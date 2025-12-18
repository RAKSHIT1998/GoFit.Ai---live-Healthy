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
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.systemGroupedBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
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

    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(Design.Typography.subheadline)
                    .foregroundColor(.secondary)

                Text(auth.name.isEmpty ? "User" : auth.name)
                    .font(Design.Typography.title)
            }

            Spacer()

            LogoView(size: .small, showText: false, color: Design.Colors.primary)
                .scaleEffect(animateCards ? 1 : 0.9)
        }
        .padding(.vertical, Design.Spacing.sm)
    }

    // MARK: - Main Stats
    private var mainStatsCard: some View {
        VStack(spacing: Design.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Calories", systemImage: "flame.fill")
                        .foregroundColor(Design.Colors.calories)

                    Text(todayCalories)
                        .font(Design.Typography.largeTitle)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Label("Fasting", systemImage: "timer")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)

                    Text(fastingStatus)
                        .font(Design.Typography.title2)
                }
            }

            Divider()

            HStack(spacing: Design.Spacing.md) {
                MacroPill(label: "Protein", value: todayProtein, color: Design.Colors.protein, icon: "p.circle.fill")
                MacroPill(label: "Carbs", value: todayCarbs, color: Design.Colors.carbs, icon: "c.circle.fill")
                MacroPill(label: "Fat", value: todayFat, color: Design.Colors.fat, icon: "f.circle.fill")
            }
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
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
                    showingScanner = true
                }

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
                    showingLiquidLog = true
                }

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
                    showingWorkout = true
                }
            }
        }
    }

    // MARK: - Health Metrics
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Today's Activity")
                .font(Design.Typography.headline)

            HStack(spacing: Design.Spacing.md) {
                HealthMetricCard(
                    icon: "figure.walk",
                    value: "\(healthKit.todaySteps)",
                    label: "Steps",
                    color: Design.Colors.steps,
                    unit: ""
                )

                HealthMetricCard(
                    icon: "flame.fill",
                    value: "\(Int(healthKit.todayActiveCalories))",
                    label: "Calories",
                    color: Design.Colors.calories,
                    unit: "kcal"
                )

                HealthMetricCard(
                    icon: "heart.fill",
                    value: healthKit.restingHeartRate > 0
                        ? "\(Int(healthKit.restingHeartRate))"
                        : "—",
                    label: "Heart Rate",
                    color: Design.Colors.heart,
                    unit: "bpm"
                )
            }
        }
    }

    // MARK: - Water Intake
    private var waterIntakeCard: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Label("Water Intake", systemImage: "drop.fill")
                    .foregroundColor(Design.Colors.water)

                Spacer()

                Text("\(String(format: "%.1f", waterIntake))L")
                    .font(Design.Typography.title2)
                    .foregroundColor(Design.Colors.water)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    let progress: CGFloat = {
                        guard AppConstants.defaultWaterGoal > 0,
                              waterIntake.isFinite,
                              !waterIntake.isNaN else {
                            return 0.0
                        }
                        let calculated = min(waterIntake / AppConstants.defaultWaterGoal, 1.0)
                        return calculated.isFinite && !calculated.isNaN ? calculated : 0.0
                    }()
                    
                    let barWidth: CGFloat = {
                        let width = geo.size.width * progress
                        return width.isFinite && !width.isNaN ? width : 0.0
                    }()

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Design.Colors.water, Design.Colors.water.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth, height: 12)
                }
            }
            .frame(height: 12)

            Text("Goal: \(String(format: "%.1f", AppConstants.defaultWaterGoal))L")
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }

    // MARK: - AI Recommendations
    private var aiRecommendationsCard: some View {
        Button {
            showingWorkout = true
        } label: {
            HStack(spacing: Design.Spacing.md) {
                Image(systemName: "sparkles")
                    .foregroundColor(.white)
                    .padding()
                    .background(Design.Colors.primaryGradient)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text("AI Recommendations")
                        .font(Design.Typography.headline)

                    Text("Personalized meals & workouts")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }

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

