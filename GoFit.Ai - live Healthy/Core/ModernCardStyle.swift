import SwiftUI

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Design.Spacing.lg
    var backgroundColor: Color = Color(.secondarySystemBackground)
    var cornerRadius: CGFloat = Design.Radius.large
    
    init(
        padding: CGFloat = Design.Spacing.lg,
        backgroundColor: Color = Color(.secondarySystemBackground),
        cornerRadius: CGFloat = Design.Radius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.primary.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    var backgroundColor: Color = Design.Colors.primary
    var foregroundColor: Color = .white
    var height: CGFloat = 56
    var cornerRadius: CGFloat = Design.Radius.medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Design.Animation.springFast, value: configuration.isPressed)
    }
}

// MARK: - Modern Secondary Button
struct ModernSecondaryButtonStyle: ButtonStyle {
    var borderColor: Color = Design.Colors.primary
    var foregroundColor: Color = Design.Colors.primary
    var height: CGFloat = 56
    var cornerRadius: CGFloat = Design.Radius.medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Design.Animation.springFast, value: configuration.isPressed)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(Design.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Design.Typography.subheadline)
                        .foregroundColor(Design.Colors.primary)
                }
            }
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.vertical, Design.Spacing.sm)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(title)
                .font(Design.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(message)
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(ModernButtonStyle())
                .padding(.horizontal, Design.Spacing.xl)
                .padding(.top, Design.Spacing.md)
            }
        }
        .padding(.vertical, Design.Spacing.xl)
    }
}

