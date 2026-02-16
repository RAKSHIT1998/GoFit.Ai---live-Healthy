# Device Storage & Logging - Quick Reference Guide

## 🎯 Quick Start (Copy & Paste)

### Initialize in App Launch
```swift
// In GofitAIApp.swift
@main
struct GofitAIApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    DeviceStorageManager.shared.initialize()
                    AppLogger.shared.log("App started", level: .info)
                }
        }
    }
}
```

---

## 📦 DeviceStorageManager - Common Operations

### Save Preferences
```swift
DeviceStorageManager.shared.saveUserPreference(true, forKey: "notificationsEnabled")
DeviceStorageManager.shared.saveUserPreference("dark", forKey: "theme")
```

### Load Preferences
```swift
let notificationsEnabled = DeviceStorageManager.shared.getUserPreference(forKey: "notificationsEnabled", defaultValue: true)
let theme = DeviceStorageManager.shared.getUserPreference(forKey: "theme", defaultValue: "light")
```

### Save Codable Objects
```swift
let workout = WorkoutSession(name: "Leg Day", duration: 3600, caloriesBurned: 400, exercises: [...])
DeviceStorageManager.shared.save(workout, forKey: "current_workout")
```

### Load Codable Objects
```swift
if let workout = DeviceStorageManager.shared.load(WorkoutSession.self, forKey: "current_workout") {
    print("Loaded workout: \(workout.name)")
}
```

### Save/Load Images
```swift
// Save
if let imageData = image.jpegData(compressionQuality: 0.8) {
    DeviceStorageManager.shared.saveImage(imageData, forKey: "meal_photo_001")
}

// Load
if let imageData = DeviceStorageManager.shared.loadImage(forKey: "meal_photo_001") {
    let uiImage = UIImage(data: imageData)
}
```

### Clear Cache
```swift
DeviceStorageManager.shared.clearAllCache()
```

### Get Storage Info
```swift
let info = DeviceStorageManager.shared.getStorageInfo()
print("Used: \(info.used), Available: \(info.available), Usage: \(info.percentage)%")
```

---

## 📝 AppLogger - Common Operations

### Basic Logging
```swift
AppLogger.shared.log("Message", level: .info, category: "MyCategoryName")
AppLogger.shared.log("Error occurred", level: .error, category: "DataProcessing")
AppLogger.shared.log("Success!", level: .success, category: "Upload")
```

### Specialized Logging Methods
```swift
// Authentication
AppLogger.shared.auth("User logged in with Apple Sign In")

// Workout tracking
AppLogger.shared.workout("Completed 45min strength training - 300cal burned")

// Meal logging
AppLogger.shared.meal("Logged breakfast: 450cal, 25g protein")

// Storage operations
AppLogger.shared.storage("Saved user profile to device")

// HealthKit operations
AppLogger.shared.healthKit("Synced 5000 steps from HealthKit")

// User actions
AppLogger.shared.activity("User viewed workout details")
```

### Network Logging
```swift
let start = Date()
let result = try await someNetworkCall()
let duration = Date().timeIntervalSince(start)

AppLogger.shared.logNetworkRequest(
    url: "api/workouts",
    method: "GET",
    statusCode: 200,
    duration: duration
)
```

### Error Logging
```swift
do {
    try someFunction()
} catch {
    AppLogger.shared.logError(
        error,
        category: "FileProcessing",
        context: "Failed to load workout history"
    )
}
```

### Performance Tracking
```swift
let start = Date()
calculateComplexStats()
let duration = (Date().timeIntervalSince(start)) * 1000 // Convert to ms
AppLogger.shared.logPerformance(operation: "Calculate Daily Stats", duration: duration)
```

### Memory Monitoring
```swift
AppLogger.shared.logMemoryUsage()
```

### Export & Clear Logs
```swift
// Export all logs to file
if let exportURL = AppLogger.shared.exportLogs() {
    print("Logs saved to: \(exportURL)")
    // Share with user or upload to backend
}

// Clear old logs (older than 7 days)
AppLogger.shared.clearOldLogs(olderThanDays: 7)

// Get all logs as string
let allLogs = AppLogger.shared.getLogsAsString()
```

---

## 💾 UserDataCache - Common Operations

### Update User Profile
```swift
let profile = UserProfileCache(
    userId: "123",
    name: "John Doe",
    email: "john@example.com",
    age: 30,
    weightKg: 75,
    heightCm: 180,
    goal: "lose",
    activityLevel: "moderate",
    lastUpdated: Date()
)
UserDataCache.shared.updateUserProfile(profile)
```

### Add Workout
```swift
let exercise = ExerciseRecord(
    exerciseName: "Bench Press",
    sets: 4,
    reps: [10, 10, 8, 8],
    weight: 100
)

let workout = WorkoutSession(
    name: "Upper Body",
    duration: 2700,
    caloriesBurned: 250,
    exercises: [exercise]
)

UserDataCache.shared.addWorkoutSession(workout)
```

### Add Meal
```swift
let meal = MealEntry(
    name: "Grilled Chicken with Rice",
    calories: 550,
    protein: 40,
    carbs: 60,
    fat: 12,
    date: Date(),
    mealType: "lunch"
)

UserDataCache.shared.addMealEntry(meal)
```

### Get Cached Data
```swift
// Get all workouts
let allWorkouts = UserDataCache.shared.workoutSessions

// Get workouts from last 30 days
let monthWorkouts = UserDataCache.shared.getWorkoutHistory(for: 30)

// Get today's meals
let todaysMeals = UserDataCache.shared.getTodaysMeals()

// Get meal history
let mealHistory = UserDataCache.shared.getMealHistory(for: 14)
```

