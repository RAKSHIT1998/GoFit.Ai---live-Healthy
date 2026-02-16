import Foundation
import Combine

/// Intelligent caching layer for user data
/// Provides offline access and sync-on-demand capabilities
final class UserDataCache: ObservableObject {
    static let shared = UserDataCache()
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Published Properties
    @Published private(set) var userProfile: UserProfileCache?
    @Published private(set) var workoutSessions: [WorkoutSession] = []
    @Published private(set) var mealEntries: [MealEntry] = []
    @Published private(set) var dailyStats: DailyStats?
    @Published private(set) var isLoading = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var isSynced = false
    
    private let storage = DeviceStorageManager.shared
    private let logger = AppLogger.shared
    private let cacheLock = DispatchQueue(label: "user.data.cache.queue")
    
    // Cache expiry
    private let cacheExpiryInterval: TimeInterval = 6 * 60 * 60 // 6 hours
    
    // MARK: - Initialization
    private func loadCachedData() {
        cacheLock.async {
            self.logger.storage("Loading cached user data...")
            
            if let profile = self.storage.load(UserProfileCache.self, forKey: "cached_user_profile") {
                DispatchQueue.main.async {
                    self.userProfile = profile
                }
            }
            
            if let workouts = self.storage.load([WorkoutSession].self, forKey: "cached_workouts") {
                DispatchQueue.main.async {
                    self.workoutSessions = workouts
                }
            }
            
            if let meals = self.storage.load([MealEntry].self, forKey: "cached_meals") {
                DispatchQueue.main.async {
                    self.mealEntries = meals
                }
            }
            
            if let stats = self.storage.load(DailyStats.self, forKey: "cached_daily_stats") {
                DispatchQueue.main.async {
                    self.dailyStats = stats
                }
            }
            
            if let syncTime = self.storage.load(Date.self, forKey: "last_sync_time") {
                DispatchQueue.main.async {
                    self.lastSyncTime = syncTime
                }
            }
            
            self.logger.storage("Cache loading complete")
        }
    }
    
    // MARK: - User Profile Cache
    func updateUserProfile(_ profile: UserProfileCache) {
        cacheLock.async {
            let success = self.storage.save(profile, forKey: "cached_user_profile")
            DispatchQueue.main.async {
                if success {
                    self.userProfile = profile
                    self.logger.storage("User profile cached successfully")
                }
            }
        }
    }
    
    func clearUserProfile() {
        cacheLock.async {
            self.storage.removeStoredObject(forKey: "cached_user_profile")
            DispatchQueue.main.async {
                self.userProfile = nil
                self.logger.storage("User profile cleared from cache")
            }
        }
    }
    
    // MARK: - Workout Cache
    func addWorkoutSession(_ session: WorkoutSession) {
        cacheLock.async {
            var sessions = self.workoutSessions
            sessions.insert(session, at: 0) // Add to top
            
            // Keep only last 100 workouts
            if sessions.count > 100 {
                sessions = Array(sessions.prefix(100))
            }
            
            let success = self.storage.save(sessions, forKey: "cached_workouts")
            DispatchQueue.main.async {
                if success {
                    self.workoutSessions = sessions
                    self.logger.workout("Workout session cached: \(session.name)")
                }
            }
        }
    }
    
    func updateWorkoutSessions(_ sessions: [WorkoutSession]) {
        cacheLock.async {
            let success = self.storage.save(sessions, forKey: "cached_workouts")
            DispatchQueue.main.async {
                if success {
                    self.workoutSessions = sessions
                    self.logger.storage("Workout sessions updated (\(sessions.count) sessions)")
                }
            }
        }
    }
    
    func getWorkoutHistory(for days: Int = 30) -> [WorkoutSession] {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        return workoutSessions.filter { $0.date >= cutoffDate }
    }
    
    // MARK: - Meal Cache
    func addMealEntry(_ meal: MealEntry) {
        cacheLock.async {
            var meals = self.mealEntries
            meals.insert(meal, at: 0) // Add to top
            
            // Keep only last 500 meals
            if meals.count > 500 {
                meals = Array(meals.prefix(500))
            }
            
            let success = self.storage.save(meals, forKey: "cached_meals")
            DispatchQueue.main.async {
                if success {
                    self.mealEntries = meals
                    self.logger.meal("Meal entry cached: \(meal.name)")
                }
            }
        }
    }
    
    func updateMealEntries(_ meals: [MealEntry]) {
        cacheLock.async {
            let success = self.storage.save(meals, forKey: "cached_meals")
            DispatchQueue.main.async {
                if success {
                    self.mealEntries = meals
                    self.logger.storage("Meal entries updated (\(meals.count) meals)")
                }
            }
        }
    }
    
    func getMealHistory(for days: Int = 30) -> [MealEntry] {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        return mealEntries.filter { $0.date >= cutoffDate }
    }
    
    func getTodaysMeals() -> [MealEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return mealEntries.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    func calculateTodaysNutrition() -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let todaysMeals = getTodaysMeals()
        return (
            calories: todaysMeals.reduce(0) { $0 + $1.calories },
            protein: todaysMeals.reduce(0) { $0 + $1.protein },
            carbs: todaysMeals.reduce(0) { $0 + $1.carbs },
            fat: todaysMeals.reduce(0) { $0 + $1.fat }
        )
    }
    
