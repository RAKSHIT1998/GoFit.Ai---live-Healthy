import Foundation
import UIKit

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    let baseURL = URL(string: EnvironmentConfig.apiBaseURL)!

    // Generic JSON request with Bearer token (if present)
    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        // Construct URL properly - baseURL already includes /api
        // Remove leading slash from path if present to avoid double slashes
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        
        // Ensure baseURL doesn't have trailing slash, then append path
        var baseURLString = baseURL.absoluteString
        if baseURLString.hasSuffix("/") {
            baseURLString = String(baseURLString.dropLast())
        }
        let urlString = "\(baseURLString)/\(cleanPath)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        }
        
        // Debug: Log the URL being called
        #if DEBUG
        print("🌐 API Request: \(method) \(url.absoluteString)")
        #endif
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = AuthService.shared.readToken()?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResponse = resp as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            // try to decode error message
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
            if let errStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "NetworkError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errStr])
            }
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // Request that returns a dictionary (for export data)
    func requestDictionary(_ path: String, method: String = "GET", body: Data? = nil) async throws -> [String: Any] {
        // Construct URL the same way as request method
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var baseURLString = baseURL.absoluteString
        if baseURLString.hasSuffix("/") {
            baseURLString = String(baseURLString.dropLast())
        }
        let urlString = "\(baseURLString)/\(cleanPath)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = AuthService.shared.readToken()?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResponse = resp as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
            if let errStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "NetworkError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errStr])
            }
            throw URLError(.badServerResponse)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        return json
    }

    // Upload image (multipart) with JWT
    func uploadMealImage(data: Data, filename: String = "meal.jpg", userId: String?) async throws -> ServerMealResponse {
        let url = baseURL.appendingPathComponent("photo/analyze")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        // Set longer timeout for AI analysis (90 seconds)
        req.timeoutInterval = 90.0
        
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Ensure token is present - throw error if not
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authentication token found. Please log in again."])
        }
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()
        // optional userId
        if let uid = userId {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"userId\"\r\n\r\n")
            body.appendString("\(uid)\r\n")
        }

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")

        req.httpBody = body

        // Use URLSession with custom configuration for longer timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90.0
        config.timeoutIntervalForResource = 90.0
        let session = URLSession(configuration: config)
        
        let (d, r) = try await session.data(for: req)
        guard let httpResponse = r as? HTTPURLResponse else {
            let statusCode = (r as? HTTPURLResponse)?.statusCode ?? -1
            if let err = String(data: d, encoding: .utf8) {
                throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: err])
            }
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            // Try to parse error message from response
            if let errorData = try? JSONDecoder().decode([String: String].self, from: d),
               let errorMessage = errorData["message"] {
                throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else if let err = String(data: d, encoding: .utf8) {
                throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: err])
            }
            throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(statusCode)"])
        }
        
        // Photo analyze returns PhotoAnalysisResponse, not ServerMealResponse
        // First, decode the response
        let decoded: PhotoAnalysisResponse
        do {
            decoded = try JSONDecoder().decode(PhotoAnalysisResponse.self, from: d)
        } catch {
            // Only catch actual decoding errors, not validation errors
            if let errorStr = String(data: d, encoding: .utf8) {
                print("⚠️ Decode error. Response: \(errorStr)")
            }
            throw NSError(domain: "UploadError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response. Please try again."])
        }
        
        // Validate that we got items (this happens after successful decoding)
        guard !decoded.items.isEmpty else {
            throw NSError(domain: "UploadError", code: 500, userInfo: [NSLocalizedDescriptionKey: "AI analysis returned no food items. Please try again with a clearer photo."])
        }
        
        // Convert to ServerMealResponse format for compatibility
        return ServerMealResponse(
            mealId: nil,
            parsedItems: decoded.items,
            recommendations: nil
        )
    }
}

// small helper
fileprivate extension Data {
    mutating func appendString(_ str: String) {
        if let d = str.data(using: .utf8) { append(d) }
    }
}
