import SwiftUI

struct HomeDashboardView: View {

    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var purchases: PurchaseManager
    @StateObject private var healthKit = HealthKitService.shared

    @State private var showingScanner = false
    @State private var showingHistory = false
    @State private var showingFasting = false
    @State private var showingWorkout = false
    @State private var showingLiquidLog = false
    @State private var showingShareProgress = false

    @State private var todayCalories = "—"
    @State private var todayProtein = "—"
    @State private var todayCarbs = "—"
    @State private var todayFat = "—"
    @State private var todaySugar: Double = 0

    @State private var fastingStatus = "Not fasting"
    @State private var waterIntake: Double = 0
    @State private var liquidIntakeGoal: Double = AppConstants.defaultWaterGoal
    
    // AI-calculated target calories from onboarding
    @State private var targetCalories: Int? = nil

    @State private var isLoading = false
    @State private var animateCards = false

    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Design.Spacing.lg) {
                        welcomeHeader
                        mainStatsCard
                        quickActionsSection
                        healthMetricsSection
                        waterIntakeCard
                        sugarMeterCard
                        aiRecommendationsCard
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.bottom, Design.Spacing.xl)
                }
                .refreshable {
                    await loadLiquidIntakeGoal()
                    await loadSummary()
                    await loadWaterIntake()
                    await loadHealthData()
                    if healthKit.isAuthorized {
                        await healthKit.readTodayData()
                        try? await healthKit.syncToBackend()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingHistory = true } label: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Design.Colors.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingFasting = true } label: {
                            Label("Fasting", systemImage: "timer")
                        }
                        Button { showingShareProgress = true } label: {
                            Label("Share Progress", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                MealScannerView3().environmentObject(auth)
            }
            .sheet(isPresented: $showingHistory) {
                MealHistoryView().environmentObject(auth)
            }
            .sheet(isPresented: $showingFasting) {
                FastingView()
            }
            .sheet(isPresented: $showingWorkout) {
                WorkoutSuggestionsView().environmentObject(auth)
            }
            .sheet(isPresented: $showingLiquidLog) {
                LiquidLogView()
                    .environmentObject(auth)
                    .onDisappear {
                        // Reload water intake when sheet dismisses
                        Task {
                            await loadWaterIntake()
                        }
                    }
            }
            .sheet(isPresented: $showingShareProgress) {
                ShareProgressView(
                    calories: todayCalories,
                    steps: healthKit.todaySteps,
                    activeCalories: healthKit.todayActiveCalories,
                    waterIntake: waterIntake,
                    heartRate: healthKit.restingHeartRate > 0 ? healthKit.restingHeartRate : nil
                )
                .environmentObject(auth)
            }
            .onAppear {
                withAnimation(Design.Animation.spring) {
                    animateCards = true
                }

                Task {
                    await loadTargetCalories() // Load AI-calculated target calories
                    await loadLiquidIntakeGoal() // Load custom liquid intake goal
                    await loadSummary()
                    await loadWaterIntake()
                    await loadHealthData() // Load from backend first
                    await syncHealthData() // Then sync with HealthKit
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealSaved"))) { _ in
                // Reload immediately from local cache (instant update)
                Task {
                    let localTotals = LocalMealCache.shared.getTodayTotals()
                    await MainActor.run {
                        todayCalories = "\(Int(localTotals.calories))"
                        todayProtein = "\(Int(localTotals.protein))g"
                        todayCarbs = "\(Int(localTotals.carbs))g"
                        todayFat = "\(Int(localTotals.fat))g"
                        todaySugar = localTotals.sugar
                    }
                    // Then sync with backend in background
                    await loadSummary()
                }
            }
        }
    }

    // MARK: - Welcome Header (Clean White Design)
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(Design.Typography.subheadline)
                    .foregroundColor(.secondary)

                Text(auth.name.isEmpty ? "User" : auth.name)
                    .font(Design.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, Design.Spacing.sm)
    }

    // MARK: - Main Stats (Clean White Design)
    private var mainStatsCard: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Header with Share Button
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Calories")
                            .font(Design.Typography.subheadline)
                            .foregroundColor(.secondary)
                        
                        // AI badge to show this is AI-calculated
                        if targetCalories != nil {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundColor(Design.Colors.primary)
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(todayCalories)
                            .font(Design.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Show target calories if available
                        if let target = targetCalories {
                            Text("/ \(target)")
                                .font(Design.Typography.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Progress bar for calories
                    if let target = targetCalories, target > 0, todayCalories != "—", let current = Int(todayCalories) {
                        let progress = min(Double(current) / Double(target), 1.0)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(progress >= 1.0 ? Design.Colors.sugar : Design.Colors.primary)
                                    .frame(width: geo.size.width * min(progress, 1.0), height: 8)
                                    .animation(Design.Animation.smooth, value: progress)
                            }
                        }
                        .frame(height: 8)
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Share Button
                Button {
                    showingShareProgress = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(Design.Colors.primary)
                }
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Burned")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(healthKit.todayActiveCalories))")
                        .font(Design.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(Design.Colors.steps)
                }
            }
            
            Divider()
            
            // Macros
            HStack(spacing: Design.Spacing.md) {
                VStack(spacing: 4) {
                    Text(todayProtein)
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Design.Colors.protein)
                    Text("Protein")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(todayCarbs)
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Design.Colors.carbs)
                    Text("Carbs")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(todayFat)
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Design.Colors.fat)
                    Text("Fat")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Design.Spacing.lg)
        .background(Design.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.06), radius: 10, x: 0, y: 2)
    }
    

    // MARK: - Quick Actions (Clean White Design)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Quick Actions")
                .font(Design.Typography.headline)
                .foregroundColor(.primary)

            HStack(spacing: Design.Spacing.md) {
                // Scan Meal Button - Opens Camera
                Button {
                    showingScanner = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Design.Colors.primary)
                            .clipShape(Circle())
                        
                        Text("Scan Meal")
                            .font(Design.Typography.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.md)
                    .background(Design.Colors.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                Button {
                    showingLiquidLog = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Design.Colors.water)
                            .clipShape(Circle())
                        
                        Text("Liquid")
                            .font(Design.Typography.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.md)
                    .background(Design.Colors.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                Button {
                    showingWorkout = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Design.Colors.steps)
                            .clipShape(Circle())
                        
                        Text("Workout")
                            .font(Design.Typography.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.md)
                    .background(Design.Colors.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: - Health Metrics (Clean White Design)
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Today's Activity")
                .font(Design.Typography.headline)
                .foregroundColor(.primary)

            HStack(spacing: Design.Spacing.md) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(Design.Colors.steps)
                        .frame(width: 50, height: 50)
                        .background(Design.Colors.steps.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("\(healthKit.todaySteps)")
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                    
                    Text("Steps")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Design.Spacing.md)
                .background(Design.Colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)

                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(Design.Colors.calories)
                        .frame(width: 50, height: 50)
                        .background(Design.Colors.calories.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("\(Int(healthKit.todayActiveCalories))")
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                    
                    Text("Calories")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Design.Spacing.md)
                .background(Design.Colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)

                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(Design.Colors.heart)
                        .frame(width: 50, height: 50)
                        .background(Design.Colors.heart.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(healthKit.restingHeartRate > 0 ? "\(Int(healthKit.restingHeartRate))" : "—")
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                    
                    Text("Heart Rate")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Design.Spacing.md)
                .background(Design.Colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
    }

    // MARK: - Water Intake (Clean White Design)
    private var waterIntakeCard: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Label("Water Intake", systemImage: "drop.fill")
                    .foregroundColor(Design.Colors.water)
                    .font(Design.Typography.headline)

                Spacer()

                Text("\(String(format: "%.1f", waterIntake))L")
                    .font(Design.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Design.Colors.water)
            }

            let progress: Double = {
                guard liquidIntakeGoal > 0,
                      waterIntake.isFinite,
                      !waterIntake.isNaN else {
                    return 0.0
                }
                return min(waterIntake / liquidIntakeGoal, 1.0)
            }()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Colors.secondaryBackground)
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Colors.water)
                        .frame(width: geo.size.width * progress, height: 16)
                        .animation(Design.Animation.smooth, value: progress)
                }
            }
            .frame(height: 16)

            HStack {
                Text("Goal: \(String(format: "%.1f", liquidIntakeGoal))L")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(Design.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Design.Colors.water)
            }
        }
        .padding(Design.Spacing.lg)
        .background(Design.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.06), radius: 10, x: 0, y: 2)
    }

    // MARK: - Sugar Meter Card
    private var sugarMeterCard: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Label("Sugar Intake", systemImage: "chart.bar.fill")
                    .foregroundColor(Design.Colors.sugar)
                    .font(Design.Typography.headline)

                Spacer()

                Text("\(String(format: "%.1f", todaySugar))g")
                    .font(Design.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Design.Colors.sugar)
            }

            let progress: Double = {
                guard AppConstants.defaultSugarGoal > 0,
                      todaySugar.isFinite,
                      !todaySugar.isNaN else {
                    return 0.0
                }
                return min(todaySugar / AppConstants.defaultSugarGoal, 1.0)
            }()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Colors.sugar)
                        .frame(width: geo.size.width * progress, height: 16)
                        .animation(Design.Animation.smooth, value: progress)
                }
            }
            .frame(height: 16)

            HStack {
                Text("Goal: \(String(format: "%.0f", AppConstants.defaultSugarGoal))g")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(Design.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Design.Colors.sugar)
            }
        }
        .padding(Design.Spacing.lg)
        .background(Design.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.06), radius: 10, x: 0, y: 2)
    }

    // MARK: - AI Recommendations (Clean White Design)
    private var aiRecommendationsCard: some View {
        Button {
            showingWorkout = true
        } label: {
            HStack(spacing: Design.Spacing.md) {
                Image(systemName: "sparkles")
                    .foregroundColor(.white)
                    .font(.title3)
                    .frame(width: 50, height: 50)
                    .background(Design.Colors.primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Recommendations")
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)

                    Text("Personalized meals & workouts")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(Design.Spacing.lg)
            .background(Design.Colors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.primary.opacity(0.06), radius: 10, x: 0, y: 2)
        }
    }

    // MARK: - Data
    
    // Load AI-calculated target calories from user profile
    private func loadTargetCalories() async {
        guard auth.isLoggedIn else {
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            return
        }
        
        do {
            struct UserProfile: Codable {
                let id: String
                let name: String
                let email: String
                let metrics: Metrics?
            }
            
            struct Metrics: Codable {
                let targetCalories: Int?
            }
            
            let profile: UserProfile = try await NetworkManager.shared.request(
                "auth/me",
                method: "GET",
                body: nil
            )
            
            await MainActor.run {
                targetCalories = profile.metrics?.targetCalories
                if let target = targetCalories {
                    print("✅ Loaded AI-calculated target calories: \(target) kcal")
                } else {
                    print("⚠️ No target calories found in user profile")
                }
            }
        } catch {
            print("⚠️ Failed to load target calories: \(error.localizedDescription)")
        }
    }
    
    private func loadSummary() async {
        // Check if user is logged in
        guard auth.isLoggedIn else {
            print("⚠️ Cannot load summary: User not logged in")
            return
        }
        
        // FIRST: Load from local cache immediately for instant UI
        let localTotals = LocalMealCache.shared.getTodayTotals()
        await MainActor.run {
            todayCalories = "\(Int(localTotals.calories))"
            todayProtein = "\(Int(localTotals.protein))g"
            todayCarbs = "\(Int(localTotals.carbs))g"
            todayFat = "\(Int(localTotals.fat))g"
            todaySugar = localTotals.sugar
        }
        print("✅ Loaded from local cache: \(Int(localTotals.calories)) kcal")
        
        // THEN: Sync with backend in background (non-blocking)
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            print("⚠️ No valid token, using local cache only")
            return
        }
        
        isLoading = true
        defer { isLoading = false }

        do {
            struct Summary: Codable {
                let calories: Double
                let protein: Double
                let carbs: Double
                let fat: Double
                let sugar: Double?
            }

            // Force fresh fetch by adding timestamp to prevent caching
            let endpoint = "meals/summary/today?t=\(Date().timeIntervalSince1970)"
            let summary: Summary =
                try await NetworkManager.shared.request(
                    endpoint,
                    method: "GET",
                    body: nil
                )

            // Validate and sanitize values to prevent NaN
            let calories = summary.calories.isFinite && !summary.calories.isNaN ? summary.calories : 0
            let protein = summary.protein.isFinite && !summary.protein.isNaN ? summary.protein : 0
            let carbs = summary.carbs.isFinite && !summary.carbs.isNaN ? summary.carbs : 0
            let fat = summary.fat.isFinite && !summary.fat.isNaN ? summary.fat : 0
            let sugar = (summary.sugar ?? 0).isFinite && !(summary.sugar ?? 0).isNaN ? (summary.sugar ?? 0) : 0

            // Update UI with backend data (may be more accurate)
            await MainActor.run {
                todayCalories = "\(Int(calories))"
                todayProtein = "\(Int(protein))g"
                todayCarbs = "\(Int(carbs))g"
                todayFat = "\(Int(fat))g"
                todaySugar = sugar
            }
            print("✅ Synced with backend: \(Int(calories)) kcal")
        } catch {
            print("⚠️ Backend sync failed, using local cache: \(error.localizedDescription)")
            // Keep local cache values - don't clear them
            // Only log out on actual 401 (unauthorized) errors
            if let nsError = error as NSError?,
               nsError.code == 401 {
                print("❌ Unauthorized (401) - token expired or invalid. Logging out.")
                await MainActor.run {
                    auth.logout()
                }
            }
        }

        do {
            struct Fasting: Codable {
                let status: String
                let remainingHours: Double?
            }

            let fasting: Fasting =
                try await NetworkManager.shared.request(
                    "fasting/current",
                    method: "GET",
                    body: nil
                )

            if fasting.status == "fasting",
               let remaining = fasting.remainingHours,
               remaining.isFinite && !remaining.isNaN {

                let h = Int(remaining)
                let minutes = (remaining - Double(h)) * 60
                let m = minutes.isFinite && !minutes.isNaN ? Int(minutes) : 0
                fastingStatus = "\(h)h \(m)m"
            } else {
                fastingStatus = "Not fasting"
            }
        } catch {
            fastingStatus = "Not fasting"
        }
    }
    
    // Load liquid intake goal from backend
    private func loadLiquidIntakeGoal() async {
        guard auth.isLoggedIn else {
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            return
        }
        
        do {
            let response: [String: Any] = try await NetworkManager.shared.requestDictionary("auth/me", method: "GET", body: nil)
            if let metrics = response["metrics"] as? [String: Any],
               let liquid = metrics["liquidIntakeGoal"] as? Double {
                await MainActor.run {
                    liquidIntakeGoal = liquid
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to load liquid intake goal: \(error.localizedDescription)")
            #endif
        }
    }
    
    // Load water intake from backend
    private func loadWaterIntake() async {
        guard auth.isLoggedIn else {
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            return
        }
        
        do {
            struct HealthSummary: Codable {
                let today: TodayData
            }
            
            struct TodayData: Codable {
                let water: Double?
            }
            
            // Force fresh fetch by adding timestamp to prevent caching
            let endpoint = "health/summary?t=\(Date().timeIntervalSince1970)"
            let summary: HealthSummary = try await NetworkManager.shared.request(
                endpoint,
                method: "GET",
                body: nil
            )
            
            await MainActor.run {
                waterIntake = summary.today.water ?? 0
            }
        } catch {
            print("⚠️ Failed to load water intake: \(error.localizedDescription)")
        }
    }
    
    // Load health data from backend (steps, calories)
    private func loadHealthData() async {
        guard auth.isLoggedIn else {
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            return
        }
        
        do {
            struct HealthSummary: Codable {
                let today: TodayData
            }
            
            struct TodayData: Codable {
                let steps: Int?
                let activeCalories: Double?
            }
            
            // Force fresh fetch by adding timestamp to prevent caching
            let endpoint = "health/summary?t=\(Date().timeIntervalSince1970)"
            let summary: HealthSummary = try await NetworkManager.shared.request(
                endpoint,
                method: "GET",
                body: nil
            )
            
            await MainActor.run {
                // Update HealthKit service with backend data
                if let steps = summary.today.steps {
                    healthKit.todaySteps = steps
                }
                if let calories = summary.today.activeCalories {
                    healthKit.todayActiveCalories = calories
                }
            }
        } catch {
            print("⚠️ Failed to load health data: \(error.localizedDescription)")
        }
    }

    private func syncHealthData() async {
        // Use HealthKitService for syncing
        healthKit.checkAuthorizationStatus()
        
        if !healthKit.isAuthorized {
            do {
                print("🔵 Requesting HealthKit authorization...")
                try await healthKit.requestAuthorization()
            } catch {
                print("⚠️ HealthKit authorization failed: \(error.localizedDescription)")
                return
            }
        }
        
        guard healthKit.isAuthorized else {
            return
        }
        
        await healthKit.readTodayData()
        try? await healthKit.syncToBackend()
        print("✅ HealthKit data synced")
    }

    private func addWater() {
        Task {
            struct WaterReq: Codable { let amount: Double }
            let body = try? JSONEncoder().encode(WaterReq(amount: 0.25))

            do {
                let _: EmptyResponse = try await NetworkManager.shared.request(
                    "health/water",
                    method: "POST",
                    body: body
                )
                
                // Reload water intake after adding
                await loadWaterIntake()
            } catch {
                print("⚠️ Failed to add water: \(error.localizedDescription)")
            }
        }
    }
}

