import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.xl) {
                        // Icon
                        Image(systemName: "lock.rotation")
                            .font(.system(size: Design.Scale.value(60, textStyle: .title1)))
                            .foregroundColor(Design.Colors.primary)
                            .padding(.top, Design.Spacing.xl)
                        
                        // Title
                        Text("Forgot Password?")
                            .font(Design.Typography.display)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.md)
                        
                        // Email field
                        CustomTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(.horizontal, Design.Spacing.md)
                        
                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: Design.Spacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(Design.Typography.body)
                                    .foregroundColor(.red)
                            }
                            .padding(Design.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(Design.Radius.medium)
                            .padding(.horizontal, Design.Spacing.md)
                        }
                        
                        // Success message
                        if let success = successMessage {
                            HStack(spacing: Design.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(success)
                                    .font(Design.Typography.body)
                                    .foregroundColor(.green)
                            }
                            .padding(Design.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(Design.Radius.medium)
                            .padding(.horizontal, Design.Spacing.md)
                        }
                        
                        // Submit button
                        Button(action: handleForgotPassword) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if isValidEmail && !isLoading {
                                        Design.Colors.primaryGradient
                                    } else {
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(16)
                            .shadow(color: Design.Colors.primary.opacity(isValidEmail ? 0.4 : 0), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isLoading || !isValidEmail)
                        .padding(.horizontal, Design.Spacing.md)
                        
                        // Note
                        Text("If an account with that email exists, a password reset link will be sent.")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.md)
                    }
                    .padding(.vertical, Design.Spacing.xl)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .alert("Email Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("If an account with that email exists, a password reset link has been sent. Please check your email.")
            }
        }
    }
    
    private var isValidEmail: Bool {
        !email.isEmpty && Validators.isValidEmail(email)
    }
    
    private func handleForgotPassword() {
        // Validate email before submitting
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // Prevent multiple simultaneous requests
        guard !isLoading else {
            return
        }
        
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                try await AuthService.shared.forgotPassword(email: trimmedEmail)
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                    successMessage = "Password reset link sent! Please check your email."
                    email = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "No internet connection. Please check your network and try again."
                        case .timedOut:
                            errorMessage = "Connection timed out. Please check your internet connection and try again."
                        case .cannotFindHost:
                            errorMessage = "Cannot reach server. Please check your connection and try again."
                        case .networkConnectionLost:
                            errorMessage = "Network connection lost. Please try again."
                        case .cancelled:
                            // Don't show error for cancelled requests
                            return
                        default:
                            errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else if let nsError = error as NSError? {
                        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = error.localizedDescription.isEmpty ? "Failed to send reset email. Please try again." : error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription.isEmpty ? "Failed to send reset email. Please try again." : error.localizedDescription
                    }
                    
                    #if DEBUG
                    print("❌ Forgot password error: \(errorMessage ?? "Unknown error")")
                    #endif
                }
            }
        }
    }
}
