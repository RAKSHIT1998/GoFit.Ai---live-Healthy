import SwiftUI

struct DailyLogHistoryView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var logStore = LocalDailyLogStore.shared
    @State private var selectedDate: Date = Date()
    @State private var logs: [DailyLog] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if logs.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: Design.Spacing.lg) {
                            // Date selector
                            dateSelectorView
                            
                            // Selected date summary
                            if let selectedLog = logStore.getLog(for: selectedDate) {
                                dailySummaryCard(log: selectedLog)
                                
                                // Meals section
                                if !selectedLog.meals.isEmpty {
                                    mealsSection(log: selectedLog)
                                }
                                
                                // Liquid intake section
                                if !selectedLog.liquidIntake.isEmpty {
                                    liquidIntakeSection(log: selectedLog)
                                }
                                
                                // Activity section
                                if selectedLog.caloriesBurned > 0 || selectedLog.steps != nil {
                                    activitySection(log: selectedLog)
                                }
                            } else {
                                noDataForDateView
                            }
                            
                            // Recent days summary
                            recentDaysSummary
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        .padding(.bottom, Design.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Daily Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadLogs()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .onAppear {
                loadLogs()
            }
        }
    }
    
    // MARK: - Date Selector
    
    private var dateSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Spacing.sm) {
                ForEach(getLast30Days(), id: \.self) { date in
                    DateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasData: logStore.getLog(for: date) != nil
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
        }
    }
    
    private func getLast30Days() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // MARK: - Daily Summary Card
    
    private func dailySummaryCard(log: DailyLog) -> some View {
        VStack(spacing: Design.Spacing.md) {
            HStack {
                Text(formatDate(log.date))
                    .font(Design.Typography.title2)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Design.Spacing.md) {
                NutritionStatCard(
                    title: "Calories",
                    value: "\(Int(log.totalCalories))",
                    unit: "kcal",
                    color: Design.Colors.calories
                )
                
                NutritionStatCard(
                    title: "Protein",
                    value: String(format: "%.1f", log.totalProtein),
                    unit: "g",
                    color: Design.Colors.protein
                )
                
                NutritionStatCard(
                    title: "Carbs",
                    value: String(format: "%.1f", log.totalCarbs),
                    unit: "g",
                    color: Design.Colors.carbs
                )
                
                NutritionStatCard(
                    title: "Fat",
                    value: String(format: "%.1f", log.totalFat),
                    unit: "g",
                    color: Design.Colors.fat
                )
                
                NutritionStatCard(
                    title: "Sugar",
                    value: String(format: "%.1f", log.totalSugar),
                    unit: "g",
                    color: Design.Colors.sugar
                )
                
                NutritionStatCard(
                    title: "Liquid",
                    value: String(format: "%.2f", log.totalLiquid),
                    unit: "L",
                    color: Design.Colors.water
                )
            }
            
            if log.caloriesBurned > 0 {
                HStack {
                    Text("Calories Burned")
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(log.caloriesBurned)) kcal")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
                .padding(.top, Design.Spacing.sm)
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Meals Section
    
    private func mealsSection(log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Meals")
                    .font(Design.Typography.title3)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(log.meals.count)")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(log.meals.sorted(by: { $0.timestamp > $1.timestamp })) { meal in
                MealCard(meal: meal)
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Liquid Intake Section
    
    private func liquidIntakeSection(log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Liquid Intake")
                    .font(Design.Typography.title3)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(log.liquidIntake.count) entries")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(log.liquidIntake.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                LiquidEntryCard(entry: entry)
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Activity Section
    
    private func activitySection(log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Activity")
                .font(Design.Typography.title3)
                .foregroundColor(.primary)
            
            if log.caloriesBurned > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Design.Colors.calories)
                    Text("Calories Burned")
                        .font(Design.Typography.body)
                    Spacer()
                    Text("\(Int(log.caloriesBurned)) kcal")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
            
            if let steps = log.steps {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(Design.Colors.steps)
                    Text("Steps")
                        .font(Design.Typography.body)
                    Spacer()
                    Text("\(steps)")
                        .font(Design.Typography.headline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Recent Days Summary
    
    private var recentDaysSummary: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Last 7 Days Average")
                .font(Design.Typography.title3)
                .foregroundColor(.primary)
            
            let avgCalories = logStore.getAverageCalories(days: 7)
            let avgSugar = logStore.getAverageSugar(days: 7)
            
            HStack(spacing: Design.Spacing.lg) {
                VStack(alignment: .leading) {
                    Text("Avg Calories")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(avgCalories))")
                        .font(Design.Typography.title2)
                        .foregroundColor(Design.Colors.calories)
                }
                
                VStack(alignment: .leading) {
                    Text("Avg Sugar")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f g", avgSugar))
                        .font(Design.Typography.title2)
                        .foregroundColor(Design.Colors.sugar)
                }
                
                Spacer()
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(Design.Colors.primary.opacity(0.5))
            
            Text("No Logs Yet")
                .font(Design.Typography.title2)
                .foregroundColor(.primary)
            
            Text("Start logging your meals and activities to see your daily history here")
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
        }
    }
    
    private var noDataForDateView: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No data for this date")
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
        }
        .padding(Design.Spacing.xl)
    }
    
    // MARK: - Helper Functions
    
    private func loadLogs() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            logs = logStore.getAllLogs()
            isLoading = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - Date Button

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let hasData: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayOfWeek)
                    .font(Design.Typography.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(dayNumber)
                    .font(Design.Typography.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 50, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Design.Colors.primary : Design.Colors.cardBackground)
            )
            .overlay(
                Circle()
                    .fill(hasData ? Design.Colors.primary : Color.clear)
                    .frame(width: 6, height: 6)
                    .offset(y: -20)
            )
        }
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: LoggedMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: meal.mealType.icon)
                    .foregroundColor(Design.Colors.primary)
                Text(meal.mealType.displayName)
                    .font(Design.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatTime(meal.timestamp))
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(meal.items) { item in
                HStack {
                    Text(item.name)
                        .font(Design.Typography.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(item.calories)) kcal")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(Design.Typography.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(meal.totalCalories)) kcal")
                    .font(Design.Typography.headline)
                    .foregroundColor(Design.Colors.primary)
            }
        }
        .padding(Design.Spacing.sm)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Liquid Entry Card

struct LiquidEntryCard: View {
    let entry: LiquidEntry
    
    var body: some View {
        HStack {
            Image(systemName: entry.beverageType.icon)
                .foregroundColor(Design.Colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.beverageName ?? entry.beverageType.displayName)
                    .font(Design.Typography.body)
                    .foregroundColor(.primary)
                
                Text(formatTime(entry.timestamp))
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f L", entry.amount))
                    .font(Design.Typography.headline)
                    .foregroundColor(Design.Colors.primary)
                
                if entry.calories > 0 {
                    Text("\(Int(entry.calories)) kcal")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Design.Spacing.sm)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Nutrition Stat Card

struct NutritionStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Design.Typography.title2)
                    .foregroundColor(color)
                Text(unit)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Spacing.sm)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
}
