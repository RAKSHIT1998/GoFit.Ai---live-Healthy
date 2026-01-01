import SwiftUI

struct ChangePasswordView: View {

    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section(header: Text("Change Password")) {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                Section {
                    Text("Password must be at least 8 characters long.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        changePassword()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading || !isValid)
                }
            }
        }
    }

    // MARK: - Validation
    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }

    // MARK: - API
    private func changePassword() {
        guard isValid else { return }

        isLoading = true
        errorMessage = nil

        Task {
            struct ChangePasswordRequest: Codable {
                let currentPassword: String
                let newPassword: String
            }

            let payload = ChangePasswordRequest(
                currentPassword: currentPassword,
                newPassword: newPassword
            )

            do {
                let body = try JSONEncoder().encode(payload)
                struct ChangePasswordResponse: Codable {
                    let message: String
                }
                let response: ChangePasswordResponse = try await NetworkManager.shared.request(
                    "auth/change-password",
                    method: "POST",
                    body: body
                )

                await MainActor.run {
                    isLoading = false
                    // Clear password fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    errorMessage = nil
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    if let nsError = error as NSError? {
                        // Try to extract error message from response
                        if nsError.code == 401 {
                            errorMessage = "Current password is incorrect"
                        } else if nsError.code == 400 {
                            errorMessage = "New password must be at least 8 characters"
                        } else {
                            errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}
