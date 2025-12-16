import SwiftUI

struct StatCard: View {

    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(isPressed ? 0.9 : 1.0)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(
            Animation.spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}
