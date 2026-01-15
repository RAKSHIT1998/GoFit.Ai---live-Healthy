import SwiftUI

struct MealHistoryView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var logStore = LocalDailyLogStore.shared
    @State private var selectedDate: Date = Date() // Default to current day
    @State private var showingDailyDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scrollable calendar bar at top
                    ScrollableCalendarBar(selectedDate: $selectedDate) {
                        // Callback when date is selected - opens sheet even if same date is tapped again
                        showingDailyDetails = true
                    }
                    .padding(.vertical, Design.Spacing.md)
                    .background(Design.Colors.cardBackground)
                    
                    // Main content - show today's data by default
                    if let todayLog = logStore.getLog(for: selectedDate) {
                        dailyContentView(log: todayLog)
                    } else {
                        emptyStateView
                    }
                }
            }
            .navigationTitle("Meal History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDailyDetails = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingDailyDetails) {
                DailyDetailsSheet(date: selectedDate, isPresented: $showingDailyDetails)
            }
            .onAppear {
                // Ensure we're observing log changes
                _ = logStore.logs
            }
        }
    }
    
    // MARK: - Daily Content View
    private func dailyContentView(log: DailyLog) -> some View {
        ScrollView {
            VStack(spacing: Design.Spacing.lg) {
                // Quick summary card
                quickSummaryCard(log: log)
                
                // Meals section
                if !log.meals.isEmpty {
                    mealsQuickView(log: log)
                }
                
                // Liquid intake quick view
                if !log.liquidIntake.isEmpty {
                    liquidQuickView(log: log)
                }
                
                // Tap to see more button
                Button {
                    showingDailyDetails = true
                } label: {
                    HStack {
                        Text("View Full Details")
                            .font(Design.Typography.headline)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Design.Spacing.md)
                    .background(Design.Colors.primary)
                    .cornerRadius(Design.Radius.medium)
                }
                .padding(.horizontal, Design.Spacing.md)
            }
            .padding(.vertical, Design.Spacing.md)
        }
    }
    
    // MARK: - Quick Summary Card
    private func quickSummaryCard(log: DailyLog) -> some View {
        VStack(spacing: Design.Spacing.md) {
            Text(formatDate(log.date))
                .font(Design.Typography.title3)
                .foregroundColor(.primary)
            
            HStack(spacing: Design.Spacing.lg) {
                VStack {
                    Text("\(Int(log.totalCalories))")
                        .font(Design.Typography.title)
                        .foregroundColor(Design.Colors.calories)
                    Text("Calories")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text(String(format: "%.1f", log.totalSugar))
                        .font(Design.Typography.title)
                        .foregroundColor(Design.Colors.sugar)
                    Text("Sugar (g)")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text(String(format: "%.2f", log.totalLiquid))
                        .font(Design.Typography.title)
                        .foregroundColor(Design.Colors.water)
                    Text("Water (L)")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.lg)
        .cardStyle()
        .padding(.horizontal, Design.Spacing.md)
    }
    
    // MARK: - Meals Quick View
    private func mealsQuickView(log: DailyLog) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Text("Meals")
                    .font(Design.Typography.title3)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(log.meals.count) logged")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(log.meals.prefix(3).sorted(by: { $0.timestamp > $1.timestamp })) { meal in
                HStack {
                    Image(systemName: meal.mealType.icon)
                        .foregroundColor(Design.Colors.primary)
                    Text(meal.mealType.displayName)
                        .font(Design.Typography.body)
                    Spacer()
                    Text("\(Int(meal.totalCalories)) kcal")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if log.meals.count > 3 {
                Text("+ \(log.meals.count - 3) more meals")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
        .padding(.horizontal, Design.Spacing.md)
    }
    
    // MARK: - Liquid Quick View
    private func liquidQuickView(log: DailyLog) -> some View {
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
            
            ForEach(log.liquidIntake.prefix(3).sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                HStack {
                    Image(systemName: entry.beverageType.icon)
                        .foregroundColor(Design.Colors.primary)
                    Text(entry.beverageName ?? entry.beverageType.displayName)
                        .font(Design.Typography.body)
                    Spacer()
                    Text(String(format: "%.2f L", entry.amount))
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if log.liquidIntake.count > 3 {
                Text("+ \(log.liquidIntake.count - 3) more entries")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(Design.Spacing.md)
        .cardStyle()
        .padding(.horizontal, Design.Spacing.md)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(Design.Colors.primary.opacity(0.5))
            
            Text("No Data for This Date")
                .font(Design.Typography.title2)
                .foregroundColor(.primary)
            
            Text("Start logging your meals to see your history here")
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
