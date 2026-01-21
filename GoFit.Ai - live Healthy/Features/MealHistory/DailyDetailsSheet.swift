import SwiftUI

/// Sheet that shows detailed daily information when a date is selected
struct DailyDetailsSheet: View {
    let date: Date
    @Binding var isPresented: Bool
    @StateObject private var logStore = LocalDailyLogStore.shared
    
    private var dailyLog: DailyLog? {
        logStore.getLog(for: date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                if let log = dailyLog {
                    ScrollView {
                        VStack(spacing: Design.Spacing.lg) {
                            // Date header
                            dateHeader
                            
                            // Summary cards
                            summarySection(log: log)
                            
                            // Meals section
                            if !log.meals.isEmpty {
                                mealsSection(log: log)
                            }
                            
                            // Liquid intake section
                            if !log.liquidIntake.isEmpty {
                                liquidSection(log: log)
                            }
                            
                            // Activity section
                            if log.caloriesBurned > 0 || log.steps != nil {
                                activitySection(log: log)
                            }
                        }
                        .padding(Design.Spacing.md)
                    }
                } else {
                    noDataView
                }
            }
            .navigationTitle("Daily Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Date Header
    private var dateHeader: some View {
        VStack(spacing: Design.Spacing.sm) {
            Text(formatDate(date))
                .font(Design.Typography.title)
                .foregroundColor(.primary)
            
            if calendar.isDateInToday(date) {
                Text("Today")
                    .font(Design.Typography.caption)
                    .foregroundColor(Design.Colors.primary)
                    .padding(.horizontal, Design.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.md)
    }
    
    // MARK: - Summary Section
    private func summarySection(log: DailyLog) -> some View {
        VStack(spacing: Design.Spacing.md) {
            Text("Daily Summary")
                .font(Design.Typography.title3)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Design.Spacing.md) {
                // Calories
                SummaryCard(
                    title: "Calories",
                    value: "\(Int(log.totalCalories))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: Design.Colors.calories
                )
                
                // Sugar
                SummaryCard(
                    title: "Sugar",
                    value: String(format: "%.1f", log.totalSugar),
                    unit: "g",
                    icon: "cube.fill",
                    color: Design.Colors.sugar
                )
                
                // Water
                SummaryCard(
                    title: "Water",
                    value: String(format: "%.2f", log.totalLiquid),
                    unit: "L",
                    icon: "drop.fill",
                    color: Design.Colors.water
                )
                
                // Protein
                SummaryCard(
                    title: "Protein",
                    value: String(format: "%.1f", log.totalProtein),
                    unit: "g",
                    icon: "leaf.fill",
                    color: Design.Colors.protein
                )
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Meals Section
    private func mealsSection(log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Meals Logged")
                    .font(Design.Typography.title3)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(log.meals.count)")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(log.meals.sorted(by: { $0.timestamp > $1.timestamp })) { meal in
                MealDetailCard(meal: meal)
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Liquid Section
    private func liquidSection(log: DailyLog) -> some View {
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
                LiquidDetailCard(entry: entry)
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
    
    // MARK: - No Data View
    private var noDataView: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: Design.Scale.value(60, textStyle: .title1)))
                .foregroundColor(Design.Colors.primary.opacity(0.5))
            
            Text("No Data for This Date")
                .font(Design.Typography.title2)
                .foregroundColor(.primary)
            
            Text("Start logging meals and activities to see your daily history")
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    private let calendar = Calendar.current
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(title)
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Design.Typography.title2)
                    .foregroundColor(color)
                Text(unit)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Spacing.md)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
}

// MARK: - Meal Detail Card
struct MealDetailCard: View {
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
            
            Divider()
            
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
        .padding(Design.Spacing.md)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Liquid Detail Card
struct LiquidDetailCard: View {
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
                
                if entry.sugar > 0 {
                    Text(String(format: "%.1f g sugar", entry.sugar))
                        .font(Design.Typography.caption)
                        .foregroundColor(Design.Colors.sugar)
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
