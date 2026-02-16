# Local Storage & Data Logging Implementation Guide

## Overview
Enhanced the GoFit app with comprehensive device storage, data logging, and improved UI components for better offline functionality and user experience.

## 🆕 New Services

### 1. **DeviceStorageManager** 
Location: `Services/DeviceStorageManager.swift`

Centralized manager for all persistent data on device.

**Key Features:**
- User preferences storage (UserDefaults wrapper)
- Codable object storage (JSON files)
- Image storage and retrieval
- Workout/Meal history caching
- Storage quota management
- Automatic cache cleanup

**Usage Example:**
```swift
// Save user settings
let settings = UserSettings(userId: "123", autoSyncEnabled: true)
DeviceStorageManager.shared.saveUserSettings(settings)

// Save a workout
let workout = WorkoutSession(name: "Upper Body", duration: 2700, caloriesBurned: 250, exercises: [...])
DeviceStorageManager.shared.saveWorkoutHistory([workout])

// Load cached data
if let history = DeviceStorageManager.shared.loadWorkoutHistory() {
    // Use cached workouts
}

// Save user preference
DeviceStorageManager.shared.saveUserPreference(true, forKey: "notificationsEnabled")

// Save image
if let imageData = image.jpegData(compressionQuality: 0.8) {
    DeviceStorageManager.shared.saveImage(imageData, forKey: "profile_pic")
}
```

---

### 2. **AppLogger**
Location: `Services/AppLogger.swift`

Comprehensive logging system for tracking events, errors, and performance metrics.

**Key Features:**
- Multiple log levels (debug, info, warning, error, success)
- Categorized logging (UserAction, Network, Storage, etc.)
- Automatic log rotation (keeps last 5 files)
- Log file export functionality
- Memory and performance tracking
- Easy string interpolation with convenience methods

**Usage Example:**
```swift
let logger = AppLogger.shared

// Basic logging
logger.log("User signed in", level: .success, category: "Auth")

// Specialized methods
logger.auth("Apple Sign In successful")
logger.workout("Completed 45min workout")
logger.meal("Logged breakfast with 500 calories")
logger.storage("Saved user profile to cache")

// Network logging
logger.logNetworkRequest(url: "api/auth/me", method: "GET", statusCode: 200, duration: 0.45)

// Error logging
do {
    try someFunction()
} catch {
    logger.logError(error, category: "DataParsing", context: "Failed to parse workout data")
}

// Performance tracking
let start = Date()
expensiveOperation()
let duration = Date().timeIntervalSince(start) * 1000
logger.logPerformance(operation: "Calculate Daily Stats", duration: duration)

// Memory monitoring
logger.logMemoryUsage()

// Export all logs
if let exportURL = logger.exportLogs() {
    print("Logs exported to: \(exportURL)")
}
```

---

### 3. **UserDataCache**
Location: `Services/UserDataCache.swift`

Intelligent caching layer for user data with sync-on-demand capabilities.

**Key Features:**
- Cache user profile, workouts, and meals
- Calculate daily/weekly statistics
- Track sync status and cache expiration
- Offline-first data access
- Automatic cache management (keeps 100 workouts, 500 meals)
- Nutrition calculation helpers

**Usage Example:**
```swift
let cache = UserDataCache.shared

// Update cached user profile
let profile = UserProfileCache(userId: "123", name: "John", email: "john@example.com", weightKg: 75, heightCm: 180, goal: "lose", activityLevel: "moderate", lastUpdated: Date())
cache.updateUserProfile(profile)

// Add workout
let exercise = ExerciseRecord(exerciseName: "Bench Press", sets: 4, reps: [10, 10, 8, 8], weight: 100)
let workout = WorkoutSession(name: "Chest Day", duration: 3000, caloriesBurned: 300, exercises: [exercise])
cache.addWorkoutSession(workout)

// Add meal
let meal = MealEntry(name: "Chicken Salad", calories: 450, protein: 35, carbs: 30, fat: 15, mealType: "lunch")
cache.addMealEntry(meal)

// Calculate today's nutrition
let todaysNutrition = cache.calculateTodaysNutrition()
print("Calories: \(todaysNutrition.calories), Protein: \(todaysNutrition.protein)g")

// Get today's stats
let todaysStats = cache.calculateTodaysStats()
print("Deficit: \(todaysStats.getCalorieDeficit()) calories")

// Get weekly stats
let weeklyStats = cache.getWeeklyStats()
print("Avg calories/day: \(weeklyStats.averageCaloriesPerDay)")

// Check if cache needs refresh
if cache.isCacheExpired() {
    // Sync from backend
}

// Mark data as synced
cache.markSynced()
```

---

### 4. **WorkoutCardView**
Location: `Features/Workout/WorkoutCardView.swift`

Enhanced workout display component with exercise details and images.

**Components:**
- `WorkoutCardView` - Main expandable workout card
- `ExerciseItemView` - Individual exercise display
- `ExerciseDetailView` - Detailed exercise modal

**Features:**
- Expandable/collapsible workout details
- Exercise-specific metrics display
- Pro tips for form and technique
- Tap to view exercise details
- Responsive design matching app style

