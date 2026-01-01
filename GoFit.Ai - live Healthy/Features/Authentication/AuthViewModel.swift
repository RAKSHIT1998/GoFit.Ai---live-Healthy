import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var didFinishOnboarding: Bool = false

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var weightKg: Double = 70
    @Published var heightCm: Double = 170
    @Published var goal: String = "maintain"
    @Published var dietPrefs: [String] = []
    
    // Comprehensive onboarding data
    @Published var onboardingData: OnboardingData?

    // token / userId
    @Published private(set) var token: AuthToken?
    @Published private(set) var userId: String?

    private let localKey = "gofit_local_state_v2"

    init() {
        loadLocalState()
        
        // Skip authentication if enabled in EnvironmentConfig
        if EnvironmentConfig.skipAuthentication {
            self.isLoggedIn = true
            self.didFinishOnboarding = true // Skip onboarding too
            self.userId = "dev-user-\(UUID().uuidString.prefix(8))"
            self.name = self.name.isEmpty ? "Dev User" : self.name
            self.email = self.email.isEmpty ? "dev@example.com" : self.email
            // Set default values if not already set
            if self.weightKg == 0 { self.weightKg = 70 }
            if self.heightCm == 0 { self.heightCm = 170 }
            if self.goal.isEmpty { self.goal = "maintain" }
            // Create a mock token for development (won't work with backend, but prevents errors)
            let mockToken = AuthToken(accessToken: "dev-token-skip-auth", expiresAt: nil)
            self.token = mockToken
            AuthService.shared.saveToken(mockToken) // Save to keychain so NetworkManager can read it
            saveLocalState() // Save state immediately
            return
        }
        
        // Check for existing token - if found, user stays logged in
        if let t = AuthService.shared.readToken(), !t.accessToken.isEmpty {
            self.token = t
            self.isLoggedIn = true
            // Restore user data from local state if available
            if let savedUserId = self.userId, !savedUserId.isEmpty {
                // User data already loaded from local state, just verify token is still valid
                // Try to refresh profile in background (non-blocking)
                Task {
                    await refreshUserProfile()
                }
            } else {
                // No local user data, try to fetch from backend
                Task {
                    await refreshUserProfile()
                }
            }
        } else {
            // No token found - user is not logged in
            self.isLoggedIn = false
            self.token = nil
        }
    }

    // MARK: - Local save/load
    func loadLocalState() {
        if let data = UserDefaults.standard.data(forKey: localKey),
           let obj = try? JSONDecoder().decode(LocalState.self, from: data) {
            self.didFinishOnboarding = obj.didFinishOnboarding
            self.name = obj.name
            self.weightKg = obj.weightKg > 0 ? obj.weightKg : 70
            self.heightCm = obj.heightCm > 0 ? obj.heightCm : 170
            self.goal = obj.goal.isEmpty ? "maintain" : obj.goal
            self.dietPrefs = obj.dietPrefs
            self.userId = obj.userId
        } else {
            // Initialize with defaults if no saved state
            self.didFinishOnboarding = false
            self.name = ""
            self.weightKg = 70
            self.heightCm = 170
            self.goal = "maintain"
            self.dietPrefs = []
        }
    }

    func saveLocalState() {
        let s = LocalState(didFinishOnboarding: didFinishOnboarding, name: name, weightKg: weightKg, heightCm: heightCm, goal: goal, dietPrefs: dietPrefs, userId: userId)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: localKey)
        }
    }

    // MARK: - Auth flows (async)
    func login(email: String, password: String) async throws {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email and password are required"])
        }
        
        guard Validators.isValidEmail(email) else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"])
        }
        
        // Perform login
        let token = try await AuthService.shared.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        self.token = token
        self.isLoggedIn = true
        // Save token immediately to ensure persistence
        AuthService.shared.saveToken(token)
        
        // Fetch user profile to get complete user data
        do {
            let me: UserProfile = try await NetworkManager.shared.request("auth/me", method: "GET", body: nil)
            self.userId = me.id
            self.email = me.email
            self.name = me.name
            // Update local state with fetched data
            saveLocalState()
        } catch {
            // If /me fails, still mark as logged in but log the error
            print("⚠️ Failed to fetch user profile after login: \(error.localizedDescription)")
            // Use email from login form as fallback
            self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            saveLocalState()
            // Don't throw - login was successful, profile fetch is secondary
        }
    }

    func signup(name: String, email: String, password: String) async throws {
        // Validate input
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Name, email, and password are required"])
        }
        
        guard Validators.isValidEmail(email) else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"])
        }
        
        guard Validators.isValidPassword(password) else {
            throw NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters long"])
        }
        
        print("🔵 Starting signup for: \(email)")
        
        // Include comprehensive onboarding data if available
        let onboardingData = self.onboardingData
        
        // Perform signup with all onboarding data
        let token = try await AuthService.shared.signup(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            onboardingData: onboardingData
        )
        
        print("✅ Signup successful, token received")
        
        self.token = token
        self.isLoggedIn = true
        // Save token immediately to ensure persistence
        AuthService.shared.saveToken(token)
        
        // Fetch user profile to get complete user data (including userId from database)
        do {
            print("🔵 Fetching user profile from backend...")
            let me: UserProfile = try await NetworkManager.shared.request("auth/me", method: "GET", body: nil)
            self.userId = me.id
            self.email = me.email
            self.name = me.name
            // Update local state with fetched data
            saveLocalState()
            print("✅ User profile fetched successfully. User ID: \(me.id)")
        } catch {
            // If /me fails, use the data from signup form
            print("⚠️ Failed to fetch user profile after signup: \(error.localizedDescription)")
            // Still save what we have - user was created successfully
            self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            saveLocalState()
            // Don't throw - signup was successful, profile fetch is secondary
        }
    }

    func logout() {
        AuthService.shared.deleteToken()
        self.token = nil
        self.isLoggedIn = false
        self.userId = nil
        saveLocalState()
    }
    
    // Sign in with Apple
    func signInWithApple() async throws {
        let result = try await AppleSignInService.shared.signIn()
        let token = try await AuthService.shared.signInWithApple(
            idToken: result.idToken,
            userIdentifier: result.userIdentifier,
            email: result.email,
            name: result.fullName
        )
        self.token = token
        self.isLoggedIn = true
        // Save token immediately to ensure persistence
        AuthService.shared.saveToken(token)
        
        // Update name and email if provided
        if let name = result.fullName, !name.isEmpty {
            self.name = name
        }
        if let email = result.email, !email.isEmpty {
            self.email = email
        }
        
        // Fetch user profile
        do {
            let me: UserProfile = try await NetworkManager.shared.request("auth/me", method: "GET", body: nil)
            self.userId = me.id
            if self.name.isEmpty {
                self.name = me.name
            }
            if self.email.isEmpty {
                self.email = me.email
            }
            saveLocalState()
        } catch {
            print("⚠️ Failed to fetch user profile after Apple Sign In: \(error.localizedDescription)")
            // Still save state with what we have
            saveLocalState()
            // Don't throw - Apple Sign In was successful, profile fetch is secondary
        }
    }
    
    // Skip authentication (development only)
    func skipAuthentication() {
        guard EnvironmentConfig.skipAuthentication else { return }
        self.isLoggedIn = true
        self.didFinishOnboarding = true // Skip onboarding too
        if self.userId == nil {
            self.userId = "dev-user-\(UUID().uuidString.prefix(8))"
        }
        if self.name.isEmpty {
            self.name = "Dev User"
        }
        if self.email.isEmpty {
            self.email = "dev@example.com"
        }
        // Set default values if not already set
        if self.weightKg == 0 { self.weightKg = 70 }
        if self.heightCm == 0 { self.heightCm = 170 }
        if self.goal.isEmpty { self.goal = "maintain" }
        // Create a mock token for development (won't work with backend, but prevents errors)
        let mockToken = AuthToken(accessToken: "dev-token-skip-auth", expiresAt: nil)
        self.token = mockToken
        AuthService.shared.saveToken(mockToken) // Save to keychain so NetworkManager can read it
        saveLocalState()
    }
    
    // Refresh user profile from backend
    func refreshUserProfile() async {
        guard !EnvironmentConfig.skipAuthentication, isLoggedIn else { return }
        
        // Check if token exists before attempting refresh
        guard let token = AuthService.shared.readToken(), !token.accessToken.isEmpty else {
            print("⚠️ No token found, cannot refresh profile")
            // Only log out if we're supposed to be logged in but have no token
            // This handles edge cases where token was deleted externally
            await MainActor.run {
                if self.isLoggedIn {
                    print("⚠️ User marked as logged in but no token found. Keeping user logged in with cached data.")
                    // Don't log out - keep user logged in with cached data
                    // Token might be temporarily unavailable but will be restored
                }
            }
            return
        }
        
        do {
            let me: UserProfile = try await NetworkManager.shared.request("auth/me", method: "GET", body: nil)
            await MainActor.run {
                self.userId = me.id
                self.email = me.email
                self.name = me.name
                saveLocalState()
                print("✅ User profile refreshed successfully")
            }
        } catch {
            // Check if it's a 401 (unauthorized) error - ONLY log out on actual auth failures
            // NetworkManager throws NSError with status code in the 'code' field
            var isUnauthorized = false
            
            if let nsError = error as NSError? {
                // NetworkManager sets the HTTP status code as the NSError code
                // Check if error code is 401 (unauthorized)
                if nsError.code == 401 {
                    isUnauthorized = true
                } else if nsError.domain == "NetworkError" && nsError.code == 401 {
                    isUnauthorized = true
                }
                
                if isUnauthorized {
                    print("❌ Token expired or invalid (401). Logging out user.")
                    await MainActor.run {
                        self.logout()
                    }
                } else {
                    // For network errors, timeouts, server errors (500, 503, etc.), don't log out
                    print("⚠️ Failed to refresh user profile (non-auth error): \(error.localizedDescription)")
                    print("⚠️ Error code: \(nsError.code), domain: \(nsError.domain)")
                    // User stays logged in - this is likely a temporary network issue
                    // The token is still valid, just couldn't reach the server
                }
            } else if let urlError = error as? URLError {
                // Network errors (no connection, timeout, etc.) should NOT log out user
                print("⚠️ Failed to refresh user profile (network error): \(urlError.localizedDescription)")
                print("⚠️ URLError code: \(urlError.code.rawValue)")
                // User stays logged in - likely a network issue
            } else {
                // Unknown error type - don't log out
                print("⚠️ Failed to refresh user profile (unknown error): \(error.localizedDescription)")
                // User stays logged in
            }
        }
    }
    
    // Reset app state (useful for testing)
    func resetAppState() {
        UserDefaults.standard.removeObject(forKey: localKey)
        AuthService.shared.deleteToken()
        self.isLoggedIn = false
        self.didFinishOnboarding = false
        self.token = nil
        self.userId = nil
        self.name = ""
        self.email = ""
        self.weightKg = 70
        self.heightCm = 170
        self.goal = "maintain"
        self.dietPrefs = []
    }
}

// small local state used for UI persistence
fileprivate struct LocalState: Codable {
    var didFinishOnboarding: Bool = false
    var name: String = ""
    var weightKg: Double = 70
    var heightCm: Double = 170
    var goal: String = "maintain"
    var dietPrefs: [String] = []
    var userId: String? = nil
}

// Minimal profile model (used in login flow to fetch user id)
struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
}

// Comprehensive onboarding data structure
struct OnboardingData: Codable {
    let name: String
    let weightKg: Double
    let heightCm: Double
    let goal: String
    let activityLevel: String
    let dietaryPreferences: [String]
    let allergies: [String]
    let fastingPreference: String
    let workoutPreferences: [String]
    let favoriteCuisines: [String]
    let foodPreferences: [String]
    let workoutTimeAvailability: String
    let lifestyleFactors: [String]
    let favoriteFoods: [String]
    let mealTimingPreference: String
    let cookingSkill: String
    let budgetPreference: String
    let motivationLevel: String
}
