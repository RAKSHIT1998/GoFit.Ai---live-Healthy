import SwiftUI

struct ScaleButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(
                Animation.spring(response: 0.3, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}
