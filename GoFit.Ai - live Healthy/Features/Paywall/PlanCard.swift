import SwiftUI
import StoreKit

struct PlanCard: View {
    let product: Product
    let type: PaywallView.PlanType
    let isSelected: Bool
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
            VStack(spacing: Design.Spacing.sm) {
                Text(type.periodText.capitalized)
                    .font(Design.Typography.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(product.displayPrice)
                    .font(Design.Typography.title2)
                    .foregroundColor(isSelected ? .white : .primary)

                Text("per \(type.periodText)")
                    .font(Design.Typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

                if let subscription = product.subscription,
                   let _ = subscription.introductoryOffer {
                    Text("3-day free trial")
                        .font(Design.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : Design.Colors.primary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Design.Spacing.lg)
            .background(
                isSelected ?
                Design.Colors.primaryGradient :
                LinearGradient(colors: [Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(Design.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.large)
                    .stroke(isSelected ? Color.clear : Design.Colors.primary.opacity(0.3), lineWidth: 2)
            )
            .shadow(
                color: isSelected ? Design.Colors.primary.opacity(0.3) : Color.clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: isSelected ? 6 : 0
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Design.Animation.springFast, value: isPressed)
    }
}
