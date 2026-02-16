import SwiftUI
import Combine

/// Example implementation showing how to use DeviceStorageManager, AppLogger, and UserDataCache
/// This demonstrates best practices for offline-first data management

struct ExampleStorageIntegrationView: View {
    @ObservedObject private var cache = UserDataCache.shared
    @State private var showingAddWorkout = false
    @State private var stats: DailyStats?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Storage Info Section
                storageInfoSection
                
                // Today's Stats
                if let stats = stats {
                    todayStatsSection(stats)
                }
                
                // Cached Data Status
                cacheStatusSection
                
                // Workouts List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(cache.workoutSessions.prefix(5)) { workout in
                            WorkoutCardView(workout: workout)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Offline Data Example")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddWorkout = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
                setupAndLoadData()
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
                    .onDisappear {
                        // Refresh stats after adding workout
                        stats = cache.calculateTodaysStats()
                    }
            }
        }
    }
    
    private var storageInfoSection: some View {
        let info = DeviceStorageManager.shared.getStorageInfo()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Storage Status")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Used Storage")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(info.used)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(info.available)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            ProgressView(value: info.percentage / 100)
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    private func todayStatsSection(_ stats: DailyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Stats")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(Int(stats.totalCaloriesConsumed))",
                    unit: "cal",
                    color: .orange
                )
                
                StatCard(
                    icon: "dumbbell.fill",
                    title: "Workouts",
                    value: "\(stats.workoutsCompleted)",
                    unit: "done",
                    color: .green
                )
                
                StatCard(
                    icon: "fork.knife",
                    title: "Meals",
                    value: "\(stats.mealsLogged)",
                    unit: "logged",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    private var cacheStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cache Status")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(cache.isSynced ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(cache.isSynced ? "Synced" : "Pending")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if let lastSync = cache.lastSyncTime {
                HStack {
                    Text("Last Sync")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formatDate(lastSync))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            HStack {
                Text("Cached Items")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(cache.workoutSessions.count) workouts • \(cache.mealEntries.count) meals")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                Button(action: refreshCache) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: clearCache) {
                    Label("Clear", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    private func setupAndLoadData() {
        // Initialize storage manager
        DeviceStorageManager.shared.initialize()
        
        // Log app activity
        AppLogger.shared.log("Opened storage integration example", level: .info, category: "Navigation")
        
        // Calculate and display stats
        stats = cache.calculateTodaysStats()
        
        // Log memory usage
        AppLogger.shared.logMemoryUsage()
    }
    
    private func refreshCache() {
        AppLogger.shared.logAction(action: "Manual cache refresh")
        
        // Simulate backend sync
        cache.markSynced()
        
        // Show success
        stats = cache.calculateTodaysStats()
        AppLogger.shared.logSuccess("Cache refreshed", category: "Storage")
    }
    
    private func clearCache() {
        let alertController = UIAlertController(
            title: "Clear Cache",
            message: "Are you sure you want to clear all cached data?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            cache.clearAllCache()
            stats = nil
            AppLogger.shared.logWarning("Cache cleared by user", category: "Storage")
        })
        
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController?
            .present(alertController, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// Example of adding a workout with logging
struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var cache = UserDataCache.shared
    
    @State private var workoutName = ""
    @State private var duration: TimeInterval = 3600
    @State private var caloriesBurned = 250
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Exercise Name", text: $workoutName)
                    
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("Duration", value: Binding(
                            get: { Int(duration / 60) },
                            set: { duration = TimeInterval($0 * 60) }
                        ), format: .number)
                        .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Calories Burned")
                        Spacer()
                        TextField("Calories", value: $caloriesBurned, format: .number)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Add Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(workoutName.isEmpty)
                }
            }
        }
    }
    
    private func saveWorkout() {
        // Create workout with sample exercise
        let exercise = ExerciseRecord(
            exerciseName: workoutName,
            sets: 3,
            reps: [10, 10, 8],
            weight: nil
        )
        
        let workout = WorkoutSession(
            name: workoutName,
            duration: duration,
            caloriesBurned: Double(caloriesBurned),
            exercises: [exercise],
            date: Date()
        )
        
        // Save to cache (immediate - offline-first)
        cache.addWorkoutSession(workout)
        AppLogger.shared.workout("Added workout: \(workoutName) - \(Int(duration / 60))min - \(caloriesBurned)cal")
        
        // In production, also sync to backend
        Task {
            do {
                // await syncToBackend(workout)
                cache.markSynced()
                AppLogger.shared.logSuccess("Workout synced", category: "Workout")
            } catch {
                AppLogger.shared.logError(error, context: "Failed to sync workout")
            }
        }
        
        dismiss()
    }
}

/// Example showing how to implement offline-first view
struct OfflineFirstExample: View {
    @ObservedObject private var cache = UserDataCache.shared
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            // Show cached data first
            List(cache.workoutSessions) { workout in
                WorkoutCardView(workout: workout)
            }
            .refreshable {
                await syncFromBackend()
            }
        }
        .onAppear {
            // Try to sync if cache is stale
            if cache.isCacheExpired() {
                Task {
                    await syncFromBackend()
                }
            }
        }
    }
    
    private func syncFromBackend() async {
        isRefreshing = true
        AppLogger.shared.logAction(action: "Syncing workouts from backend")
        
        do {
            // Simulate backend request
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // In production:
            // let workouts: [WorkoutSession] = try await NetworkManager.shared.request("workouts")
            // cache.updateWorkoutSessions(workouts)
            
            cache.markSynced()
            AppLogger.shared.logSuccess("Sync completed", category: "Storage")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.shared.logError(error, context: "Backend sync failed")
        }
        
        isRefreshing = false
    }
}

// MARK: - Preview
#Preview {
    ExampleStorageIntegrationView()
}
