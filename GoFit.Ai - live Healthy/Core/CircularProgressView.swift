import SwiftUI

// MARK: - Circular Progress Indicator (2025 Style)
struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    let backgroundColor: Color
    let showPercentage: Bool
    let label: String?
    let value: String?
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 120,
        color: Color = AppDesign.Colors.primary,
        backgroundColor: Color = Color.gray.opacity(0.2),
        showPercentage: Bool = false,
        label: String? = nil,
        value: String? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
        self.label = label
        self.value = value
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        angle: .degrees(-90)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppDesign.Animation.smooth, value: animatedProgress)
            
            // Center content
            VStack(spacing: 4) {
                if let value = value {
                    Text(value)
                        .font(AppDesign.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                } else if showPercentage {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(AppDesign.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                if let label = label {
                    Text(label)
                        .font(AppDesign.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(AppDesign.Animation.smooth.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(AppDesign.Animation.smooth) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Macro Circle (Smaller version for macros)
struct MacroCircleView: View {
    let progress: Double
    let color: Color
    let label: String
    let value: String
    let total: String?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppDesign.Animation.smooth, value: progress)
                
                VStack(spacing: 2) {
                    Text(value)
                        .font(AppDesign.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    if let total = total {
                        Text("/\(total)")
                            .font(AppDesign.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)
            
            Text(label)
                .font(AppDesign.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

