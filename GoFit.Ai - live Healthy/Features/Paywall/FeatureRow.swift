import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var animate = false

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Design.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(Design.Colors.primary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Design.Typography.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(Design.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(Design.Radius.medium)
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -20)
        .onAppear {
            withAnimation(Design.Animation.spring.delay(delay)) {
                animate = true
            }
        }
    }
}
