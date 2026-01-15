import SwiftUI

/// Scrollable calendar bar for selecting dates - shows 31 days (15 past, today, 15 future)
struct ScrollableCalendarBar: View {
    @Binding var selectedDate: Date
    @StateObject private var logStore = LocalDailyLogStore.shared
    var onDateSelected: (() -> Void)? = nil // Callback when date is selected
    
    private let calendar = Calendar.current
    
    // Cache the date range to avoid regenerating on every render
    // Normalize all dates to start of day for consistent ID matching
    @State private var dateRange: [Date] = []
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Spacing.sm) {
                    ForEach(dateRange, id: \.self) { date in
                        CalendarDayButton(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasData: hasData(for: date),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                    // Call callback to open sheet even if same date is tapped
                                    onDateSelected?()
                                }
                            }
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
            }
            .onAppear {
                // Initialize date range once
                if dateRange.isEmpty {
                    dateRange = generateDateRange()
                }
                
                // Scroll to today on appear - use normalized date from range
                let normalizedToday = normalizeToStartOfDay(Date())
                if let todayInRange = dateRange.first(where: { calendar.isDate($0, inSameDayAs: normalizedToday) }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(todayInRange, anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                // Scroll to selected date when it changes externally - use normalized date from range
                let normalizedSelected = normalizeToStartOfDay(newValue)
                if let selectedInRange = dateRange.first(where: { calendar.isDate($0, inSameDayAs: normalizedSelected) }) {
                    withAnimation {
                        proxy.scrollTo(selectedInRange, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 80)
    }
    
    /// Normalize date to start of day for consistent comparison and ID matching
    private func normalizeToStartOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    /// Generate date range: 15 days past, today, 15 days future (31 days total)
    private func generateDateRange() -> [Date] {
        let today = normalizeToStartOfDay(Date())
        var dates: [Date] = []
        
        // Generate 15 days past, today, and 15 days future (31 days total, symmetric)
        for i in -15...15 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(normalizeToStartOfDay(date))
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
