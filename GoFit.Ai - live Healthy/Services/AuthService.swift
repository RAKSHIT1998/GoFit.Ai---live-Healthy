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
        req.timeoutInterval = 30.0 // 30 second timeout
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
        
        // Decode response - backend returns { accessToken, user }
        do {
            // Try to decode as AuthTokenResponse first (with user data)
            if let response = try? JSONDecoder().decode(AuthTokenResponse.self, from: data) {
                let token = AuthToken(accessToken: response.accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            saveToken(token)
            return token
        } catch {
            print("❌ Failed to decode AuthToken from login response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode server response. Please try again."])
        }
    }

    // Signup with retry logic for rate limiting
    func signup(name: String, email: String, password: String, onboardingData: OnboardingData? = nil) async throws -> AuthToken {
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await performSignup(name: name, email: email, password: password, onboardingData: onboardingData)
            } catch {
                lastError = error
                
                // Check if it's a rate limit error (429)
                if let nsError = error as NSError?,
                   nsError.code == 429 {
                    // Calculate exponential backoff: 2^attempt seconds
                    let delaySeconds = pow(2.0, Double(attempt))
                    
                    if attempt < maxRetries - 1 {
                        print("⏳ Rate limit hit, retrying in \(delaySeconds) seconds (attempt \(attempt + 1)/\(maxRetries))...")
                        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                        continue
                    } else {
                        print("❌ Max retries reached for rate limit")
                        throw error
                    }
                } else {
                    // Not a rate limit error, throw immediately
                    throw error
                }
            }
        }
        
        // Should never reach here, but just in case
        throw lastError ?? NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Registration failed after retries"])
    }
    
    // Internal signup method (actual implementation)
    private func performSignup(name: String, email: String, password: String, onboardingData: OnboardingData? = nil) async throws -> AuthToken {
        let url = baseURL.appendingPathComponent("auth/register")
        
        // Debug logging
        print("🔵 Registration request URL: \(url.absoluteString)")
        print("🔵 Base URL: \(baseURL.absoluteString)")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30.0 // 30 second timeout
        
        // Build request body with onboarding data
        var body: [String: Any] = ["name": name, "email": email, "password": password]
        
        // Add comprehensive onboarding data if available
        if let data = onboardingData {
            body["weightKg"] = data.weightKg
            body["heightCm"] = data.heightCm
            body["goals"] = data.goal
            body["activityLevel"] = data.activityLevel
            body["dietaryPreferences"] = data.dietaryPreferences
            body["allergies"] = data.allergies
            body["fastingPreference"] = data.fastingPreference
            body["workoutPreferences"] = data.workoutPreferences
            body["favoriteCuisines"] = data.favoriteCuisines
            body["foodPreferences"] = data.foodPreferences
            body["workoutTimeAvailability"] = data.workoutTimeAvailability
            body["lifestyleFactors"] = data.lifestyleFactors
            body["favoriteFoods"] = data.favoriteFoods
            body["mealTimingPreference"] = data.mealTimingPreference
            body["cookingSkill"] = data.cookingSkill
            body["budgetPreference"] = data.budgetPreference
            body["motivationLevel"] = data.motivationLevel
            body["drinkingFrequency"] = data.drinkingFrequency
            body["smokingStatus"] = data.smokingStatus
            print("🔵 Including comprehensive onboarding data in signup")
        }
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        // Log request body (without password for security)
        if let bodyString = String(data: req.httpBody!, encoding: .utf8) {
            // Parse JSON and redact password to handle escaped characters correctly
            if let jsonData = bodyString.data(using: .utf8),
               var jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                jsonObject["password"] = "***"
                if let sanitizedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
                   let sanitized = String(data: sanitizedData, encoding: .utf8) {
                    print("🔵 Request body: \(sanitized)")
                } else {
                    print("🔵 Request body: [unable to sanitize]")
                }
            } else {
                // Fallback: use regex if JSON parsing fails (shouldn't happen, but safer)
                // This regex handles escaped quotes: matches any character including escaped quotes
                let pattern = "\"password\":\"((?:[^\"\\\\]|\\\\.)*)\""
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(bodyString.startIndex..., in: bodyString)
                    let sanitized = regex.stringByReplacingMatches(in: bodyString, options: [], range: range, withTemplate: "\"password\":\"***\"")
                    print("🔵 Request body: \(sanitized)")
                } else {
                    print("🔵 Request body: [unable to sanitize]")
                }
            }
        }
        
        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            // Network error (connection failed, timeout, etc.)
            print("❌ Network error during registration: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URLError code: \(urlError.code.rawValue)")
                print("❌ URLError description: \(urlError.localizedDescription)")
            }
            throw error
        }
        
        guard let http = resp as? HTTPURLResponse else {
            print("❌ Invalid response type: \(type(of: resp))")
            throw URLError(.badServerResponse)
        }
        
        print("🔵 Response status code: \(http.statusCode)")
        
        // Check for error response
        guard 200...299 ~= http.statusCode else {
            // Try to decode error message from backend
            var errorMessage = "Registration failed"
            
            // Check for rate limiting (429 status code)
            if http.statusCode == 429 {
                errorMessage = "Too many requests. Please wait a few minutes and try again."
                print("❌ Rate limit exceeded (429)")
            } else {
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
            }
            
            // Log for debugging
            print("❌ Registration error: \(errorMessage) (Status: \(http.statusCode))")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode response - backend returns { accessToken, user }
        do {
            // Try to decode as AuthTokenResponse first (with user data)
            if let response = try? JSONDecoder().decode(AuthTokenResponse.self, from: data) {
                let token = AuthToken(accessToken: response.accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
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
    
    // Sign in with Apple
    func signInWithApple(idToken: String, userIdentifier: String, email: String?, name: String?, onboardingData: OnboardingData? = nil) async throws -> AuthToken {
        let url = baseURL.appendingPathComponent("auth/apple")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30.0
        
        var body: [String: Any?] = [
            "idToken": idToken,
            "userIdentifier": userIdentifier,
            "email": email,
            "name": name
        ]
        
        // Add onboarding data if available
        if let data = onboardingData {
            body["weightKg"] = data.weightKg
            body["heightCm"] = data.heightCm
            body["goals"] = data.goal
            body["activityLevel"] = data.activityLevel
            body["dietaryPreferences"] = data.dietaryPreferences
            body["allergies"] = data.allergies
            body["fastingPreference"] = data.fastingPreference
            body["workoutPreferences"] = data.workoutPreferences
            body["favoriteCuisines"] = data.favoriteCuisines
            body["foodPreferences"] = data.foodPreferences
            body["workoutTimeAvailability"] = data.workoutTimeAvailability
            body["lifestyleFactors"] = data.lifestyleFactors
            body["favoriteFoods"] = data.favoriteFoods
            body["mealTimingPreference"] = data.mealTimingPreference
            body["cookingSkill"] = data.cookingSkill
            body["budgetPreference"] = data.budgetPreference
            body["motivationLevel"] = data.motivationLevel
            body["drinkingFrequency"] = data.drinkingFrequency
            body["smokingStatus"] = data.smokingStatus
        }
        
        // Remove nil values
        let cleanBody = body.compactMapValues { $0 }
        req.httpBody = try JSONSerialization.data(withJSONObject: cleanBody)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= http.statusCode else {
            var errorMessage = "Apple Sign In failed"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                errorMessage = message
            } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                errorMessage = errorString
            } else {
                errorMessage = "Apple Sign In failed with status code \(http.statusCode)"
            }
            throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode response - backend returns { accessToken, user }
        do {
            // Try to decode as AuthTokenResponse first (with user data)
            if let response = try? JSONDecoder().decode(AuthTokenResponse.self, from: data) {
                let token = AuthToken(accessToken: response.accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            saveToken(token)
            return token
        } catch {
            print("❌ Failed to decode AuthToken from Apple Sign In response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode server response. Please try again."])
        }
    }
    
    // Forgot password
    func forgotPassword(email: String) async throws {
        let url = baseURL.appendingPathComponent("auth/forgot-password")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30.0
        
        let body = ["email": email]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= http.statusCode else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to send password reset email"])
            }
        }
    }
    
    // Reset password
    func resetPassword(token: String, newPassword: String) async throws {
        let url = baseURL.appendingPathComponent("auth/reset-password")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30.0
        
        let body = ["token": token, "password": newPassword]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= http.statusCode else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else {
                throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to reset password"])
            }
        }
    }
}

// MARK: - Response Models
struct AuthTokenResponse: Codable {
    let accessToken: String
    let user: UserResponse?
}

struct UserResponse: Codable {
    let id: String
    let name: String
    let email: String
    let goals: String?
}