**Usage Example:**
```swift
// In your workout history view
@ObservedObject var cache = UserDataCache.shared

var body: some View {
    List(cache.workoutSessions) { workout in
        WorkoutCardView(workout: workout)
    }
}
```

---

## 📱 Integration Steps

### Step 1: Initialize Services in App Startup
Update `GofitAIApp.swift`:

```swift
@main
struct GofitAIApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Initialize all storage services
                    DeviceStorageManager.shared.initialize()
                    AppLogger.shared.log("App launched", level: .info, category: "Lifecycle")
                }
        }
    }
}
```

### Step 2: Integrate AppLogger Throughout App
Add logging to key operations:

```swift
// In AuthViewModel
func login(email: String, password: String) async throws {
    AppLogger.shared.logAction(user: email, action: "Login attempt")
    try await AuthService.shared.login(email: email, password: password)
    AppLogger.shared.auth("Login successful for \(email)")
}

// In NetworkManager
func request<T: Decodable>(_ endpoint: String, method: String = "GET") async throws -> T {
    let start = Date()
    let result = try await actualRequest()
    let duration = Date().timeIntervalSince(start)
    AppLogger.shared.logNetworkRequest(url: endpoint, method: method, statusCode: 200, duration: duration)
    return result
}
```

### Step 3: Use Cache for Offline-First Data
In your workout/meal views:

```swift
struct WorkoutHistoryView: View {
    @ObservedObject var cache = UserDataCache.shared
    @State private var isRefreshing = false
    
    var body: some View {
        List(cache.workoutSessions) { workout in
            WorkoutCardView(workout: workout)
        }
        .onAppear {
            // Try to sync if cache is expired
            if cache.isCacheExpired() {
                refreshFromBackend()
            }
        }
        .refreshable {
            await refreshFromBackend()
        }
    }
    
    private func refreshFromBackend() async {
        do {
            let workouts = try await NetworkManager.shared.request("workouts")
            cache.updateWorkoutSessions(workouts)
            cache.markSynced()
        } catch {
            AppLogger.shared.logError(error, context: "Failed to sync workouts")
        }
    }
}
```

### Step 4: Save User Actions
When user logs data:

```swift
// In meal logging view
func saveMeal() {
    let meal = MealEntry(...)
    
    // Save to cache immediately (offline-first)
    cache.addMealEntry(meal)
    AppLogger.shared.meal("Logged meal: \(meal.name)")
    
    // Sync to backend in background
    Task {
        do {
            try await NetworkManager.shared.uploadMeal(meal)
            cache.markSynced()
            AppLogger.shared.logSuccess("Meal synced to backend", category: "Meal")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to sync meal")
        }
    }
}
```

### Step 5: Display Storage & Debug Info
Add to Settings view:

```swift
struct SettingsView: View {
    var body: some View {
        Form {
            Section("Storage Info") {
                let info = DeviceStorageManager.shared.getStorageInfo()
                HStack {
                    Text("Used")
                    Spacer()
                    Text(info.used)
                }
                HStack {
                    Text("Available")
                    Spacer()
                    Text(info.available)
                }
                ProgressView(value: info.percentage / 100)
            }
            
            Section("Debug") {
                Button("Export Logs") {
                    if let url = AppLogger.shared.exportLogs() {
                        // Share logs
                    }
                }
                Button("Clear Cache") {
                    UserDataCache.shared.clearAllCache()
                }
            }
        }
    }
}
```

---

## 📊 Storage Structure
```
Documents/
└── GoFitAppData/
    ├── user_profile.json
    ├── user_settings.json
    ├── workout_history.json
    ├── meal_history.json
    ├── daily_stats.json
    └── images/
        ├── profile_pic.jpg
        ├── meal_001.jpg
        └── meal_002.jpg

Logs/
└── app_2024-12-16.log
    app_2024-12-17.log
    app_2024-12-18.log
```

---

## 🔧 Configuration

### Adjust Cache Expiry
```swift
// In UserDataCache
private let cacheExpiryInterval: TimeInterval = 6 * 60 * 60 // 6 hours
```

### Adjust Max Stored Items
```swift
// Keep only last 100 workouts
if sessions.count > 100 {
    sessions = Array(sessions.prefix(100))
}

// Keep only last 500 meals
if meals.count > 500 {
    meals = Array(meals.prefix(500))
}
```

### Log Rotation Settings
```swift
private let maxLogFileSize: UInt64 = 10 * 1024 * 1024 // 10 MB
private let maxLogFiles = 5
```

---

## 🎯 Benefits

✅ **Offline-First**: All user data available without internet
✅ **Better UX**: Instant data loading from cache
✅ **Debugging**: Comprehensive logging for troubleshooting
✅ **Performance**: Reduced backend calls, faster app response
✅ **Sync-on-Demand**: Smart background syncing
✅ **Storage Management**: Automatic cleanup and quota tracking
✅ **User Insights**: Detailed statistics and analytics ready
✅ **Image Optimization**: Local image caching for workouts/meals

---

## 📝 Next Steps

1. Integrate logging into NetworkManager and AuthViewModel
2. Add cache checks in all data-fetching views
3. Implement background sync using BackgroundTasks framework
4. Add statistics dashboard using DailyStats and WeeklyStats
5. Create settings UI for storage management and log export
6. Monitor actual device storage usage in production
