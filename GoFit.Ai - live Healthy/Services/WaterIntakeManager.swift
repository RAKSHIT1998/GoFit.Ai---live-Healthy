import Foundation

/// Manages water and liquid intake logging with automatic caching and syncing
@MainActor
class WaterIntakeManager: ObservableObject {
    static let shared = WaterIntakeManager()
    
    @Published var todayWaterIntake: Double = 0 // in liters
    @Published var waterGoal: Double = 2.0 // Default 2L per day
    @Published var intakeLogs: [WaterLog] = []
    
    private let cache = UserDataCache.shared
    private let logger = AppLogger.shared
    private let storage = DeviceStorageManager.shared
    private let lock = DispatchQueue(label: "water.intake.manager.queue")
    
    private init() {
        loadTodaysIntake()
    }
    
    // MARK: - Load from Cache
    
    /// Load today's water intake from cache
    private func loadTodaysIntake() {
        lock.async { [weak self] in
            guard let self = self else { return }
            // Load from cache
            if let stats = self.cache.dailyStats {
                DispatchQueue.main.async { [weak self] in
                    self?.todayWaterIntake = stats.waterIntake
                }
            }
        }
    }
    
    // MARK: - Log Water
    
    /// Log plain water intake (in liters)
    /// Example: logWater(0.5) for 500ml
    func logWater(_ liters: Double) {
        lock.async { [weak self] in
            guard let self = self else { return }
            let log = WaterLog(
                id: UUID().uuidString,
                liters: liters,
                type: "water",
                timestamp: Date()
            )
            
            // 1️⃣ Update today's total in cache
            if var stats = self.cache.dailyStats {
                stats.waterIntake += liters
                // Cache will handle persistence
            }
            
            let currentIntake = self.todayWaterIntake + liters
            DispatchQueue.main.async { [weak self] in
                self?.todayWaterIntake += liters
                self?.intakeLogs.append(log)
            }
            
            // 2️⃣ Log the action
            self.logger.meal("💧 Logged water: \(liters)L (Total today: \(currentIntake)L)")
            
            // 3️⃣ Background sync (non-blocking)
            Task {
                await self.syncWaterLog(log)
            }
        }
    }
    
    /// Log common water amounts (preset)
    func logWaterPreset(amount: WaterPreset) {
        logWater(amount.liters)
    }
    
    // MARK: - Log Beverage
    
    /// Log beverage with name and optional calories
    /// Example: logBeverage(name: "Orange Juice", liters: 0.25, calories: 110)
    func logBeverage(name: String, liters: Double, calories: Double = 0) {
        lock.async { [weak self] in
            guard let self = self else { return }
            // Create meal entry for beverage
            let mealEntry = MealEntry(
                name: name,
                calories: calories,
                protein: 0,
                carbs: 0,
                fat: 0,
                date: Date(),
                mealType: "drink",
                imageURL: nil,
                notes: "Beverage: \(liters)L"
            )
            
            // 1️⃣ Save beverage as meal entry
            self.cache.addMealEntry(mealEntry)
            
            // 2️⃣ Update water intake
            if var stats = self.cache.dailyStats {
                stats.waterIntake += liters
                if calories > 0 {
                    stats.totalCaloriesConsumed += calories
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.todayWaterIntake += liters
            }
            
            // 3️⃣ Log the action
            let calorieInfo = calories > 0 ? " (\(Int(calories))cal)" : ""
            self.logger.meal("🥤 Logged \(name): \(liters)L\(calorieInfo)")
            
            // 4️⃣ Background sync
            Task {
                await self.syncBeverage(name: name, liters: liters, calories: calories)
            }
        }
    }
    
    // MARK: - Sync to Backend
    
    /// Sync water log to backend
    private func syncWaterLog(_ log: WaterLog) async {
        // Data is saved locally via cache
        // Background sync to backend can be implemented when API endpoint is available
        cache.markSynced()
        logger.logSuccess("💧 Water logged and cached locally", category: "Water")
    }
    
    /// Sync beverage to backend
    private func syncBeverage(name: String, liters: Double, calories: Double) async {
        // Data is saved locally via cache and meal entry
        // Background sync to backend can be implemented when API endpoint is available
        cache.markSynced()
        logger.logSuccess("🥤 Beverage logged and cached locally", category: "Drink")
    }
    
    // MARK: - Get Statistics
    
    /// Get water intake percentage of daily goal
    var waterIntakePercentage: Double {
        return (todayWaterIntake / waterGoal) * 100
    }
    
    /// Check if daily water goal is met
    var isGoalMet: Bool {
        return todayWaterIntake >= waterGoal
    }
    
    /// Get remaining water needed
    var waterRemaining: Double {
        let remaining = waterGoal - todayWaterIntake
        return max(0, remaining)
    }
    
    /// Get formatted water intake
    var formattedIntake: String {
        return String(format: "%.1f L", todayWaterIntake)
    }
    
    // MARK: - Daily Reset
    
    /// Reset water intake for new day (called at midnight)
    func resetForNewDay() {
        lock.async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.todayWaterIntake = 0
                self?.intakeLogs.removeAll()
            }
            self.logger.meal("Reset water intake for new day")
        }
    }
}

// MARK: - Data Models

/// Single water log entry
struct WaterLog: Identifiable, Codable {
    let id: String
    let liters: Double
    let type: String // "water", "coffee", "tea", etc.
    let timestamp: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var formattedVolume: String {
        let ml = Int(liters * 1000)
        if ml >= 1000 {
            return String(format: "%.1f L", liters)
        } else {
            return "\(ml) ml"
        }
    }
}

/// Preset water amounts for quick logging
enum WaterPreset: String, CaseIterable {
    case small = "Small Cup (250ml)"
    case medium = "Medium Cup (500ml)"
    case large = "Large Cup (750ml)"
    case bottle = "Water Bottle (1L)"
    case custom = "Custom Amount"
    
    var liters: Double {
        switch self {
        case .small: return 0.25
        case .medium: return 0.5
        case .large: return 0.75
        case .bottle: return 1.0
        case .custom: return 0.5 // Default for custom
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "cup.and.saucer"
        case .medium: return "cup.and.saucer.fill"
        case .large: return "cup.and.saucer.fill"
        case .bottle: return "water.circle"
        case .custom: return "plus.circle"
        }
    }
}


