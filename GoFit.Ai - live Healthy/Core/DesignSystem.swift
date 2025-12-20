import SwiftUI

// MARK: - Design System 2025
struct AppDesign {
    // Colors - Vibrant 2025 Palette
    struct Colors {
        // Primary - Vibrant Green (like reference)
        static let primary = Color(red: 0.2, green: 0.85, blue: 0.4) // Vibrant Green
        static let primaryLight = Color(red: 0.35, green: 0.95, blue: 0.55)
        static let primaryDark = Color(red: 0.15, green: 0.75, blue: 0.3)
        static let accent = Color(red: 1.0, green: 0.84, blue: 0.0) // Sunrise Yellow
        static let secondary = Color.gray
        
        // Background - Force Light Mode
        static let background = Color.white
        static let cardBackground = Color(white: 0.98)
        static let secondaryBackground = Color(white: 0.95)
        
        // Gradient
        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [primary, primaryLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Glassmorphism background - Light mode only
        static var glassBackground: Color {
            Color.white.opacity(0.7)
        }
        static var glassBackgroundDark: Color {
            Color.white.opacity(0.1)
        }
        
        // Category colors - More vibrant
        static let calories = Color(red: 1.0, green: 0.5, blue: 0.0) // Bright Orange
        static let protein = Color(red: 0.0, green: 0.5, blue: 1.0) // Bright Blue
        static let carbs = Color(red: 1.0, green: 0.2, blue: 0.3) // Bright Red
        static let fat = Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        static let sugar = Color(red: 0.9, green: 0.1, blue: 0.5) // Pink
        static let water = Color(red: 0.2, green: 0.7, blue: 1.0) // Sky Blue
        static let steps = Color(red: 0.2, green: 0.85, blue: 0.4) // Green
        static let heart = Color(red: 1.0, green: 0.2, blue: 0.3) // Red
    }
    
    // Typography - Consistent, Modern Scale
    struct Typography {
        // Display & Titles
        static let display = Font.system(size: 36, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body Text
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyBold = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .medium, design: .rounded)
        
        // Supporting Text
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
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
    
    // Shadows - Adaptive for Dark Mode
    struct Shadows {
        static var small: Shadow {
            Shadow(
                color: Color.primary.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        static var medium: Shadow {
            Shadow(
                color: Color.primary.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        static var large: Shadow {
            Shadow(
                color: Color.primary.opacity(0.2),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }
    
    // Animation - Smooth 2025 Animations
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.25)
        static let springFast = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0.15)
        static let springSlow = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Card Style with Glassmorphism
struct CardStyle: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadow: Shadow
    let useGlass: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if useGlass {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor.opacity(0.7))
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.25),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor)
                    }
                }
            )
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = Color.white,
        cornerRadius: CGFloat = AppDesign.Radius.large,
        shadow: Shadow = AppDesign.Shadows.medium,
        useGlass: Bool = false
    ) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius, shadow: shadow, useGlass: useGlass))
    }
}

// MARK: - Animated Button Style with Haptic
struct AnimatedButtonStyle: ButtonStyle {
    let color: Color
    let isPrimary: Bool
    
    init(color: Color = AppDesign.Colors.primary, isPrimary: Bool = true) {
        self.color = color
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppDesign.Animation.springFast, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, pressed in
                if pressed {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
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

// MARK: - Shimmer Effect (Adaptive for Dark Mode)
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.primary.opacity(colorScheme == .dark ? 0.2 : 0.3),
                        Color.clear
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

