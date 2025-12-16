import SwiftUI

struct MacroPill: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(Design.Typography.headline)
                .foregroundColor(color)

            Text(label)
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}
