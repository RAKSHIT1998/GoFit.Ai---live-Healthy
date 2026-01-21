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
        
        // Normalize email (trim and lowercase) to match backend expectations
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let body = ["email": normalizedEmail, "password": password]
        req.httpBody = try JSONEncoder().encode(body)
        
        #if DEBUG
        print("🔵 Login request to: \(url.absoluteString)")
        print("🔵 Email (normalized): \(normalizedEmail)")
        #endif
        
        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            #if DEBUG
            print("❌ Network error during login: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URLError code: \(urlError.code.rawValue)")
            }
            #endif
            throw error
        }
        
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        print("🔵 Login response status: \(http.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Login response: \(responseString)")
        }
        #endif
        
        // Check for error response
        guard 200...299 ~= http.statusCode else {
            // Try to decode error message from backend
            var errorMessage = "Login failed"
            
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] {
                errorMessage = message
            } else if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = errorData["message"] as? String {
                errorMessage = message
            } else if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                errorMessage = errorString
            } else {
                errorMessage = "Login failed with status code \(http.statusCode)"
            }
            
            #if DEBUG
            print("❌ Login error: \(errorMessage) (Status: \(http.statusCode))")
            #endif
            
            throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode response - backend returns { accessToken, user }
        do {
            // Try to decode as AuthTokenResponse first (with user data)
            if let response = try? JSONDecoder().decode(AuthTokenResponse.self, from: data) {
                guard let accessToken = response.accessToken, !accessToken.isEmpty else {
                    throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid authentication token received from server."])
                }
                let token = AuthToken(accessToken: accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            guard let accessToken = token.accessToken, !accessToken.isEmpty else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid authentication token received from server."])
            }
            saveToken(token)
            return token
        } catch {
            #if DEBUG
            print("❌ Failed to decode AuthToken from login response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            #endif
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
                        #if DEBUG
                        print("⏳ Rate limit hit, retrying in \(delaySeconds) seconds (attempt \(attempt + 1)/\(maxRetries))...")
                        #endif
                        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                        continue
                    } else {
                        #if DEBUG
                        print("❌ Max retries reached for rate limit")
                        #endif
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
        
        // Debug logging (only in debug mode to avoid exposing sensitive information)
        #if DEBUG
        print("🔵 Registration request URL: \(url.absoluteString)")
        print("🔵 Base URL: \(baseURL.absoluteString)")
        #endif
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30.0 // 30 second timeout
        
        // Build request body with onboarding data
        var body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "password": password
        ]
        
        // Add comprehensive onboarding data if available
        if let data = onboardingData {
            body["weightKg"] = data.weightKg
            body["heightCm"] = data.heightCm
            body["goals"] = data.goal
            body["activityLevel"] = data.activityLevel
            body["dietaryPreferences"] = data.dietaryPreferences // Already an array
            body["allergies"] = data.allergies // Already an array
            body["fastingPreference"] = data.fastingPreference
            body["workoutPreferences"] = data.workoutPreferences // Already an array
            body["favoriteCuisines"] = data.favoriteCuisines // Already an array
            body["foodPreferences"] = data.foodPreferences // Already an array
            body["workoutTimeAvailability"] = data.workoutTimeAvailability
            body["lifestyleFactors"] = data.lifestyleFactors // Already an array
            body["favoriteFoods"] = data.favoriteFoods // Already an array
            body["mealTimingPreference"] = data.mealTimingPreference
            body["cookingSkill"] = data.cookingSkill
            body["budgetPreference"] = data.budgetPreference
            body["motivationLevel"] = data.motivationLevel
            body["drinkingFrequency"] = data.drinkingFrequency
            body["smokingStatus"] = data.smokingStatus
            #if DEBUG
            print("🔵 Including comprehensive onboarding data in signup")
            #endif
        }
        
        // Validate that body can be serialized to JSON
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            #if DEBUG
            print("❌ Failed to serialize request body to JSON: \(error.localizedDescription)")
            #endif
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare signup data. Please try again."])
        }
        
        // Log request body (without password for security) - only in debug mode
        #if DEBUG
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
        #endif
        
        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            // Network error (connection failed, timeout, etc.)
            #if DEBUG
            print("❌ Network error during registration: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URLError code: \(urlError.code.rawValue)")
                print("❌ URLError description: \(urlError.localizedDescription)")
            }
            #endif
            throw error
        }
        
        guard let http = resp as? HTTPURLResponse else {
            #if DEBUG
            print("❌ Invalid response type: \(type(of: resp))")
            #endif
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        print("🔵 Response status code: \(http.statusCode)")
        #endif
        
        // Check for error response
        guard 200...299 ~= http.statusCode else {
            // Try to decode error message from backend
            var errorMessage = "Registration failed"
            
            // Check for rate limiting (429 status code)
            if http.statusCode == 429 {
                errorMessage = "Too many requests. Please wait a few minutes and try again."
                #if DEBUG
                print("❌ Rate limit exceeded (429)")
                #endif
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
            
            // Log for debugging (only in debug mode to avoid exposing sensitive information)
            #if DEBUG
            print("❌ Registration error: \(errorMessage) (Status: \(http.statusCode))")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            #endif
            
            throw NSError(domain: "AuthError", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode response - backend returns { accessToken, user }
        do {
            // Try to decode as AuthTokenResponse first (with user data)
            if let response = try? JSONDecoder().decode(AuthTokenResponse.self, from: data) {
                // Check if accessToken is null or empty (account created but token generation failed)
                guard let accessToken = response.accessToken, !accessToken.isEmpty else {
                    let message = response.message ?? "Account created successfully. Please sign in to continue."
                    throw NSError(domain: "AuthError", code: 201, userInfo: [NSLocalizedDescriptionKey: message])
                }
                let token = AuthToken(accessToken: accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            guard let accessToken = token.accessToken, !accessToken.isEmpty else {
                throw NSError(domain: "AuthError", code: 201, userInfo: [NSLocalizedDescriptionKey: "Account created successfully. Please sign in to continue."])
            }
            saveToken(token)
            return token
        } catch let decodeError as NSError {
            // If it's our custom error about account creation, rethrow it
            if decodeError.domain == "AuthError" && decodeError.code == 201 {
                throw decodeError
            }
            // If decoding fails, log the response for debugging (only in debug mode)
            #if DEBUG
            print("❌ Failed to decode AuthToken from response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            #endif
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
                guard let accessToken = response.accessToken, !accessToken.isEmpty else {
                    throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid authentication token received from server."])
                }
                let token = AuthToken(accessToken: accessToken, expiresAt: nil)
                saveToken(token)
                return token
            }
            // Fallback: try direct AuthToken decode
            let token = try JSONDecoder().decode(AuthToken.self, from: data)
            guard let accessToken = token.accessToken, !accessToken.isEmpty else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid authentication token received from server."])
            }
            saveToken(token)
            return token
        } catch {
            #if DEBUG
            print("❌ Failed to decode AuthToken from Apple Sign In response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            #endif
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
    let accessToken: String? // Optional to handle cases where token generation fails
    let user: UserResponse?
    let message: String? // Optional message from backend
}

struct UserResponse: Codable {
    let id: String
    let name: String
    let email: String
    let goals: String?
}