### Calculate Statistics
```swift
// Today's nutrition totals
let nutrition = UserDataCache.shared.calculateTodaysNutrition()
print("Calories: \(nutrition.calories), Protein: \(nutrition.protein)g")

// Today's stats (includes workouts)
let todaysStats = UserDataCache.shared.calculateTodaysStats()
print("Calorie deficit: \(todaysStats.getCalorieDeficit())")

// Weekly stats
let weekStats = UserDataCache.shared.getWeeklyStats()
print("Avg calories/day: \(weekStats.averageCaloriesPerDay)")
print("Workouts completed: \(weekStats.totalWorkouts)")
```

### Sync Management
```swift
// Check if cache needs refresh (6 hour expiry)
if UserDataCache.shared.isCacheExpired() {
    // Fetch from backend
    refreshDataFromServer()
}

// Mark data as synced
UserDataCache.shared.markSynced()

// Get last sync time
if let lastSync = UserDataCache.shared.lastSyncTime {
    print("Last synced: \(lastSync)")
}

// Check sync status
if UserDataCache.shared.isSynced {
    print("Data is in sync")
}
```

### Clear Cache
```swift
UserDataCache.shared.clearAllCache()
UserDataCache.shared.clearUserProfile()
```

---

## 🎨 WorkoutCardView - Usage

### Basic Usage
```swift
struct WorkoutListView: View {
    @ObservedObject var cache = UserDataCache.shared
    
    var body: some View {
        List(cache.workoutSessions) { workout in
            WorkoutCardView(workout: workout)
        }
    }
}
```

### With Filtering
```swift
struct RecentWorkoutsView: View {
    @ObservedObject var cache = UserDataCache.shared
    
    var recentWorkouts: [WorkoutSession] {
        cache.getWorkoutHistory(for: 7) // Last 7 days
    }
    
    var body: some View {
        List(recentWorkouts) { workout in
            WorkoutCardView(workout: workout)
        }
    }
}
```

---

## 🔄 Complete Offline-First Example

```swift
struct OfflineFirstView: View {
    @ObservedObject var cache = UserDataCache.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Show cached data
            List(cache.workoutSessions) { workout in
                WorkoutCardView(workout: workout)
            }
            .refreshable {
                await refreshFromServer()
            }
            
            // Show loading indicator
            if isLoading {
                ProgressView()
            }
        }
        .onAppear(perform: checkAndSync)
    }
    
    private func checkAndSync() {
        // Show cached data immediately
        AppLogger.shared.log("View appeared, showing \(cache.workoutSessions.count) cached workouts")
        
        // Check if we need to sync in background
        if cache.isCacheExpired() {
            Task {
                await refreshFromServer()
            }
        }
    }
    
    private func refreshFromServer() async {
        isLoading = true
        AppLogger.shared.logAction(action: "Refreshing workouts from server")
        
        do {
            // Simulate backend call
            // let workouts: [WorkoutSession] = try await NetworkManager.shared.request("workouts")
            // cache.updateWorkoutSessions(workouts)
            
            cache.markSynced()
            AppLogger.shared.logSuccess("Workouts synced")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.shared.logError(error, context: "Failed to refresh workouts")
        }
        
        isLoading = false
    }
}
```

---

## 📊 Add to Settings View

```swift
struct StorageSettingsView: View {
    var body: some View {
        Form {
            Section("Storage") {
                let info = DeviceStorageManager.shared.getStorageInfo()
                
                HStack {
                    Text("Used Storage")
                    Spacer()
                    Text(info.used)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Available")
                    Spacer()
                    Text(info.available)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: info.percentage / 100)
            }
            
            Section("Cache") {
                HStack {
                    Text("Cached Workouts")
                    Spacer()
                    Text("\(UserDataCache.shared.workoutSessions.count)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Cached Meals")
                    Spacer()
                    Text("\(UserDataCache.shared.mealEntries.count)")
                        .fontWeight(.semibold)
                }
                
                if let lastSync = UserDataCache.shared.lastSyncTime {
                    HStack {
                        Text("Last Synced")
                        Spacer()
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.semibold)
                    }
                }
                
                Button(action: { UserDataCache.shared.markSynced() }) {
                    Text("Refresh Cache")
                }
            }
            
            Section("Debug") {
                Button("Export Logs") {
                    AppLogger.shared.exportLogs()
                }
                
                Button("Clear All Cache", role: .destructive) {
                    UserDataCache.shared.clearAllCache()
                    DeviceStorageManager.shared.clearAllAppData()
                }
            }
        }
    }
}
```

---

## 🚀 Pro Tips

1. **Always log important actions** for debugging in production
2. **Use cache first, sync in background** for better UX
3. **Clear old logs regularly** to manage storage
4. **Check cache expiry** before displaying stale data
5. **Test offline mode** by disabling network
6. **Monitor memory usage** during heavy operations
7. **Export logs** when users report issues
8. **Implement background sync** for seamless updates

---

## 📍 File Locations

- **DeviceStorageManager**: `Services/DeviceStorageManager.swift`
- **AppLogger**: `Services/AppLogger.swift`
- **UserDataCache**: `Services/UserDataCache.swift`
- **WorkoutCardView**: `Features/Workout/WorkoutCardView.swift`
- **Example Integration**: `Features/Examples/ExampleStorageIntegrationView.swift`
- **Documentation**: `LOCAL_STORAGE_IMPLEMENTATION.md`
