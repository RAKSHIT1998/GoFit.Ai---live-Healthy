import SwiftUI

struct WorkoutSuggestionsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var suggestions: [String] = []
    @State private var loading = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if loading { ProgressView("Generating...") }
                if suggestions.isEmpty && !loading {
                    Text("No suggestions yet").foregroundColor(.secondary)
                }
                List {
                    ForEach(suggestions, id: \.self) { s in
                        Text(s).padding(8)
                    }
                }
            }
            .navigationTitle("Workout Suggestions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") { Task { await generate() } }
                }
            }
            .task { await generate() }
        }
    }

    func generate() async {
        loading = true
        suggestions = []
        defer { loading = false }
        // Call your recommendation API: GET /api/recommendations/workout?userId=...
        do {
            try await Task.sleep(nanoseconds: 250_000_000)
            // placeholder items
            suggestions = [
                "20 min HIIT: 30s on / 30s off (squats, burpees, mountain climbers)",
                "15 min core flow: planks, dead bugs, russian twists",
                "30 min brisk walk or jog (moderate intensity)"
            ]
        } catch {
            suggestions = ["Failed to load suggestions"]
        }
    }
}
