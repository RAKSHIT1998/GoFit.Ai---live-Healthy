import SwiftUI

struct HealthMetricCard: View {

    let icon: String
    let value: String
    let label: String
    let color: Color
    let unit: String

    var body: some View {
        VStack(spacing: Design.Spacing.sm) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 52, height: 52)
                    .blur(radius: 6)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(Design.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(label)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.md)
        .cardStyle(useGlass: true)
    }
}
