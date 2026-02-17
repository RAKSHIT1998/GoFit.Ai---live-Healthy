import Foundation

// MARK: - Phase 2: Log Sharing Models

struct SharedActivityLog: Identifiable, Codable {
    let id: Int
    let userId: Int
    let username: String?
    let type: String // meal, workout
    let title: String?
    let description: String?
    let visibility: String // private, friends_only, public
    let sharedWith: [Int]? // Array of user IDs
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, username, type, title, description, visibility
        case sharedWith = "shared_with"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ActivityFeed: Identifiable, Codable {
    let id: Int
    let activity: SharedActivityLog
    let friendUsername: String
    let timestamp: String
    let isOwnActivity: Bool
}

struct LogVisibilitySettings: Codable {
    let visibility: String // private, friends_only, public
    let sharedWith: [Int]? // Specific users to share with

    enum CodingKeys: String, CodingKey {
        case visibility
        case sharedWith = "shared_with"
    }
}

// MARK: - Phase 3: Challenge Models

struct Challenge: Identifiable, Codable {
    let id: Int
    let creatorId: Int
    let name: String
    let description: String?
    let challengeType: String // personal, group
    let metric: String // steps, calories, meals, workouts
    let targetValue: Int
    let startDate: String
    let endDate: String
    let isActive: Bool
    let participantCount: Int
    let userJoined: Bool?

    enum CodingKeys: String, CodingKey {
        case id, creatorId, name, description, challengeType, metric, targetValue
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case participantCount = "participant_count"
        case userJoined = "user_joined"
    }
}

struct ChallengeParticipant: Identifiable, Codable {
    let id: Int
    let userId: Int
    let username: String
    let email: String?
    let profilePicture: String?
    let currentScore: Int
    let rank: Int
    let joinedAt: String

    enum CodingKeys: String, CodingKey {
        case id, userId, username, email
        case profilePicture = "profile_picture"
        case currentScore = "current_score"
        case rank, joinedAt
    }
}

struct ChallengeLeaderboard: Codable {
    let leaderboard: [ChallengeParticipant]
}

struct ChallengeInvitation: Identifiable, Codable {
    let id: Int
    let challengeId: Int
    let challengeName: String
    let invitedBy: String
    let status: String // pending, accepted, declined
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, challengeId
        case challengeName = "challenge_name"
        case invitedBy = "invited_by"
        case status
        case createdAt = "created_at"
    }
}

// MARK: - Phase 4: Notification Models

struct SocialNotification: Identifiable, Codable {
    let id: Int
    let recipientId: Int
    let type: String // challenge_invite, friend_request, ai_competitive, etc
    let title: String?
    let message: String?
    let relatedUserId: Int?
    let challengeId: Int?
    let aiGenerated: Bool
    let isRead: Bool
    let readAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, recipientId, type, title, message
        case relatedUserId = "related_user_id"
        case challengeId = "challenge_id"
        case aiGenerated = "ai_generated"
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

struct NotificationResponse: Codable {
    let notifications: [SocialNotification]
    let count: Int
}

struct UnreadCount: Codable {
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }
}

// MARK: - Phase 5: Gamification Models

struct Badge: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let iconUrl: String?
    let earned: Bool
    let earnedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case iconUrl = "icon_url"
        case earned
        case earnedAt = "earned_at"
    }
}

struct Achievement: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String?
    let iconUrl: String?
    let earned: Bool
    let earnedAt: String?
    let progress: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case iconUrl = "icon_url"
        case earned
        case earnedAt = "earned_at"
        case progress
    }
}

struct UserStreak: Identifiable, Codable {
    let id: Int
    let userId: Int
    let streakType: String // workout_streak, nutrition_streak
    let currentStreak: Int
    let bestStreak: Int
    let lastUpdated: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, userId
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case lastUpdated = "last_updated"
        case isActive = "is_active"
    }
}

struct GamificationStats: Codable {
    let totalPoints: Int
    let actionCount: Int
    let rank: Int?
    let badges: BadgesInfo
    let achievements: AchievementsInfo
    let streaks: StreaksInfo

    enum CodingKeys: String, CodingKey {
        case totalPoints = "total_points"
        case actionCount = "action_count"
        case rank, badges, achievements, streaks
    }

    struct BadgesInfo: Codable {
        let earned: Int
        let details: [Badge]
    }

    struct AchievementsInfo: Codable {
        let earned: Int
        let details: [Achievement]
    }

    struct StreaksInfo: Codable {
        let active: Int
        let details: [UserStreak]
    }
}

struct LeaderboardEntry: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String?
    let profilePicture: String?
    let totalPoints: Int?
    let badgeCount: Int?
    let achievementCount: Int?
    let rank: Int
    let isCurrentUser: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case profilePicture = "profile_picture"
        case totalPoints = "total_points"
        case badgeCount = "badge_count"
        case achievementCount = "achievement_count"
        case rank
        case isCurrentUser = "is_current_user"
    }
}

struct GlobalLeaderboard: Codable {
    let leaderboard: [LeaderboardEntry]
    let count: Int
}
