#if os(watchOS)
import SwiftUI

struct WatchDashboardView: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Today")
                    .font(.headline)

                metricRow(title: "Calories", value: "\(Int(watchManager.nutrition.calories))", unit: "kcal")
                metricRow(title: "Protein", value: String(format: "%.0f", watchManager.nutrition.protein), unit: "g")
                metricRow(title: "Carbs", value: String(format: "%.0f", watchManager.nutrition.carbs), unit: "g")
                metricRow(title: "Fat", value: String(format: "%.0f", watchManager.nutrition.fat), unit: "g")
                metricRow(title: "Fiber", value: String(format: "%.0f", watchManager.nutrition.fiber), unit: "g")
                metricRow(title: "Sugar", value: String(format: "%.0f", watchManager.nutrition.sugar), unit: "g")
                metricRow(title: "Water", value: String(format: "%.1f", watchManager.nutrition.water), unit: "L")

                Divider().padding(.vertical, 6)

                Button("Scan Food (iPhone)") {
                    watchManager.openScannerOnPhone()
                }
                .buttonStyle(.borderedProminent)

                Button("Log Water 250ml") {
                    watchManager.logWater(amount: 0.25)
                }
                .buttonStyle(.bordered)

                Button("Log Water 500ml") {
                    watchManager.logWater(amount: 0.5)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .onAppear {
            watchManager.start()
        }
    }

    @ViewBuilder
    private func metricRow(title: String, value: String, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value) \(unit)")
                .font(.headline)
        }
    }
}
#endif
