import Foundation

struct AuthToken: Codable {
    let accessToken: String? // Optional to handle cases where token generation fails
    let expiresAt: Date? // optional
}
