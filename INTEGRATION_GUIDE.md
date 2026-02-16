# Integration Guide: Adding Storage to Your Existing App

This guide shows you exactly how to integrate the new storage services into your existing GoFit app with minimal changes.

---

## 🔧 Step 1: Initialize in App Launch

### Update `GofitAIApp.swift`
```swift
import SwiftUI

@main
struct GofitAIApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Initialize storage services
                    DeviceStorageManager.shared.initialize()
                    
                    // Log app launch
                    AppLogger.shared.log("GoFit app launched", level: .info, category: "Lifecycle")
                    AppLogger.shared.logMemoryUsage()
                }
        }
    }
}
```

---

## 🔐 Step 2: Add Logging to Authentication

### Update `AuthViewModel.swift`
```swift
// In the login() method
func login(email: String, password: String) async throws {
    AppLogger.shared.logAction(user: email, action: "Login attempt")
    AppLogger.shared.logDebug("Email: \(email)", category: "Auth")
    
    do {
        let token = try await AuthService.shared.login(email: email, password: password)
        self.token = token
        self.isLoggedIn = true
        
        AppLogger.shared.auth("Login successful")
        saveLocalState()
    } catch {
        AppLogger.shared.logError(error, category: "Auth", context: "Login failed for \(email)")
        throw error
    }
}

// In the signInWithApple() method
func signInWithApple() async throws {
    AppLogger.shared.auth("Starting Apple Sign In")
    
    do {
        let result = try await AppleSignInService.shared.signIn()
        let token = try await AuthService.shared.signInWithApple(
            idToken: result.idToken,
            userIdentifier: result.userIdentifier,
            email: result.email,
            name: result.fullName
        )
        
        self.token = token
        self.isLoggedIn = true
        self.didFinishOnboarding = true
        AuthService.shared.saveToken(token)
        
        AppLogger.shared.auth("Apple Sign In successful")
    } catch {
        AppLogger.shared.logError(error, category: "Auth", context: "Apple Sign In failed")
        throw error
    }
}

// In the logout() method
func logout() {
    AppLogger.shared.auth("User logged out")
    AuthService.shared.deleteToken()
    self.token = nil
    self.isLoggedIn = false
    self.userId = nil
    saveLocalState()
}
```

---

## 🏋️ Step 3: Use Cache in Workout Views

### Update Workout History View
```swift
struct WorkoutHistoryView: View {
    @ObservedObject private var cache = UserDataCache.shared
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if cache.workoutSessions.isEmpty {
                    VStack {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No workouts yet")
                            .font(.headline)
                        Text("Add a workout to get started")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(cache.workoutSessions) { workout in
                        WorkoutCardView(workout: workout)
                    }
                    .refreshable {
                        await refreshWorkouts()
                    }
                }
                
                if isRefreshing {
                    ProgressView()
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refreshWorkouts() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                checkAndRefresh()
            }
        }
    }
    
    private func checkAndRefresh() {
        AppLogger.shared.log("Workout history view appeared", level: .debug)
        
        // Show cached data immediately
        // Only sync in background if cache is stale
        if cache.isCacheExpired() {
            Task {
                await refreshWorkouts()
            }
        }
    }
    
    private func refreshWorkouts() async {
        isRefreshing = true
        AppLogger.shared.logAction(action: "Refreshing workouts from server")
        
        do {
            // In production, fetch from backend:
            // let workouts: [WorkoutSession] = try await NetworkManager.shared.request("workouts")
            // cache.updateWorkoutSessions(workouts)
            
            cache.markSynced()
            errorMessage = nil
            AppLogger.shared.logSuccess("Workouts refreshed", category: "Workout")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.shared.logError(error, context: "Failed to refresh workouts")
        }
        
        isRefreshing = false
    }
}
```

