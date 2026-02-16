import Foundation
import Combine

/// Centralized device storage manager for all persistent data
/// Handles user preferences, app cache, and local data synchronization
final class DeviceStorageManager: ObservableObject {
    static let shared = DeviceStorageManager()
    
    private init() {
        loadStorageQuota()
    }
    
    // MARK: - Properties
    @Published private(set) var storageUsed: UInt64 = 0
    @Published private(set) var storageAvailable: UInt64 = 0
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let storageLock = DispatchQueue(label: "device.storage.manager.queue")
    
    // MARK: - Storage Paths
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var cacheURL: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    private var appStorageURL: URL {
        documentsURL.appendingPathComponent("GoFitAppData", isDirectory: true)
    }
    
    // MARK: - Initialization
    func initialize() {
        storageLock.async {
            // Create necessary directories
            try? self.fileManager.createDirectory(at: self.appStorageURL, withIntermediateDirectories: true)
            
            // Load initial storage info
            DispatchQueue.main.async {
                self.loadStorageQuota()
            }
            
            print("✅ DeviceStorageManager initialized")
        }
    }
    
    // MARK: - Storage Quota Management
    private func loadStorageQuota() {
        storageLock.async {
            let attributes = try? self.fileManager.attributesOfFileSystem(forPath: self.documentsURL.path)
            let available = (attributes?[.systemFreeSize] as? NSNumber)?.unsignedLongLongValue ?? 0
            let total = (attributes?[.systemSize] as? NSNumber)?.unsignedLongLongValue ?? 0
            let used = total - available
            
            DispatchQueue.main.async {
                self.storageAvailable = available
                self.storageUsed = used
            }
        }
    }
    
    // MARK: - User Preferences Storage
    func saveUserPreference(_ value: Any?, forKey key: String) {
        storageLock.async {
            self.defaults.set(value, forKey: "gofit_pref_\(key)")
            self.defaults.synchronize()
            print("💾 Saved preference: \(key)")
        }
    }
    
    func getUserPreference(forKey key: String) -> Any? {
        return storageLock.sync {
            defaults.object(forKey: "gofit_pref_\(key)")
        }
    }
    
    func getUserPreference(forKey key: String, defaultValue: Bool) -> Bool {
        return storageLock.sync {
            if let value = defaults.object(forKey: "gofit_pref_\(key)") as? Bool {
                return value
            }
            return defaultValue
        }
    }
    
    func getUserPreference(forKey key: String, defaultValue: String) -> String {
        return storageLock.sync {
            return (defaults.object(forKey: "gofit_pref_\(key)") as? String) ?? defaultValue
        }
    }
    
    func removeUserPreference(forKey key: String) {
        storageLock.async {
            self.defaults.removeObject(forKey: "gofit_pref_\(key)")
            self.defaults.synchronize()
        }
    }
    
