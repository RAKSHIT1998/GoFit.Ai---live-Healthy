import SwiftUI

// MARK: - Design System
struct AppDesign {
    // Colors
    struct Colors {
        static let primary = Color(red: 0.2, green: 0.7, blue: 0.6) // Teal Green
        static let primaryLight = Color(red: 0.3, green: 0.8, blue: 0.7)
        static let primaryDark = Color(red: 0.15, green: 0.6, blue: 0.5)
        static let accent = Color(red: 1.0, green: 0.84, blue: 0.0) // Sunrise Yellow
        static let secondary = Color.gray
        
        // Gradient
        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [primary, primaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Category colors
        static let calories = Color.orange
        static let protein = Color.blue
        static let carbs = Color.purple
        static let fat = Color.pink
        static let water = Color.blue
        static let steps = Color.green
        static let heart = Color.red
    }
    
    // Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // Corner Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    // Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)
        static let springFast = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)
        static let springSlow = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0.4)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadow: Shadow
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = Color(.systemBackground),
        cornerRadius: CGFloat = AppDesign.Radius.large,
        shadow: Shadow = AppDesign.Shadows.medium
    ) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    let color: Color
    let isPrimary: Bool
    
    init(color: Color = AppDesign.Colors.primary, isPrimary: Bool = true) {
        self.color = color
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(AppDesign.Animation.springFast, value: configuration.isPressed)
    }
}

// MARK: - Pulse Animation
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(color.opacity(0.3))
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(color: Color = AppDesign.Colors.primary) -> some View {
        modifier(PulseModifier(color: color))
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 300
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// Global typealias for easier access to design system
typealias Design = AppDesign

