import Foundation
import Combine

/// Local storage service for daily logs - stores up to 30 days of data
final class LocalDailyLogStore: ObservableObject {
    static let shared = LocalDailyLogStore()
    private init() {
        load()
        cleanupOldLogs()
    }
    
    @Published private(set) var logs: [DailyLog] = []
    private let maxDays = 30 // Keep 30 days of data
    
    private let storageURL: URL = {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("daily_logs.json")
    }()
    
    private let storageLock = DispatchQueue(label: "local.daily.log.store")
    
    // MARK: - Load & Save
    
    private func load() {
        storageLock.sync {
            guard FileManager.default.fileExists(atPath: storageURL.path) else {
                DispatchQueue.main.async {
                    self.logs = []
                }
                return
            }
            do {
                let data = try Data(contentsOf: storageURL)
                let decodedLogs = try JSONDecoder().decode([DailyLog].self, from: data)
                // Sort by date (newest first)
                let sortedLogs = decodedLogs.sorted { $0.date > $1.date }
                DispatchQueue.main.async {
                    self.logs = sortedLogs
                }
                print("✅ Loaded \(sortedLogs.count) daily logs from local storage")
            } catch {
                print("⚠️ Failed to load daily logs: \(error)")
                DispatchQueue.main.async {
                    self.logs = []
                }
            }
        }
    }
    
