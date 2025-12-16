import SwiftUI

struct EditProfileView: View {

    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedGoal: String = "maintain"
    @State private var isLoading = false

    private let goals = ["lose", "maintain", "gain"]

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)

                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)

                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Goal")) {
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal.capitalized)
                                .tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = auth.name
                weight = String(format: "%.1f", auth.weightKg)
                height = String(format: "%.1f", auth.heightCm)
                selectedGoal = auth.goal
            }
        }
    }

    // MARK: - Save
    private func saveProfile() {
        isLoading = true

        auth.name = name
        if let w = Double(weight) { auth.weightKg = w }
        if let h = Double(height) { auth.heightCm = h }
        auth.goal = selectedGoal
        auth.saveLocalState()

        Task {
            struct ProfileUpdate: Codable {
                let name: String
                let metrics: Metrics
            }

            struct Metrics: Codable {
                let weightKg: Double
                let heightCm: Double
            }

            let payload = ProfileUpdate(
                name: auth.name,
                metrics: Metrics(
                    weightKg: auth.weightKg,
                    heightCm: auth.heightCm
                )
            )

            do {
                let body = try JSONEncoder().encode(payload)
                let _: EmptyResponse = try await NetworkManager.shared.request(
                    "auth/profile",
                    method: "PUT",
                    body: body
                )
            } catch {
                print("Profile update failed:", error)
            }

            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}
