import SwiftUI

struct SettingsRow: View {

    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}
