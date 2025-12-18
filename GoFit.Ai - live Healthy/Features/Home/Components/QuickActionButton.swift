import SwiftUI

struct QuickActionButton: View {

    let icon: String
    let label: String
    let color: Color
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.impact(style: .light)
            withAnimation(Design.Animation.springFast) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        } label: {
            VStack(spacing: Design.Spacing.sm) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(gradient)
                        .frame(width: 64, height: 64)
                        .blur(radius: 8)
                        .opacity(0.4)
                    
                    // Main circle
                    Circle()
                        .fill(gradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Text(label)
                    .font(Design.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.large)
                    .fill(Color(.systemBackground).opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.large)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.large)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(Design.Animation.springFast, value: isPressed)
    }
}
