import SwiftUI

struct SettingsSection<Content: View>: View {

    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
        }
    }
}
