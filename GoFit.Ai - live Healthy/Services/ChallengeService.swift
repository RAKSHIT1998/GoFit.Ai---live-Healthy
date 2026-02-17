import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

@MainActor
class ChallengeService: NSObject, ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var currentChallenge: Challenge?
    @Published var leaderboard: [ChallengeParticipant] = []
    @Published var myInvitations: [ChallengeInvitation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "\(APIConfig.baseURL)/challenges"
    private let session = URLSession.shared

    // MARK: - Create Challenge

    func createChallenge(
        name: String,
        description: String?,
        type: String,
        metric: String,
        targetValue: Int,
        durationDays: Int,
        isGroupChallenge: Bool = false,
        invitedUsers: [Int] = []
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/create"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "name": name,
            "description": description ?? "",
            "challengeType": type,
            "metric": metric,
            "targetValue": targetValue,
            "duration": durationDays,
            "isGroupChallenge": isGroupChallenge,
            "invitedUsers": invitedUsers
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to create challenge"
            throw NetworkError.invalidResponse
        }

        let result = try JSONDecoder().decode([String: Challenge].self, from: data)
        if let newChallenge = result["challenge"] {
            self.currentChallenge = newChallenge
            try await getChallenges()
        }
    }

    // MARK: - Get Challenges

    func getChallenges(type: String? = nil, status: String = "active") async throws {
        isLoading = true
        defer { isLoading = false }

        var endpoint = "\(baseURL)?status=\(status)"
        if let type = type {
            endpoint += "&type=\(type)"
        }

        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch challenges"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [Challenge]].self, from: data)
        self.challenges = response_data["challenges"] ?? []
    }

    // MARK: - Join Challenge

    func joinChallenge(challengeId: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/\(challengeId)/join"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to join challenge"
            throw NetworkError.invalidResponse
        }

        // Refresh challenges
        try await getChallenges()
    }

    // MARK: - Get Leaderboard

    func getLeaderboard(challengeId: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/\(challengeId)/leaderboard"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch leaderboard"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode(ChallengeLeaderboard.self, from: data)
        self.leaderboard = response_data.leaderboard
    }

    // MARK: - Update Score

    func updateScore(challengeId: Int, scoreValue: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/\(challengeId)/score"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = ["scoreValue": scoreValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to update score"
            throw NetworkError.invalidResponse
        }

        // Refresh leaderboard
        try await getLeaderboard(challengeId: challengeId)
    }
}
