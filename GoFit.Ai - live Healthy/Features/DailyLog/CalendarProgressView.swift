import SwiftUI

struct CalendarProgressView: View {
    @StateObject private var logStore = LocalDailyLogStore.shared
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            // Month navigation header
            monthHeader
            
            // Calendar grid
            calendarGrid
            
            // Legend
            legendView
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Design.Colors.primary)
                    .font(.headline)
            }
            
            Spacer()
            
            Text(currentMonth, formatter: dateFormatter)
                .font(Design.Typography.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Design.Colors.primary)
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: Design.Spacing.sm) {
            // Weekday headers
            weekdayHeaders
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Design.Spacing.sm) {
                ForEach(calendarDays, id: \.self) { date in
                    calendarDayCell(date: date)
                }
            }
        }
    }
    
    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func calendarDayCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayLog = logStore.getLog(for: date)
        let hasData = dayLog != nil && (dayLog!.meals.count > 0 || dayLog!.liquidIntake.count > 0 || dayLog!.caloriesBurned > 0 || dayLog!.steps != nil)
        
        return Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Design.Typography.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .secondary)
                
                // Progress indicators
                if hasData {
                    HStack(spacing: 2) {
                        // Meal indicator
                        if dayLog?.meals.count ?? 0 > 0 {
                            Circle()
                                .fill(Design.Colors.calories)
                                .frame(width: 4, height: 4)
                        }
                        
                        // Steps indicator
                        if dayLog?.steps ?? 0 > 0 {
                            Circle()
                                .fill(Design.Colors.steps)
                                .frame(width: 4, height: 4)
                        }
                        
                        // Liquid indicator
                        if dayLog?.totalLiquid ?? 0 > 0 {
                            Circle()
                                .fill(Design.Colors.water)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(width: 40, height: 50)
            .background(
                Group {
                    if isSelected {
                        Design.Colors.primary
                    } else if isToday {
                        Design.Colors.primary.opacity(0.1)
                    } else if hasData {
                        Design.Colors.secondaryBackground
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(Design.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.small)
                    .stroke(isToday && !isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
    
    // MARK: - Calendar Days
    private var calendarDays: [Date] {
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Sunday = 1, Monday = 2, etc. We want Sunday to be first day (0 offset)
        let firstWeekday = 1 // Sunday
        let daysToSubtract = (firstDayWeekday - firstWeekday + 7) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - Legend
    private var legendView: some View {
        HStack(spacing: Design.Spacing.md) {
            legendItem(color: Design.Colors.calories, label: "Meals")
            legendItem(color: Design.Colors.steps, label: "Steps")
            legendItem(color: Design.Colors.water, label: "Liquid")
        }
        .font(Design.Typography.caption2)
        .foregroundColor(.secondary)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
    
    // MARK: - Actions
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Preview
#Preview {
    CalendarProgressView(selectedDate: .constant(Date()))
        .padding()
        .background(Design.Colors.background)
}
