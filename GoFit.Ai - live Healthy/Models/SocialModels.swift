import Foundation

// MARK: - Friend Models

struct Friend: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let fullName: String?
    let profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case fullName = "full_name"
        case profileImageUrl = "profile_image_url"
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let requesterId: String
    let requesterUsername: String
    let requesterEmail: String
    let requesterProfileImageUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case requesterUsername = "username"
        case requesterEmail = "email"
        case requesterProfileImageUrl = "profile_image_url"
        case createdAt = "created_at"
    }
}

struct FriendResponse: Codable {
    let message: String
    let friendship: FriendshipInfo?
    
    struct FriendshipInfo: Codable {
        let id: String
        let status: String
    }
}

struct FriendsListResponse: Codable {
    let friends: [Friend]
    let count: Int
}

struct FriendRequestsResponse: Codable {
    let requests: [FriendRequest]
}

struct SearchResult: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let fullName: String?
    let profileImageUrl: String?
    let friendStatus: String  // "friends", "request_sent", "request_received", "not_friends"
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case fullName = "full_name"
        case profileImageUrl = "profile_image_url"
        case friendStatus = "friend_status"
    }
}

struct SearchUsersResponse: Codable {
    let results: [SearchResult]
    let count: Int
}

struct FriendStats: Codable {
    let totalMealsLogged: Int
    let totalWorkoutsCompleted: Int
    let totalCaloriesBurned: Int
    let lastMealLogged: Date?
    let lastWorkoutCompleted: Date?
    
    enum CodingKeys: String, CodingKey {
        case totalMealsLogged = "total_meals_logged"
        case totalWorkoutsCompleted = "total_workouts_completed"
        case totalCaloriesBurned = "total_calories_burned"
        case lastMealLogged = "last_meal_logged"
        case lastWorkoutCompleted = "last_workout_completed"
    }
}

struct FriendStatsResponse: Codable {
    let stats: FriendStats
}

// MARK: - Challenge Models

struct Challenge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let creatorId: String
    let type: ChallengeType  // personal_1v1, group, team
    let metric: String  // calories_burned, workouts, steps, etc.
    let startDate: Date
    let endDate: Date
    let status: ChallengeStatus  // active, completed, cancelled
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case creatorId = "creator_id"
        case type
        case metric
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case createdAt = "created_at"
    }
}

enum ChallengeType: String, Codable {
    case personal_1v1 = "personal_1v1"
    case group = "group"
    case team = "team"
}

enum ChallengeStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct ChallengeParticipant: Codable, Identifiable {
    let id: String
    let challengeId: String
    let userId: String
    let score: Double
    let rank: Int?
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case score
        case rank
        case joinedAt = "joined_at"
    }
}

struct ChallengeLeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let profileImageUrl: String?
    let score: Double
    let rank: Int
    let trend: String?  // "up", "down", "stable"
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case profileImageUrl = "profile_image_url"
        case score
        case rank
        case trend
    }
}

struct CreateChallengeRequest: Codable {
    let name: String
    let description: String?
    let type: String
    let metric: String
    let startDate: Date
    let endDate: Date
    let invitedFriends: [String]?  // friend IDs
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
        case metric
        case startDate = "start_date"
        case endDate = "end_date"
        case invitedFriends = "invited_friends"
    }
}

struct ChallengesResponse: Codable {
    let challenges: [Challenge]
    let count: Int
}

struct ChallengeDetailResponse: Codable {
    let challenge: Challenge
    let participants: [ChallengeParticipant]
    let leaderboard: [ChallengeLeaderboardEntry]
}

// MARK: - Notification Models

struct SocialNotification: Codable, Identifiable {
    let id: String
    let recipientId: String
    let type: NotificationType
    let title: String?
    let message: String
    let aiGenerated: Bool
    let relatedUserId: String?
    let challengeId: String?
    let read: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipientId = "recipient_id"
        case type
        case title
        case message
        case aiGenerated = "ai_generated"
        case relatedUserId = "related_user_id"
        case challengeId = "challenge_id"
        case read
        case createdAt = "created_at"
    }
}

enum NotificationType: String, Codable {
    case friend_activity = "friend_activity"
    case challenge_update = "challenge_update"
    case milestone = "milestone"
    case leaderboard = "leaderboard"
}

struct NotificationsResponse: Codable {
    let notifications: [SocialNotification]
    let unreadCount: Int
    
    enum CodingKeys: String, CodingKey {
        case notifications
        case unreadCount = "unread_count"
    }
}

// MARK: - Activity Log Models

struct ActivityLog: Codable, Identifiable {
    let id: String
    let userId: String
    let type: ActivityType
    let data: [String: AnyCodable]  // Flexible JSON storage
    let sharedWith: [String]  // user IDs
    let visibility: VisibilityLevel
    let challengeId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case data
        case sharedWith = "shared_with"
        case visibility
        case challengeId = "challenge_id"
        case createdAt = "created_at"
    }
}

enum ActivityType: String, Codable {
    case meal = "meal"
    case workout = "workout"
    case daily_summary = "daily_summary"
}

enum VisibilityLevel: String, Codable {
    case `private` = "private"
    case friends_only = "friends_only"
    case `public` = "public"
}

struct ShareActivityRequest: Codable {
    let activityId: String
    let sharedWith: [String]  // user IDs
    let visibility: String  // "private", "friends_only", "public"
    
    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case sharedWith = "shared_with"
        case visibility
    }
}

struct ShareActivityResponse: Codable {
    let message: String
    let activityLog: ActivityLog?
}
