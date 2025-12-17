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
        
        if let t = AuthService.shared.readToken() {
            self.token = t
            // Optionally you can decode a userId from token if you embed it, or fetch /me
            self.isLoggedIn = true
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
        let token = try await AuthService.shared.login(email: email, password: password)
        self.token = token
        self.isLoggedIn = true
        // Optionally fetch /me to get userId
        if let me: UserProfile = try? await NetworkManager.shared.request("auth/me", method: "GET", body: nil) {
            self.userId = me.id
        }
        saveLocalState()
    }

    func signup(name: String, email: String, password: String) async throws {
        let token = try await AuthService.shared.signup(name: name, email: email, password: password)
        self.token = token
        self.isLoggedIn = true
        // Optionally fetch profile
        if let me: UserProfile = try? await NetworkManager.shared.request("auth/me", method: "GET", body: nil) {
            self.userId = me.id
        }
        saveLocalState()
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
        
        // Update name and email if provided
        if let name = result.fullName, !name.isEmpty {
            self.name = name
        }
        if let email = result.email, !email.isEmpty {
            self.email = email
        }
        
        // Fetch user profile
        if let me: UserProfile = try? await NetworkManager.shared.request("auth/me", method: "GET", body: nil) {
            self.userId = me.id
            if self.name.isEmpty {
                self.name = me.name
            }
            if self.email.isEmpty {
                self.email = me.email
            }
        }
        saveLocalState()
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
