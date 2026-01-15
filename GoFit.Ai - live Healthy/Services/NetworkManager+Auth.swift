import Foundation
import UIKit

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    let baseURL = URL(string: EnvironmentConfig.apiBaseURL)!
    
    // MARK: - Error Extraction Helpers
    private func extractErrorFromHTML(_ html: String, statusCode: Int) -> String {
        // Handle specific status codes with user-friendly messages
        switch statusCode {
        case 503:
            if html.contains("Could not find host") || html.contains("Cloudflare") {
                return "Server is temporarily unavailable. The service may be down for maintenance. Please try again later or use offline features."
            }
            return "Service temporarily unavailable. Please try again later."
        case 502:
            return "Bad gateway. The server is experiencing issues. Please try again later."
        case 504:
            return "Gateway timeout. The server took too long to respond. Please try again."
        case 500:
            return "Internal server error. Please try again later."
        case 404:
            return "Endpoint not found. Please check your connection."
        case 401:
            return "Authentication required. Please sign in again."
        case 403:
            return "Access forbidden. You don't have permission to access this resource."
        default:
            // Try to extract error message from HTML if possible
            if let titleRange = html.range(of: "<title>", options: .caseInsensitive),
               let titleEndRange = html.range(of: "</title>", options: .caseInsensitive, range: titleRange.upperBound..<html.endIndex) {
                let title = String(html[titleRange.upperBound..<titleEndRange.lowerBound])
                if !title.isEmpty && title.count < 200 {
                    return title
                }
            }
            
            // Fallback to generic message
            return "Network request failed (Status \(statusCode)). Please check your internet connection and try again."
        }
    }

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
        req.timeoutInterval = 60.0 // 60 second timeout
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResponse = resp as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            // try to decode error message from JSON response
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
            var errorMessage = "Request failed with status code \(statusCode)"
            
            // Try to parse JSON error response first
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = errorJson["message"] as? String {
                    errorMessage = message
                } else if let error = errorJson["error"] as? String {
                    errorMessage = error
                }
            } else if let errStr = String(data: data, encoding: .utf8), !errStr.isEmpty {
                // Check if response is HTML (like Cloudflare error pages)
                if errStr.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE") || errStr.contains("<html") {
                    // Extract meaningful error from HTML
                    errorMessage = extractErrorFromHTML(errStr, statusCode: statusCode)
                } else {
                    // Regular text error, but limit length to avoid huge error messages
                    let maxLength = 500
                    if errStr.count > maxLength {
                        errorMessage = String(errStr.prefix(maxLength)) + "..."
                    } else {
                        errorMessage = errStr
                    }
                }
            }
            
            throw NSError(domain: "NetworkError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
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
        req.timeoutInterval = 60.0 // 60 second timeout
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResponse = resp as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
            var errorMessage = "Request failed with status code \(statusCode)"
            
            if let errStr = String(data: data, encoding: .utf8), !errStr.isEmpty {
                // Check if response is HTML
                if errStr.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE") || errStr.contains("<html") {
                    errorMessage = extractErrorFromHTML(errStr, statusCode: statusCode)
                } else {
                    // Limit length for text errors
                    let maxLength = 500
                    errorMessage = errStr.count > maxLength ? String(errStr.prefix(maxLength)) + "..." : errStr
                }
            } else {
                errorMessage = extractErrorFromHTML("", statusCode: statusCode)
            }
            
            throw NSError(domain: "NetworkError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
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