    // MARK: - Daily Stats
    func updateDailyStats(_ stats: DailyStats) {
        cacheLock.async {
            let success = self.storage.save(stats, forKey: "cached_daily_stats")
            DispatchQueue.main.async {
                if success {
                    self.dailyStats = stats
                    self.logger.storage("Daily stats updated")
                }
            }
        }
    }
    
    func calculateTodaysStats() -> DailyStats {
        let meals = getTodaysMeals()
        let todayWorkouts = workoutSessions.filter { session in
            Calendar.current.isDate(session.date, inSameDayAs: Date())
        }
        
        let nutrition = calculateTodaysNutrition()
        let totalCaloriesBurned = todayWorkouts.reduce(0) { $0 + $1.caloriesBurned }
        
        return DailyStats(
            date: Date(),
            totalCaloriesConsumed: nutrition.calories,
            totalCaloriesBurned: totalCaloriesBurned,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            workoutsCompleted: todayWorkouts.count,
            mealsLogged: meals.count,
            waterIntake: 0, // Can be fetched from HealthKit
            steps: 0 // Can be fetched from HealthKit
        )
    }
    
    // MARK: - Sync Management
    func markSynced() {
        cacheLock.async {
            DispatchQueue.main.async {
                self.lastSyncTime = Date()
                self.isSynced = true
                self.storage.save(Date(), forKey: "last_sync_time")
                self.logger.storage("Data synced at \(self.lastSyncTime?.description ?? "unknown")")
            }
        }
    }
    
    func isCacheExpired() -> Bool {
        guard let lastSync = lastSyncTime else { return true }
        return Date().timeIntervalSince(lastSync) > cacheExpiryInterval
    }
    
    // MARK: - Clear Cache
    func clearAllCache() {
        cacheLock.async {
            self.storage.removeStoredObject(forKey: "cached_user_profile")
            self.storage.removeStoredObject(forKey: "cached_workouts")
            self.storage.removeStoredObject(forKey: "cached_meals")
            self.storage.removeStoredObject(forKey: "cached_daily_stats")
            self.storage.removeStoredObject(forKey: "last_sync_time")
            
            DispatchQueue.main.async {
                self.userProfile = nil
                self.workoutSessions = []
                self.mealEntries = []
                self.dailyStats = nil
                self.lastSyncTime = nil
                self.isSynced = false
                self.logger.storage("All cache cleared")
            }
        }
    }
    
    // MARK: - Statistics
    func getWeeklyStats(endingOn date: Date = Date()) -> WeeklyStats {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: date) ?? date
        
        let weekWorkouts = workoutSessions.filter { $0.date >= weekAgo && $0.date <= date }
        let weekMeals = mealEntries.filter { $0.date >= weekAgo && $0.date <= date }
        
        let totalCaloriesConsumed = weekMeals.reduce(0) { $0 + $1.calories }
        let totalCaloriesBurned = weekWorkouts.reduce(0) { $0 + $1.caloriesBurned }
        let avgCaloriesPerDay = totalCaloriesConsumed / 7
        let avgProteinPerDay = weekMeals.reduce(0) { $0 + $1.protein } / 7
        
        return WeeklyStats(
            startDate: weekAgo,
            endDate: date,
            totalWorkouts: weekWorkouts.count,
            totalMealsLogged: weekMeals.count,
            totalCaloriesConsumed: totalCaloriesConsumed,
            totalCaloriesBurned: totalCaloriesBurned,
            averageCaloriesPerDay: avgCaloriesPerDay,
            averageProteinPerDay: avgProteinPerDay
        )
    }
}

// MARK: - Data Models
struct UserProfileCache: Codable {
    var userId: String
    var name: String
    var email: String
    var age: Int?
    var weightKg: Double
    var heightCm: Double
    var goal: String
    var activityLevel: String
    var profileImageURL: String?
    var lastUpdated: Date
}

struct DailyStats: Codable, Identifiable {
    let id = UUID()
    var date: Date
    var totalCaloriesConsumed: Double
    var totalCaloriesBurned: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var workoutsCompleted: Int
    var mealsLogged: Int
    var waterIntake: Double // in liters
    var steps: Int
    
    func getCalorieDeficit() -> Double {
        return totalCaloriesBurned - totalCaloriesConsumed
    }
    
    func getMacroPercentages() -> (protein: Double, carbs: Double, fat: Double) {
        let total = protein + carbs + fat
        guard total > 0 else { return (0, 0, 0) }
        
        return (
            protein: (protein / total) * 100,
            carbs: (carbs / total) * 100,
            fat: (fat / total) * 100
        )
    }
}

struct WeeklyStats: Codable {
    var startDate: Date
    var endDate: Date
    var totalWorkouts: Int
    var totalMealsLogged: Int
    var totalCaloriesConsumed: Double
    var totalCaloriesBurned: Double
    var averageCaloriesPerDay: Double
    var averageProteinPerDay: Double
    
    func getAverageCalorieDeficit() -> Double {
        return (totalCaloriesBurned - totalCaloriesConsumed) / 7
    }
    
    func getCompletionRate() -> Double {
        // Assuming daily goal is 1 workout minimum
        return Double(totalWorkouts) / 7.0
    }
}
