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
class LogSharingService: NSObject, ObservableObject {
    @Published var sharedLogs: [SharedActivityLog] = []
    @Published var activityFeed: [ActivityFeed] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "\(APIConfig.baseURL)/logs"
    private let session = URLSession.shared
    private var cache = NSCache<NSString, NSData>()

    // MARK: - Share Log

    func shareMealLog(mealId: Int, visibility: String, sharedWith: [Int]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/meal/share"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "mealId": mealId,
            "visibility": visibility,
            "sharedWith": sharedWith ?? []
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to share meal log"
            throw NetworkError.invalidResponse
        }

        let result = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        print("✅ Meal shared successfully: \(result)")
    }

    func shareWorkoutLog(workoutId: Int, visibility: String, sharedWith: [Int]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/workout/share"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "workoutId": workoutId,
            "visibility": visibility,
            "sharedWith": sharedWith ?? []
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to share workout log"
            throw NetworkError.invalidResponse
        }

        let result = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        print("✅ Workout shared successfully: \(result)")
    }

    // MARK: - Get Shared Logs

    func getFriendsSharedLogs() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/friends"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch shared logs"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [SharedActivityLog]].self, from: data)
        self.sharedLogs = response_data["logs"] ?? []
    }

    // MARK: - Get Activity Feed

    func getActivityFeed() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/feed"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch activity feed"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [ActivityFeed]].self, from: data)
        self.activityFeed = response_data["feed"] ?? []
    }

    // MARK: - Update Visibility

    func updateLogVisibility(logId: Int, visibility: String, sharedWith: [Int]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/\(logId)/visibility"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "visibility": visibility,
            "sharedWith": sharedWith ?? []
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to update visibility"
            throw NetworkError.invalidResponse
        }
    }

    // MARK: - Delete Log

    func deleteSharedLog(logId: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/\(logId)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to delete log"
            throw NetworkError.invalidResponse
        }

        // Refresh feed
        try await getActivityFeed()
    }
}

// MARK: - Gamification Service

@MainActor
class GamificationService: NSObject, ObservableObject {
    @Published var stats: GamificationStats?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var badges: [Badge] = []
    @Published var achievements: [Achievement] = []
    @Published var streaks: [UserStreak] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "\(APIConfig.baseURL)/gamification"
    private let session = URLSession.shared

    // MARK: - Get Stats

    func getStats() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/stats"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch stats"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: GamificationStats].self, from: data)
        self.stats = response_data["stats"]
    }

    // MARK: - Get Leaderboard

    func getLeaderboard(limit: Int = 50, offset: Int = 0) async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/leaderboard?limit=\(limit)&offset=\(offset)"
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

        let response_data = try JSONDecoder().decode(GlobalLeaderboard.self, from: data)
        self.leaderboard = response_data.leaderboard
    }

    // MARK: - Get Badges

    func getBadges() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/badges"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch badges"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [Badge]].self, from: data)
        self.badges = response_data["badges"] ?? []
    }

    // MARK: - Get Achievements

    func getAchievements() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/achievements"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch achievements"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [Achievement]].self, from: data)
        self.achievements = response_data["achievements"] ?? []
    }

    // MARK: - Get Streaks

    func getStreaks() async throws {
        isLoading = true
        defer { isLoading = false }

        let endpoint = "\(baseURL)/streaks"
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            errorMessage = "Failed to fetch streaks"
            throw NetworkError.invalidResponse
        }

        let response_data = try JSONDecoder().decode([String: [UserStreak]].self, from: data)
        self.streaks = response_data["streaks"] ?? []
    }
}