    private func persist() {
        // This method is called from within sync blocks, so we need to persist asynchronously
        // to avoid deadlocks. The data is already captured by the caller's sync block context.
        // We'll encode and write on a background queue to avoid blocking.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // Capture current state synchronously
            let logsToPersist: [DailyLog]
            self.storageLock.sync {
                logsToPersist = self.logs
            }
            
            // Persist outside the lock
            do {
                let data = try JSONEncoder().encode(logsToPersist)
                try data.write(to: self.storageURL, options: [.atomic])
            } catch {
                print("⚠️ Failed to persist daily logs: \(error)")
            }
        }
    }
    
    // MARK: - Get or Create Daily Log
    
    /// Get or create a daily log for a specific date
    /// Note: This method should only be called from within storageLock.sync blocks
    private func getOrCreateLog(for date: Date) -> DailyLog {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        if let existingLog = logs.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            return existingLog
        }
        
        let newLog = DailyLog(date: normalizedDate)
        var updatedLogs = logs
        updatedLogs.append(newLog)
        updatedLogs.sort { $0.date > $1.date }
        logs = updatedLogs // Trigger @Published
        return newLog
    }
    
    // MARK: - Meal Operations
    
    /// Add a meal to today's log
    func addMeal(_ meal: LoggedMeal) {
        storageLock.sync {
            let today = Calendar.current.startOfDay(for: Date())
            let calendar = Calendar.current
            var updatedLogs = logs
            
            if let index = updatedLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                var log = updatedLogs[index]
                log.meals.append(meal)
                log.meals.sort { $0.timestamp > $1.timestamp }
                updatedLogs[index] = log
            } else {
                var newLog = DailyLog(date: today)
                newLog.meals.append(meal)
                updatedLogs.append(newLog)
                updatedLogs.sort { $0.date > $1.date }
            }
            
            DispatchQueue.main.async {
                self.logs = updatedLogs
            }
            
            persist()
            print("✅ Added meal to daily log: \(meal.mealType.displayName)")
        }
    }
    
    /// Remove a meal from today's log
    func removeMeal(mealId: String) {
        storageLock.sync {
            let today = Calendar.current.startOfDay(for: Date())
            var updatedLogs = logs
            if let index = updatedLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                updatedLogs[index].meals.removeAll { $0.id == mealId }
                DispatchQueue.main.async {
                    self.logs = updatedLogs
                }
                persist()
            }
        }
    }
    
    // MARK: - Liquid Intake Operations
    
    /// Add liquid intake to today's log
    func addLiquidIntake(_ entry: LiquidEntry) {
        storageLock.sync {
            let today = Calendar.current.startOfDay(for: Date())
            let calendar = Calendar.current
            var updatedLogs = logs
            
            if let index = updatedLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                var log = updatedLogs[index]
                log.liquidIntake.append(entry)
                log.liquidIntake.sort { $0.timestamp > $1.timestamp }
                updatedLogs[index] = log
            } else {
                var newLog = DailyLog(date: today)
                newLog.liquidIntake.append(entry)
                updatedLogs.append(newLog)
                updatedLogs.sort { $0.date > $1.date }
            }
            
            DispatchQueue.main.async {
                self.logs = updatedLogs
            }
            
            persist()
            print("✅ Added liquid intake: \(entry.amount)L \(entry.beverageType.displayName)")
        }
    }
    
    /// Remove liquid intake entry
    func removeLiquidIntake(entryId: String) {
        storageLock.sync {
            let today = Calendar.current.startOfDay(for: Date())
            var updatedLogs = logs
            if let index = updatedLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                updatedLogs[index].liquidIntake.removeAll { $0.id == entryId }
                DispatchQueue.main.async {
                    self.logs = updatedLogs
                }
                persist()
            }
        }
    }
    
    // MARK: - Activity Operations
    
    /// Update calories burned for a specific date
    func updateCaloriesBurned(_ calories: Double, for date: Date = Date()) {
        storageLock.sync {
            let normalizedDate = Calendar.current.startOfDay(for: date)
            let calendar = Calendar.current
            var updatedLogs = logs
            
            if let index = updatedLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
                var log = updatedLogs[index]
                log.caloriesBurned = calories
                updatedLogs[index] = log
            } else {
                var newLog = DailyLog(date: normalizedDate)
                newLog.caloriesBurned = calories
                updatedLogs.append(newLog)
                updatedLogs.sort { $0.date > $1.date }
            }
            
            DispatchQueue.main.async {
                self.logs = updatedLogs
            }
            
            persist()
        }
    }
    
    /// Update steps for a specific date
    func updateSteps(_ steps: Int, for date: Date = Date()) {
        storageLock.sync {
            let normalizedDate = Calendar.current.startOfDay(for: date)
            let calendar = Calendar.current
            var updatedLogs = logs
            
            if let index = updatedLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
                var log = updatedLogs[index]
                log.steps = steps
                updatedLogs[index] = log
            } else {
                var newLog = DailyLog(date: normalizedDate)
                newLog.steps = steps
                updatedLogs.append(newLog)
                updatedLogs.sort { $0.date > $1.date }
            }
            
            DispatchQueue.main.async {
                self.logs = updatedLogs
            }
            
            persist()
        }
    }
    
    // MARK: - Query Operations
    
    /// Get log for a specific date
    func getLog(for date: Date) -> DailyLog? {
        return storageLock.sync {
            let normalizedDate = Calendar.current.startOfDay(for: date)
            return logs.first { Calendar.current.isDate($0.date, inSameDayAs: normalizedDate) }
        }
    }
    
    /// Get today's log
    func getTodayLog() -> DailyLog {
        return storageLock.sync {
            let today = Calendar.current.startOfDay(for: Date())
            return getOrCreateLog(for: today)
        }
    }
    
    /// Get all logs (last 30 days)
    func getAllLogs() -> [DailyLog] {
        return storageLock.sync { logs }
    }
    
    /// Get logs for a date range
    func getLogs(from startDate: Date, to endDate: Date) -> [DailyLog] {
        return storageLock.sync {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let end = calendar.startOfDay(for: endDate)
            
            return logs.filter { log in
                log.date >= start && log.date <= end
            }
        }
    }
    
    /// Get logs for the last N days
    func getLogsForLastDays(_ days: Int) -> [DailyLog] {
        return storageLock.sync {
            let calendar = Calendar.current
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let cutoff = calendar.startOfDay(for: cutoffDate)
            
            return logs.filter { $0.date >= cutoff }
        }
    }
    
    // MARK: - Statistics
    
    /// Get average daily calories for the last N days
    func getAverageCalories(days: Int = 7) -> Double {
        let recentLogs = getLogsForLastDays(days)
        guard !recentLogs.isEmpty else { return 0 }
        
        let total = recentLogs.reduce(0.0) { $0 + $1.totalCalories }
        return total / Double(recentLogs.count)
    }
    
    /// Get average daily sugar for the last N days
    func getAverageSugar(days: Int = 7) -> Double {
        let recentLogs = getLogsForLastDays(days)
        guard !recentLogs.isEmpty else { return 0 }
        
        let total = recentLogs.reduce(0.0) { $0 + $1.totalSugar }
        return total / Double(recentLogs.count)
    }
    
    // MARK: - Cleanup
    
    /// Remove logs older than maxDays
    private func cleanupOldLogs() {
        storageLock.sync {
            let calendar = Calendar.current
            let cutoffDate = calendar.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
            let cutoff = calendar.startOfDay(for: cutoffDate)
            
            let beforeCount = logs.count
            logs = logs.filter { $0.date >= cutoff }
            let afterCount = logs.count
            
            if beforeCount != afterCount {
                persist()
                print("🧹 Cleaned up \(beforeCount - afterCount) old daily logs")
            }
        }
    }
    
    /// Clear all logs
    func clearAll() {
        storageLock.sync {
            logs.removeAll()
            persist()
        }
    }
}
