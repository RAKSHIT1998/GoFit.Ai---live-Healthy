import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let expiresAt: Date? // optional
}
