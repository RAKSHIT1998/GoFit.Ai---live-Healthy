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

    @State private var todayCalories = "—"
    @State private var todayProtein = "—"
    @State private var todayCarbs = "—"
    @State private var todayFat = "—"

    @State private var fastingStatus = "Not fasting"
    @State private var waterIntake: Double = 0

    @State private var isLoading = false
    @State private var animateCards = false

    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Design.Spacing.lg) {
                        welcomeHeader
                        mainStatsCard
                        quickActionsSection
                        healthMetricsSection
                        waterIntakeCard
                        aiRecommendationsCard
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.bottom, Design.Spacing.xl)
                }
                .refreshable {
                    await loadSummary()
                    await syncHealthData()
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
                LiquidLogView().environmentObject(auth)
            }
            .onAppear {
                withAnimation(Design.Animation.spring) {
                    animateCards = true
                }

                Task {
                    await loadSummary()
                    await syncHealthData()
                }
            }
        }
    }

    // MARK: - Welcome Header (2025 Style)
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back,")
                    .font(Design.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(animateCards ? 1 : 0)
                    .offset(x: animateCards ? 0 : -20)
                    .animation(Design.Animation.spring.delay(0.1), value: animateCards)

                Text(auth.name.isEmpty ? "User" : auth.name)
                    .font(Design.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(Design.Colors.primary)
                    .opacity(animateCards ? 1 : 0)
                    .offset(x: animateCards ? 0 : -20)
                    .animation(Design.Animation.spring.delay(0.2), value: animateCards)
            }

            Spacer()

            LogoView(size: .small, showText: false, color: Design.Colors.primary)
                .scaleEffect(animateCards ? 1 : 0.7)
                .opacity(animateCards ? 1 : 0)
                .rotationEffect(.degrees(animateCards ? 0 : -10))
                .animation(Design.Animation.bouncy.delay(0.3), value: animateCards)
        }
        .padding(.vertical, Design.Spacing.sm)
    }

    // MARK: - Main Stats with Circular Progress (2025 Style)
    private var mainStatsCard: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Calories Circular Progress (Large, Prominent)
            HStack(spacing: Design.Spacing.xl) {
                CircularProgressView(
                    progress: calculateCalorieProgress(),
                    size: 140,
                    color: Design.Colors.primary,
                    showPercentage: false,
                    value: todayCalories,
                    label: "kcal left"
                )
                .scaleEffect(animateCards ? 1 : 0.8)
                .animation(Design.Animation.spring.delay(0.1), value: animateCards)
                
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Consumed")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(todayCalories)
                            .font(Design.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Design.Colors.calories)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Burned")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(healthKit.todayActiveCalories))")
                            .font(Design.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Design.Colors.steps)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .opacity(0.3)
            
            // Macro Circles (2025 Style)
            HStack(spacing: Design.Spacing.lg) {
                if let proteinValue = Double(todayProtein.replacingOccurrences(of: "—", with: "0")),
                   let proteinGoal = getProteinGoal() {
                    MacroCircleView(
                        progress: min(proteinValue / proteinGoal, 1.0),
                        color: Design.Colors.protein,
                        label: "Protein",
                        value: todayProtein,
                        total: "\(Int(proteinGoal))g"
                    )
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .animation(Design.Animation.spring.delay(0.2), value: animateCards)
                }
                
                if let carbsValue = Double(todayCarbs.replacingOccurrences(of: "—", with: "0")),
                   let carbsGoal = getCarbsGoal() {
                    MacroCircleView(
                        progress: min(carbsValue / carbsGoal, 1.0),
                        color: Design.Colors.carbs,
                        label: "Carbs",
                        value: todayCarbs,
                        total: "\(Int(carbsGoal))g"
                    )
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .animation(Design.Animation.spring.delay(0.3), value: animateCards)
                }
                
                if let fatValue = Double(todayFat.replacingOccurrences(of: "—", with: "0")),
                   let fatGoal = getFatGoal() {
                    MacroCircleView(
                        progress: min(fatValue / fatGoal, 1.0),
                        color: Design.Colors.fat,
                        label: "Fat",
                        value: todayFat,
                        total: "\(Int(fatGoal))g"
                    )
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .animation(Design.Animation.spring.delay(0.4), value: animateCards)
                }
            }
        }
        .padding(Design.Spacing.lg)
        .cardStyle(useGlass: true)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 30)
        .animation(Design.Animation.spring, value: animateCards)
    }
    
    private func calculateCalorieProgress() -> Double {
        guard let consumed = Double(todayCalories.replacingOccurrences(of: "—", with: "0")),
              consumed > 0 else { return 0 }
        let goal = 2000.0 // Default goal, can be made dynamic
        let remaining = max(0, goal - consumed)
        return remaining / goal
    }
    
    private func getProteinGoal() -> Double? {
        // Calculate based on user weight or default
        return 150.0 // Default, can be made dynamic
    }
    
    private func getCarbsGoal() -> Double? {
        return 250.0 // Default
    }
    
    private func getFatGoal() -> Double? {
        return 65.0 // Default
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Quick Actions")
                .font(Design.Typography.headline)

            HStack(spacing: Design.Spacing.md) {
                QuickActionButton(
                    icon: "camera.fill",
                    label: "Scan Meal",
                    color: Design.Colors.primary,
                    gradient: Design.Colors.primaryGradient
                ) {
                    HapticManager.impact(style: .medium)
                    showingScanner = true
                }
                .scaleEffect(animateCards ? 1 : 0.9)
                .animation(Design.Animation.spring.delay(0.1), value: animateCards)

                QuickActionButton(
                    icon: "drop.fill",
                    label: "Liquid",
                    color: Design.Colors.water,
                    gradient: LinearGradient(
                        colors: [Design.Colors.water, Design.Colors.water.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    HapticManager.impact(style: .light)
                    showingLiquidLog = true
                }
                .scaleEffect(animateCards ? 1 : 0.9)
                .animation(Design.Animation.spring.delay(0.2), value: animateCards)

                QuickActionButton(
                    icon: "figure.walk",
                    label: "Workout",
                    color: Design.Colors.steps,
                    gradient: LinearGradient(
                        colors: [Design.Colors.steps, Design.Colors.steps.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    HapticManager.impact(style: .light)
                    showingWorkout = true
                }
                .scaleEffect(animateCards ? 1 : 0.9)
                .animation(Design.Animation.spring.delay(0.3), value: animateCards)
            }
        }
    }

    // MARK: - Health Metrics (2025 Style)
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Today's Activity")
                .font(Design.Typography.headline)
                .opacity(animateCards ? 1 : 0)
                .offset(x: animateCards ? 0 : -20)
                .animation(Design.Animation.spring.delay(0.4), value: animateCards)

            HStack(spacing: Design.Spacing.md) {
                HealthMetricCard(
                    icon: "figure.walk",
                    value: "\(healthKit.todaySteps)",
                    label: "Steps",
                    color: Design.Colors.steps,
                    unit: ""
                )
                .scaleEffect(animateCards ? 1 : 0.8)
                .opacity(animateCards ? 1 : 0)
                .animation(Design.Animation.spring.delay(0.5), value: animateCards)

                HealthMetricCard(
                    icon: "flame.fill",
                    value: "\(Int(healthKit.todayActiveCalories))",
                    label: "Calories",
                    color: Design.Colors.calories,
                    unit: "kcal"
                )
                .scaleEffect(animateCards ? 1 : 0.8)
                .opacity(animateCards ? 1 : 0)
                .animation(Design.Animation.spring.delay(0.6), value: animateCards)

                HealthMetricCard(
                    icon: "heart.fill",
                    value: healthKit.restingHeartRate > 0
                        ? "\(Int(healthKit.restingHeartRate))"
                        : "—",
                    label: "Heart Rate",
                    color: Design.Colors.heart,
                    unit: "bpm"
                )
                .scaleEffect(animateCards ? 1 : 0.8)
                .opacity(animateCards ? 1 : 0)
                .animation(Design.Animation.spring.delay(0.7), value: animateCards)
            }
        }
    }

    // MARK: - Water Intake (2025 Style)
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
                guard AppConstants.defaultWaterGoal > 0,
                      waterIntake.isFinite,
                      !waterIntake.isNaN else {
                    return 0.0
                }
                return min(waterIntake / AppConstants.defaultWaterGoal, 1.0)
            }()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 20)
                    
                    // Animated progress bar
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Design.Colors.water,
                                    Design.Colors.water.opacity(0.8),
                                    Design.Colors.water.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 20)
                        .animation(Design.Animation.smooth, value: progress)
                }
            }
            .frame(height: 20)

            HStack {
                Text("Goal: \(String(format: "%.1f", AppConstants.defaultWaterGoal))L")
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
        .cardStyle(useGlass: true)
        .scaleEffect(animateCards ? 1 : 0.95)
        .opacity(animateCards ? 1 : 0)
        .animation(Design.Animation.spring.delay(0.5), value: animateCards)
    }

    // MARK: - AI Recommendations (2025 Style)
    private var aiRecommendationsCard: some View {
        Button {
            HapticManager.impact(style: .medium)
            showingWorkout = true
        } label: {
            HStack(spacing: Design.Spacing.md) {
                ZStack {
                    // Animated glow
                    Circle()
                        .fill(Design.Colors.primaryGradient)
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                        .opacity(0.5)
                    
                    // Main icon circle
                    Circle()
                        .fill(Design.Colors.primaryGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: Design.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

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
            .cardStyle(useGlass: true)
            .scaleEffect(animateCards ? 1 : 0.95)
            .opacity(animateCards ? 1 : 0)
            .animation(Design.Animation.spring.delay(0.6), value: animateCards)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Design.Colors.primary)
            }
            .padding(Design.Spacing.lg)
            .cardStyle(backgroundColor: Design.Colors.primary.opacity(0.1))
        }
    }

    // MARK: - Data
    private func loadSummary() async {
        isLoading = true
        defer { isLoading = false }

        do {
            struct Summary: Codable {
                let calories: Double
                let protein: Double
                let carbs: Double
                let fat: Double
            }

            let summary: Summary =
                try await NetworkManager.shared.request(
                    "meals/summary/today",
                    method: "GET",
                    body: nil
                )

            // Validate and sanitize values to prevent NaN
            let calories = summary.calories.isFinite && !summary.calories.isNaN ? summary.calories : 0
            let protein = summary.protein.isFinite && !summary.protein.isNaN ? summary.protein : 0
            let carbs = summary.carbs.isFinite && !summary.carbs.isNaN ? summary.carbs : 0
            let fat = summary.fat.isFinite && !summary.fat.isNaN ? summary.fat : 0

            todayCalories = "\(Int(calories))"
            todayProtein = "\(Int(protein))g"
            todayCarbs = "\(Int(carbs))g"
            todayFat = "\(Int(fat))g"
        } catch {
            print("Summary error:", error)
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

    private func syncHealthData() async {
        guard healthKit.isAuthorized else { return }

        try? await healthKit.readTodaySteps()
        try? await healthKit.readTodayActiveCalories()
        try? await healthKit.readHeartRate()
        try? await healthKit.syncToBackend()
    }

    private func addWater() {
        withAnimation {
            let newValue = waterIntake + 0.25
            waterIntake = newValue.isFinite && !newValue.isNaN ? newValue : waterIntake
        }

        Task {
            struct WaterReq: Codable { let amount: Double }
            let body = try? JSONEncoder().encode(WaterReq(amount: 0.25))

            let _: EmptyResponse =
                try await NetworkManager.shared.request(
                    "health/water",
                    method: "POST",
                    body: body
                )
        }
    }
}