    // MARK: - Codable Storage
    func save<T: Codable>(_ object: T, forKey key: String) -> Bool {
        return storageLock.sync {
            do {
                let data = try JSONEncoder().encode(object)
                let path = appStorageURL.appendingPathComponent("\(key).json")
                try data.write(to: path, options: [.atomic])
                print("✅ Saved codable object: \(key)")
                return true
            } catch {
                print("❌ Failed to save codable object \(key): \(error)")
                return false
            }
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return storageLock.sync {
            do {
                let path = appStorageURL.appendingPathComponent("\(key).json")
                let data = try Data(contentsOf: path)
                let object = try JSONDecoder().decode(T.self, from: data)
                print("✅ Loaded codable object: \(key)")
                return object
            } catch {
                print("⚠️ Failed to load codable object \(key): \(error)")
                return nil
            }
        }
    }
    
    func removeStoredObject(forKey key: String) -> Bool {
        return storageLock.sync {
            do {
                let path = appStorageURL.appendingPathComponent("\(key).json")
                try fileManager.removeItem(at: path)
                print("✅ Removed stored object: \(key)")
                return true
            } catch {
                print("⚠️ Failed to remove stored object \(key): \(error)")
                return false
            }
        }
    }
    
    // MARK: - Image Storage
    func saveImage(_ image: Data, forKey key: String) -> Bool {
        return storageLock.sync {
            do {
                let path = appStorageURL.appendingPathComponent("images").appendingPathComponent("\(key).jpg")
                try fileManager.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
                try image.write(to: path, options: [.atomic])
                print("✅ Saved image: \(key)")
                return true
            } catch {
                print("❌ Failed to save image \(key): \(error)")
                return false
            }
        }
    }
    
    func loadImage(forKey key: String) -> Data? {
        return storageLock.sync {
            do {
                let path = appStorageURL.appendingPathComponent("images").appendingPathComponent("\(key).jpg")
                let data = try Data(contentsOf: path)
                print("✅ Loaded image: \(key)")
                return data
            } catch {
                print("⚠️ Failed to load image \(key): \(error)")
                return nil
            }
        }
    }
    
    func removeImage(forKey key: String) -> Bool {
        return storageLock.sync {
            do {
                let path = appStorageURL.appendingPathComponent("images").appendingPathComponent("\(key).jpg")
                try fileManager.removeItem(at: path)
                print("✅ Removed image: \(key)")
                return true
            } catch {
                print("⚠️ Failed to remove image \(key): \(error)")
                return false
            }
        }
    }
    
    // MARK: - Workout Cache
    func saveWorkoutHistory(_ workouts: [WorkoutSession]) -> Bool {
        return save(workouts, forKey: "workout_history")
    }
    
    func loadWorkoutHistory() -> [WorkoutSession]? {
        return load([WorkoutSession].self, forKey: "workout_history")
    }
    
    // MARK: - Meal Cache
    func saveMealHistory(_ meals: [MealEntry]) -> Bool {
        return save(meals, forKey: "meal_history")
    }
    
    func loadMealHistory() -> [MealEntry]? {
        return load([MealEntry].self, forKey: "meal_history")
    }
    
    // MARK: - User Settings
    func saveUserSettings(_ settings: UserSettings) -> Bool {
        return save(settings, forKey: "user_settings")
    }
    
    func loadUserSettings() -> UserSettings? {
        return load(UserSettings.self, forKey: "user_settings")
    }
    
    // MARK: - Cache Cleanup
    func clearExpiredCache() {
        storageLock.async {
            do {
                let imagesURL = self.appStorageURL.appendingPathComponent("images")
                if self.fileManager.fileExists(atPath: imagesURL.path) {
                    let files = try self.fileManager.contentsOfDirectory(at: imagesURL, includingPropertiesForKeys: [.contentModificationDateKey])
                    let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
                    
                    for file in files {
                        if let attributes = try? self.fileManager.attributesOfItem(atPath: file.path),
                           let modDate = attributes[.modificationDate] as? Date,
                           modDate < thirtyDaysAgo {
                            try? self.fileManager.removeItem(at: file)
                            print("🗑️ Cleared expired image: \(file.lastPathComponent)")
                        }
                    }
                }
            } catch {
                print("⚠️ Error during cache cleanup: \(error)")
            }
        }
    }
    
    // MARK: - Storage Info
    func getStorageInfo() -> (used: String, available: String, percentage: Double) {
        let usedGB = Double(storageUsed) / (1024 * 1024 * 1024)
        let availableGB = Double(storageAvailable) / (1024 * 1024 * 1024)
        let total = usedGB + availableGB
        let percentage = total > 0 ? (usedGB / total) * 100 : 0
        
        return (
            used: String(format: "%.2f GB", usedGB),
            available: String(format: "%.2f GB", availableGB),
            percentage: percentage
        )
    }
    
    // MARK: - Cleanup & Reset
    func clearAllAppData() -> Bool {
        return storageLock.sync {
            do {
                try fileManager.removeItem(at: appStorageURL)
                try fileManager.createDirectory(at: appStorageURL, withIntermediateDirectories: true)
                print("🧹 Cleared all app storage data")
                return true
            } catch {
                print("❌ Failed to clear app data: \(error)")
                return false
            }
        }
    }
}

// MARK: - Data Models
struct UserSettings: Codable {
    var userId: String?
    var appVersion: String = "1.0"
    var lastSyncDate: Date?
    var autoSyncEnabled: Bool = true
    var cacheExpiryDays: Int = 30
    var notificationSettings: [String: Bool] = [:]
    var uiPreferences: [String: String] = [:]
}

struct WorkoutSession: Codable, Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var duration: TimeInterval
    var caloriesBurned: Double
    var exercises: [ExerciseRecord]
    var date: Date
    var notes: String?
    
    init(name: String, duration: TimeInterval, caloriesBurned: Double, exercises: [ExerciseRecord], date: Date = Date(), notes: String? = nil) {
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exercises = exercises
        self.date = date
        self.notes = notes
    }
}

struct ExerciseRecord: Codable, Identifiable {
    let id: String = UUID().uuidString
    var exerciseName: String
    var sets: Int
    var reps: [Int]
    var weight: Double? // in kg
    var duration: TimeInterval? // for cardio
    var imageURL: String? // reference to stored image
    
    init(exerciseName: String, sets: Int, reps: [Int], weight: Double? = nil, duration: TimeInterval? = nil, imageURL: String? = nil) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.imageURL = imageURL
    }
}

struct MealEntry: Codable, Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var date: Date
    var mealType: String // breakfast, lunch, dinner, snack
    var imageURL: String?
    var notes: String?
    
    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, date: Date = Date(), mealType: String = "lunch", imageURL: String? = nil, notes: String? = nil) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
        self.mealType = mealType
        self.imageURL = imageURL
        self.notes = notes
    }
}
