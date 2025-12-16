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
            self.weightKg = obj.weightKg
            self.heightCm = obj.heightCm
            self.goal = obj.goal
            self.dietPrefs = obj.dietPrefs
            self.userId = obj.userId
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
}

// small local state used for UI persistence
fileprivate struct LocalState: Codable {
    var didFinishOnboarding: Bool
    var name: String
    var weightKg: Double
    var heightCm: Double
    var goal: String
    var dietPrefs: [String]
    var userId: String?
}

// Minimal profile model (used in login flow to fetch user id)
struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
}
