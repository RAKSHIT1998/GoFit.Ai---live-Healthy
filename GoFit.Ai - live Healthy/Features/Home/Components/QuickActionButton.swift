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
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }

                Text(label)
                    .font(Design.Typography.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Design.Radius.large)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Design.Animation.springFast, value: isPressed)
    }
}
