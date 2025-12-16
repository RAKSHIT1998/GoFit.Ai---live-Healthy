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
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
            }

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(Design.Typography.headline)
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
        .cardStyle()
    }
}
