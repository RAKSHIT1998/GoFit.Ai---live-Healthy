import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let baseURL = URL(string: EnvironmentConfig.apiBaseURL)!
    private let keychainService = "com.yourcompany.gofit.auth"
    private let keychainAccount = "userToken"

    // Save token
    func saveToken(_ token: AuthToken) {
        KeychainHelper.standard.save(token, service: keychainService, account: keychainAccount)
    }

    func readToken() -> AuthToken? {
        KeychainHelper.standard.read(AuthToken.self, service: keychainService, account: keychainAccount)
    }

    func deleteToken() {
        KeychainHelper.standard.delete(service: keychainService, account: keychainAccount)
    }

    // Login (email/password)
    func login(email: String, password: String) async throws -> AuthToken {
        let url = baseURL.appendingPathComponent("auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for error response
        guard 200...299 ~= http.statusCode else {
            // Try to decode error message from backend
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else if let errorString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
            } else {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Login failed with status code \(http.statusCode)"])
            }
        }
        
        let token = try JSONDecoder().decode(AuthToken.self, from: data)
        saveToken(token)
        return token
    }

    // Signup
    func signup(name: String, email: String, password: String) async throws -> AuthToken {
        let url = baseURL.appendingPathComponent("auth/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": name, "email": email, "password": password]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Check for error response
        guard 200...299 ~= http.statusCode else {
            // Try to decode error message from backend
            var errorMessage = "Registration failed"
            
            // Try to decode as JSON
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String {
                    errorMessage = message
                } else if let error = json["error"] as? String {
                    errorMessage = error
                }
            } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                errorMessage = errorString
            } else {
                errorMessage = "Registration failed with status code \(http.statusCode)"
            }
            
            // Log for debugging
            print("❌ Registration error: \(errorMessage) (Status: \(http.statusCode))")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode response - backend returns { accessToken, user }
        // AuthToken only needs accessToken, so this should work
        do {
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            saveToken(token)
            return token
        } catch {
            // If decoding fails, log the response for debugging
            print("❌ Failed to decode AuthToken from response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode server response. Please try again."])
        }
    }
}
