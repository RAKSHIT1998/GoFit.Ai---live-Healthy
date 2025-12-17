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
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.7, blue: 0.6), // Teal Green
                    Color(red: 0.3, green: 0.8, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Logo and title
                    VStack(spacing: 16) {
                        LogoViewLight(size: .large, showText: false)
                        
                        Text("GoFit.Ai")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(isLoginMode ? "Welcome back!" : "Create your account")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        if !isLoginMode {
                            CustomTextField(
                                placeholder: "Full Name",
                                text: $name,
                                icon: "person.fill"
                            )
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
                    .padding(.horizontal, 24)
                    
                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    
                    // Action button
                    Button(action: handleAuth) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.7, blue: 0.6)))
                            } else {
                                Text(isLoginMode ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    
                    // Toggle mode
                    Button(action: {
                        withAnimation(.spring()) {
                            isLoginMode.toggle()
                            errorMessage = nil
                            // Clear form when switching modes
                            if isLoginMode {
                                name = ""
                                confirmPassword = ""
                            }
                        }
                    }) {
                        HStack {
                            Text(isLoginMode ? "Don't have an account? " : "Already have an account? ")
                                .foregroundColor(.white.opacity(0.8))
                            Text(isLoginMode ? "Sign Up" : "Sign In")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.body)
                    }
                    .padding(.top, 8)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Sign in with Apple
                    Button(action: {
                        handleAppleSignInButton()
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
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
                    try await auth.signup(name: name, email: email, password: password)
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

// MARK: - Custom Text Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
