import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    
    // Use onboarding name if available
    private var displayName: String {
        if !isLoginMode && !auth.name.isEmpty {
            return auth.name
        }
        return name
    }
    
    var body: some View {
        ZStack {
            // Adaptive background for dark mode
            Design.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    Spacer(minLength: 40)
                    
                    // Logo and title
                    VStack(spacing: Design.Spacing.md) {
                        LogoView(size: .large, showText: false, color: Design.Colors.primary)
                            .padding(.top, Design.Spacing.xl)
                        
                        Text("GoFit.Ai")
                            .font(Design.Typography.display)
                            .foregroundColor(.primary)
                        
                        Text(isLoginMode ? "Welcome back!" : "Create your account")
                            .font(Design.Typography.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Form Card
                    ModernCard {
                        VStack(spacing: Design.Spacing.md) {
                            if !isLoginMode {
                                CustomTextField(
                                    placeholder: "Full Name",
                                    text: Binding(
                                        get: { !auth.name.isEmpty ? auth.name : name },
                                        set: { name = $0 }
                                    ),
                                    icon: "person.fill"
                                )
                                .disabled(!auth.name.isEmpty) // Disable if name from onboarding
                            }
                            
                            CustomTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            
                            CustomSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )
                            
                            if !isLoginMode {
                                CustomSecureField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    
                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: Design.Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(Design.Typography.subheadline)
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
                    
                    // Action button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLoginMode ? "Sign In" : "Create Account")
                        }
                    }
                    .buttonStyle(ModernButtonStyle())
                    .disabled(isLoading || !isFormValid)
                    .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                    .padding(.horizontal, Design.Spacing.md)
                    
                    // Toggle mode
                    Button(action: {
                        withAnimation(Design.Animation.spring) {
                            isLoginMode.toggle()
                            errorMessage = nil
                            if isLoginMode {
                                name = ""
                                confirmPassword = ""
                            }
                        }
                    }) {
                        HStack {
                            Text(isLoginMode ? "Don't have an account? " : "Already have an account? ")
                                .foregroundColor(.secondary)
                            Text(isLoginMode ? "Sign Up" : "Sign In")
                                .foregroundColor(Design.Colors.primary)
                                .fontWeight(.semibold)
                        }
                        .font(Design.Typography.body)
                    }
                    .padding(.top, Design.Spacing.md)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Design.Spacing.md)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.top, Design.Spacing.lg)
                    
                    // Sign in with Apple
                    Button(action: {
                        handleAppleSignInButton()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(Design.Typography.headline)
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(ModernSecondaryButtonStyle(
                        borderColor: Color(.separator),
                        foregroundColor: .primary
                    ))
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.top, Design.Spacing.sm)
                    
                    // Optional: Phone OTP (can be added later)
                    if isLoginMode {
                        Button(action: {
                            // TODO: Implement phone OTP
                        }) {
                            Text("Sign in with Phone")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 8)
                    }
                    
                    // Skip authentication button (development only)
                    if EnvironmentConfig.skipAuthentication {
                        Button(action: {
                            auth.skipAuthentication()
                        }) {
                            Text("Skip Authentication (Dev Mode)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 16)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(auth)
        }
        .onChange(of: auth.isLoggedIn) { oldValue, newValue in
            if newValue && !isLoginMode {
                // Show paywall after signup
                showingPaywall = true
            }
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty && Validators.isValidEmail(email)
        } else {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && 
                   password == confirmPassword && password.count >= 8 &&
                   Validators.isValidEmail(email)
        }
    }
    
    private func handleAuth() {
        // Clear previous errors
        errorMessage = nil
        
        // Validate form before submitting
        guard isFormValid else {
            if isLoginMode {
                if email.isEmpty || password.isEmpty {
                    errorMessage = "Please fill in all fields"
                } else if !Validators.isValidEmail(email) {
                    errorMessage = "Please enter a valid email address"
                }
            } else {
                if name.isEmpty {
                    errorMessage = "Name is required"
                } else if email.isEmpty || !Validators.isValidEmail(email) {
                    errorMessage = "Please enter a valid email address"
                } else if password.isEmpty {
                    errorMessage = "Password is required"
                } else if password.count < 8 {
                    errorMessage = "Password must be at least 8 characters"
                } else if password != confirmPassword {
                    errorMessage = "Passwords do not match"
                }
            }
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if isLoginMode {
                    try await auth.login(email: email, password: password)
                    await MainActor.run {
                        isLoading = false
                        // Clear form on success
                        email = ""
                        password = ""
                    }
                } else {
                    // Use name from onboarding if available, otherwise use form input
                    let signupName = !auth.name.isEmpty ? auth.name : name
                    try await auth.signup(name: signupName, email: email, password: password)
                    // After successful signup, show paywall
                    await MainActor.run {
                        isLoading = false
                        // Clear form on success
                        name = ""
                        email = ""
                        password = ""
                        confirmPassword = ""
                        showingPaywall = true
                    }
                }
            } catch {
                await MainActor.run {
                    // Extract error message from various error types
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "No internet connection. Please check your network."
                        case .timedOut:
                            errorMessage = "Connection timed out. Please try again."
                        case .cannotFindHost:
                            errorMessage = "Cannot reach server. Please check your connection."
                        default:
                            errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else if let nsError = error as NSError? {
                        // Try to extract message from userInfo
                        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func handleAppleSignInButton() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await auth.signInWithApple()
                await MainActor.run {
                    isLoading = false
                    if !isLoginMode {
                        showingPaywall = true
                    }
                }
            } catch {
                await MainActor.run {
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "No internet connection. Please check your network."
                        case .timedOut:
                            errorMessage = "Connection timed out. Please try again."
                        case .cannotFindHost:
                            errorMessage = "Cannot reach server. Please check your connection."
                        default:
                            errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else if let nsError = error as NSError? {
                        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Custom Text Field (Modern Design)
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Design.Colors.primary)
                .font(Design.Typography.subheadline)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(Design.Typography.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
        }
        .padding(Design.Spacing.md)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(Design.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Design.Radius.medium)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

// MARK: - Custom Secure Field (Modern Design)
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Design.Colors.primary)
                .font(Design.Typography.subheadline)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(Design.Typography.body)
            } else {
                TextField(placeholder, text: $text)
                    .font(Design.Typography.body)
            }
            
            Button(action: { 
                withAnimation(Design.Animation.springFast) {
                    isSecure.toggle()
                }
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
                    .font(Design.Typography.subheadline)
            }
        }
        .padding(Design.Spacing.md)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(Design.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Design.Radius.medium)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}
