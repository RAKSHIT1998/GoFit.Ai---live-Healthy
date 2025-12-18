import Foundation
import UIKit

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    let baseURL = URL(string: EnvironmentConfig.apiBaseURL)!

    // Generic JSON request with Bearer token (if present)
    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
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

    // Upload image (multipart) with JWT
    func uploadMealImage(data: Data, filename: String = "meal.jpg", userId: String?) async throws -> ServerMealResponse {
        let url = baseURL.appendingPathComponent("photo/analyze")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.readToken()?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

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

        let (d, r) = try await URLSession.shared.data(for: req)
        guard let httpResponse = r as? HTTPURLResponse else {
            let statusCode = (r as? HTTPURLResponse)?.statusCode ?? -1
            if let err = String(data: d, encoding: .utf8) {
                throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: err])
            }
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let statusCode = httpResponse.statusCode
            if let err = String(data: d, encoding: .utf8) {
                throw NSError(domain: "UploadError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: err])
            }
            throw URLError(.badServerResponse)
        }
        // Photo analyze returns PhotoAnalysisResponse, not ServerMealResponse
        let decoded = try JSONDecoder().decode(PhotoAnalysisResponse.self, from: d)
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
