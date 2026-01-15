import SwiftUI

/// Scrollable calendar bar for selecting dates - shows 30 days
struct ScrollableCalendarBar: View {
    @Binding var selectedDate: Date
    @StateObject private var logStore = LocalDailyLogStore.shared
    
    private let calendar = Calendar.current
    private let daysToShow = 30 // 30-day cycle
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Spacing.sm) {
                    ForEach(getDateRange(), id: \.self) { date in
                        CalendarDayButton(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasData: hasData(for: date),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                            }
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
            }
            .onAppear {
                // Scroll to today on appear
                let today = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(today, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                // Scroll to selected date when it changes externally
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func getDateRange() -> [Date] {
        let today = Date()
        var dates: [Date] = []
        
        // Start from 15 days ago to 15 days ahead (30 days total, centered on today)
        for i in -15..<15 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func hasData(for date: Date) -> Bool {
        guard let log = logStore.getLog(for: date) else { return false }
        return !log.meals.isEmpty || !log.liquidIntake.isEmpty || log.caloriesBurned > 0 || log.steps != nil
    }
}

// MARK: - Calendar Day Button
struct CalendarDayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasData: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Day of week
                Text(dayOfWeek)
                    .font(Design.Typography.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                // Day number
                Text(dayNumber)
                    .font(Design.Typography.headline)
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : (isToday ? Design.Colors.primary : .primary))
                
                // Data indicator
                if hasData {
                    Circle()
                        .fill(isSelected ? .white.opacity(0.8) : Design.Colors.primary)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 60, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Design.Colors.primary : (isToday ? Design.Colors.primary.opacity(0.1) : Design.Colors.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