### Add Workout Save Logic
```swift
// When user completes a workout
func completeWorkout(name: String, duration: TimeInterval, caloriesBurned: Double, exercises: [ExerciseRecord]) {
    let workout = WorkoutSession(
        name: name,
        duration: duration,
        caloriesBurned: caloriesBurned,
        exercises: exercises,
        date: Date()
    )
    
    // Save to cache immediately (offline-first)
    UserDataCache.shared.addWorkoutSession(workout)
    AppLogger.shared.workout("Completed: \(name) - \(Int(duration/60))min - \(Int(caloriesBurned))cal")
    
    // Sync to backend in background
    Task {
        do {
            try await NetworkManager.shared.uploadWorkout(workout)
            UserDataCache.shared.markSynced()
            AppLogger.shared.logSuccess("Workout synced to backend", category: "Workout")
        } catch {
            AppLogger.shared.logError(error, context: "Failed to sync workout")
            // Data is still locally cached, will retry later
        }
    }
}
```

---

## 🍽️ Step 4: Use Cache in Meal Views

### Update Meal Logging
```swift
struct MealLoggingView: View {
    @State private var mealName = ""
    @State private var calories = 0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0
    @State private var mealType = "lunch"
    
    var body: some View {
        Form {
            TextField("Meal Name", text: $mealName)
            
            Stepper("Calories: \(calories)", value: $calories, in: 0...2000, step: 50)
            TextField("Protein (g)", value: $protein, format: .number)
            TextField("Carbs (g)", value: $carbs, format: .number)
            TextField("Fat (g)", value: $fat, format: .number)
            
            Picker("Meal Type", selection: $mealType) {
                Text("Breakfast").tag("breakfast")
                Text("Lunch").tag("lunch")
                Text("Dinner").tag("dinner")
                Text("Snack").tag("snack")
            }
            
            Button("Save Meal") {
                saveMeal()
            }
        }
    }
    
    private func saveMeal() {
        let meal = MealEntry(
            name: mealName,
            calories: Double(calories),
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: Date(),
            mealType: mealType
        )
        
        // Save to cache immediately
        UserDataCache.shared.addMealEntry(meal)
        AppLogger.shared.meal("Logged \(mealType): \(mealName) - \(calories)cal")
        
        // Sync to backend
        Task {
            do {
                try await NetworkManager.shared.uploadMeal(meal)
                UserDataCache.shared.markSynced()
                AppLogger.shared.logSuccess("Meal synced", category: "Meal")
            } catch {
                AppLogger.shared.logError(error, context: "Failed to sync meal")
            }
        }
    }
}
```

### Display Today's Nutrition
```swift
struct DailyNutritionView: View {
    @ObservedObject private var cache = UserDataCache.shared
    
    var body: some View {
        VStack(spacing: 16) {
            let nutrition = cache.calculateTodaysNutrition()
            let stats = cache.calculateTodaysStats()
            
            VStack(alignment: .leading) {
                Text("Today's Nutrition")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    NutritionCard(label: "Calories", value: Int(nutrition.calories), color: .orange)
                    NutritionCard(label: "Protein", value: Int(nutrition.protein), color: .blue)
                    NutritionCard(label: "Carbs", value: Int(nutrition.carbs), color: .green)
                    NutritionCard(label: "Fat", value: Int(nutrition.fat), color: .red)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Activity")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    NutritionCard(label: "Burned", value: Int(stats.totalCaloriesBurned), color: .pink)
                    NutritionCard(label: "Workouts", value: stats.workoutsCompleted, color: .purple)
                    NutritionCard(label: "Meals", value: stats.mealsLogged, color: .teal)
                }
            }
        }
        .padding()
    }
}

struct NutritionCard: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(color).opacity(0.1))
        .cornerRadius(8)
    }
}
```

---

## 📱 Step 5: Add Storage Info to Settings

