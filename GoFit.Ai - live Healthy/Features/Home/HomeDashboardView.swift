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
                Design.Colors.background
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
            // Calories Display
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                    Text(todayCalories)
                        .font(Design.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
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
                guard AppConstants.defaultWaterGoal > 0,
                      waterIntake.isFinite,
                      !waterIntake.isNaN else {
                    return 0.0
                }
                return min(waterIntake / AppConstants.defaultWaterGoal, 1.0)
            }()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Colors.water)
                        .frame(width: geo.size.width * progress, height: 16)
                        .animation(Design.Animation.smooth, value: progress)
                }
            }
            .frame(height: 16)

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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
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
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
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

