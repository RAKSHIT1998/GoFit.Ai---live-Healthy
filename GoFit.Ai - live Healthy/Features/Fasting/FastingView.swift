import SwiftUI

struct FastingView: View {
    @State private var fastingStart: Date? = nil
    @State private var fastingWindowHours = 16
    @State private var isFasting = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var progress: Double = 0
    @State private var streak: Int = 7
    @Environment(\.dismiss) var dismiss
    @State private var animateTimer = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Design.Colors.primary.opacity(0.1),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.xl) {
                        // Timer Circle
                        timerCircle
                            .padding(.top, Design.Spacing.lg)
                        
                        // Status Card
                        statusCard
                            .padding(.horizontal, Design.Spacing.md)
                        
                        // Preset Windows
                        if !isFasting {
                            presetWindowsSection
                                .padding(.horizontal, Design.Spacing.md)
                        }
                        
                        // Streak Card
                        streakCard
                            .padding(.horizontal, Design.Spacing.md)
                        
                        // Action Button
                        actionButton
                            .padding(.horizontal, Design.Spacing.md)
                            .padding(.bottom, Design.Spacing.xl)
                    }
                }
                }
            .navigationTitle("Intermittent Fasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                updateTimer()
            }
            .onAppear {
                withAnimation(Design.Animation.spring) {
                    animateTimer = true
        }
    }
        }
    }
    
    // MARK: - Timer Circle
    private var timerCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 20)
                .frame(width: 220, height: 220)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Design.Colors.primaryGradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(Design.Animation.spring, value: progress)
            
            // Content
            VStack(spacing: 8) {
                if isFasting {
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Design.Colors.primary)
                        .contentTransition(.numericText)
                    
                    Text("remaining")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Ready to Fast")
                        .font(Design.Typography.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(fastingWindowHours)h")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .scaleEffect(animateTimer ? 1.0 : 0.8)
        .opacity(animateTimer ? 1.0 : 0.0)
        .animation(Design.Animation.spring as Animation, value: animateTimer)
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: Design.Spacing.md) {
            HStack {
                Image(systemName: isFasting ? "timer" : "clock")
                    .foregroundColor(Design.Colors.primary)
                    .font(.title3)
                
                Text(isFasting ? "Fasting in Progress" : "Not Fasting")
                    .font(Design.Typography.headline)
                
                Spacer()
            }
            
            if isFasting, let start = fastingStart {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Started")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(start.formatted(date: .omitted, time: .shortened))
                            .font(Design.Typography.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("\(fastingWindowHours) hours")
                            .font(Design.Typography.subheadline)
                    }
                }
            }
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Preset Windows
    private var presetWindowsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            Text("Quick Start")
                .font(Design.Typography.headline)
                .padding(.horizontal, Design.Spacing.xs)
            
            HStack(spacing: Design.Spacing.md) {
                PresetButton(hours: 16, label: "16:8") {
                    fastingWindowHours = 16
                    startFast()
                }
                PresetButton(hours: 18, label: "18:6") {
                    fastingWindowHours = 18
                    startFast()
                }
                PresetButton(hours: 20, label: "20:4") {
                    fastingWindowHours = 20
                    startFast()
                }
            }
        }
    }
    
    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Design.Colors.accent.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "flame.fill")
                    .foregroundColor(Design.Colors.accent)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(Design.Typography.title)
                        .foregroundColor(.primary)
                    Text("days")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            if isFasting {
                endFast()
            } else {
                startFast()
            }
        }) {
            HStack {
                Image(systemName: isFasting ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                Text(isFasting ? "End Fast" : "Start Fast")
                    .font(Design.Typography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Design.Spacing.md)
            .background(
                isFasting ?
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                Design.Colors.primaryGradient
            )
            .cornerRadius(Design.Radius.large)
            .shadow(color: Design.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(AnimatedButtonStyle())
    }
    
    // MARK: - Functions
    func startFast() {
        withAnimation(Design.Animation.spring) {
        fastingStart = Date()
        isFasting = true
        timeRemaining = TimeInterval(fastingWindowHours * 3600)
            progress = 0
        }
    }
    
    func endFast() {
        withAnimation(Design.Animation.spring) {
        fastingStart = nil
        isFasting = false
        timeRemaining = 0
            progress = 0
        }
    }
    
    func updateTimer() {
        guard isFasting, let start = fastingStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        let total = TimeInterval(fastingWindowHours * 3600)
        timeRemaining = max(0, total - elapsed)
        progress = min(1.0, elapsed / total)
        
        if timeRemaining == 0 {
            endFast()
        }
    }
    
    func timeString(from seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Preset Button
struct PresetButton: View {
    let hours: Int
    let label: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(Design.Animation.springFast) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(spacing: 6) {
                Text("\(hours)h")
                    .font(Design.Typography.headline)
                    .foregroundColor(Design.Colors.primary)
                Text(label)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(Design.Colors.primary.opacity(0.1))
            .cornerRadius(Design.Radius.medium)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Design.Animation.springFast, value: isPressed)
    }
}