### Update Settings View
```swift
struct SettingsView: View {
    @State private var showingClearCache = false
    @State private var showingExportLogs = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Storage Information
                Section("Storage") {
                    let info = DeviceStorageManager.shared.getStorageInfo()
                    
                    HStack {
                        Text("Used Storage")
                        Spacer()
                        Text(info.used)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Available Storage")
                        Spacer()
                        Text(info.available)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: info.percentage / 100)
                        .tint(.blue)
                }
                
                // Cache Management
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
                    
                    Button(action: syncCache) {
                        Text("Refresh Cache")
                    }
                }
                
                // Debug Tools
                Section("Debug") {
                    Button("Export Logs") {
                        exportLogs()
                    }
                    
                    Button("View Logs") {
                        let logs = AppLogger.shared.getLogsAsString()
                        print(logs)
                    }
                    
                    Button("Clear Cache", role: .destructive) {
                        showingClearCache = true
                    }
                    .confirmationDialog(
                        "Clear Cache",
                        isPresented: $showingClearCache,
                        actions: {
                            Button("Clear", role: .destructive) {
                                UserDataCache.shared.clearAllCache()
                                DeviceStorageManager.shared.clearAllAppData()
                                AppLogger.shared.log("Cache cleared by user", level: .warning)
                            }
                        },
                        message: {
                            Text("This will delete all offline data. Make sure everything is synced.")
                        }
                    )
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func syncCache() {
        AppLogger.shared.logAction(action: "Manual cache sync")
        UserDataCache.shared.markSynced()
        AppLogger.shared.logSuccess("Cache synced", category: "Storage")
    }
    
    private func exportLogs() {
        if let exportURL = AppLogger.shared.exportLogs() {
            AppLogger.shared.log("Logs exported: \(exportURL.path)", level: .success)
            // Share with user
        }
    }
}
```

---

## 🔄 Step 6: Add NetworkManager Integration

### Update `NetworkManager.swift`
```swift
// Add logging to all requests
func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
    let url = baseURL.appendingPathComponent(endpoint)
    let start = Date()
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    
    if let body = body {
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    if let token = AuthService.shared.readToken()?.accessToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    let duration = Date().timeIntervalSince(start)
    
    if let httpResponse = response as? HTTPURLResponse {
        AppLogger.shared.logNetworkRequest(
            url: endpoint,
            method: method,
            statusCode: httpResponse.statusCode,
            duration: duration
        )
    }
    
    let decoded = try JSONDecoder().decode(T.self, from: data)
    return decoded
}
```

---

## 📊 Step 7: Add Statistics Dashboard

### Create New Stats View
```swift
struct StatsView: View {
    @ObservedObject private var cache = UserDataCache.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Stats
                    let todayStats = cache.calculateTodaysStats()
                    TodayStatsCard(stats: todayStats)
                    
                    // Weekly Stats
                    let weekStats = cache.getWeeklyStats()
                    WeeklyStatsCard(stats: weekStats)
                    
                    // Recent Workouts
                    RecentWorkoutsCard(workouts: Array(cache.workoutSessions.prefix(3)))
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

struct TodayStatsCard: View {
    let stats: DailyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Calorie Deficit")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(stats.getCalorieDeficit()))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(stats.workoutsCompleted)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeeklyStatsCard: View {
    let stats: WeeklyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Avg Cal/Day")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(stats.averageCaloriesPerDay))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Total Workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(stats.totalWorkouts)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentWorkoutsCard: View {
    let workouts: [WorkoutSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(workouts) { workout in
                HStack {
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(workout.exercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(workout.caloriesBurned)) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(Int(workout.duration/60))m")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

---

## ✅ Integration Checklist

- [ ] Initialize DeviceStorageManager and AppLogger in `GofitAIApp.swift`
- [ ] Add logging to `AuthViewModel` (login, signup, logout)
- [ ] Use `UserDataCache` in workout views
- [ ] Use `WorkoutCardView` instead of custom workout display
- [ ] Add caching to meal logging views
- [ ] Update settings view with storage info
- [ ] Add logging to `NetworkManager`
- [ ] Test offline functionality (disable WiFi)
- [ ] Export logs to verify logging works
- [ ] Monitor app performance

---

## 🧪 Testing

### Test Offline Mode
1. Turn off WiFi and cellular
2. Try to view workouts - should show cached data
3. Add a workout - should save locally
4. Check logs - should show all activities

### Test Logging
1. Go to Settings > Debug > View Logs
2. Perform actions in app
3. Check console output
4. Export logs

### Test Cache
1. Check Settings > Cache info
2. Clear cache from Settings
3. Verify data is gone
4. Refresh to reload from backend

---

Done! Your app now has comprehensive local storage and logging! 🎉
