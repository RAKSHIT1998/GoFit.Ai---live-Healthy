import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var purchases: PurchaseManager
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    @State private var showingForgotPassword = false
    
    // Animation states
    @State private var animateLogo = false
    @State private var animateForm = false
    @State private var animateBackground = false
    @State private var showParticles = false
    
    // Use onboarding name if available
    private var displayName: String {
        if !isLoginMode && !auth.name.isEmpty {
            return auth.name
        }
        return name
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()
                .opacity(animateBackground ? 1 : 0.8)
            
            // Floating particles/shapes
            if showParticles {
                FloatingParticles()
                    .opacity(0.3)
            }
            
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    Spacer(minLength: 40)
                    
                    // Logo and title with animations
                    VStack(spacing: Design.Spacing.md) {
                        LogoView(size: .large, showText: false, color: Design.Colors.primary)
                            .scaleEffect(animateLogo ? 1.0 : 0.8)
                            .opacity(animateLogo ? 1.0 : 0.0)
                            .rotationEffect(.degrees(animateLogo ? 0 : -10))
                            .padding(.top, Design.Spacing.xl)
                        
                        Text("GoFit.Ai")
                            .font(Design.Typography.display)
                            .foregroundColor(.primary)
                            .opacity(animateLogo ? 1.0 : 0.0)
                            .offset(y: animateLogo ? 0 : -20)
                        
                        Text(isLoginMode ? "Welcome back! 👋" : "Start your journey 🚀")
                            .font(Design.Typography.title3)
                            .foregroundColor(.secondary)
                            .opacity(animateLogo ? 1.0 : 0.0)
                            .offset(y: animateLogo ? 0 : -10)
                        
                        if !isLoginMode {
                            Text("Join thousands achieving their health goals")
                                .font(Design.Typography.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                                .opacity(animateLogo ? 1.0 : 0.0)
                        }
                    }
                    
                    // Form Card with staggered animation
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
                                .opacity(animateForm ? 1.0 : 0.0)
                                .offset(x: animateForm ? 0 : -30)
                            }
                            
                            CustomTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(x: animateForm ? 0 : -30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateForm)
                            
                            CustomSecureField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(x: animateForm ? 0 : -30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateForm)
                            
                            // Forgot password link (only in login mode)
                            if isLoginMode {
                                Button(action: {
                                    showingForgotPassword = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Forgot Password?")
                                            .font(Design.Typography.caption)
                                            .foregroundColor(Design.Colors.primary)
                                    }
                                }
                                .padding(.horizontal, Design.Spacing.md)
                                .opacity(animateForm ? 1.0 : 0.0)
                                .offset(y: animateForm ? 0 : 10)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: animateForm)
                            }
                            
                            if !isLoginMode {
                                CustomSecureField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill"
                                )
                                .opacity(animateForm ? 1.0 : 0.0)
                                .offset(x: animateForm ? 0 : -30)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animateForm)
                            }
                        }
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .opacity(animateForm ? 1.0 : 0.0)
                    .scaleEffect(animateForm ? 1.0 : 0.95)
                    
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
                    
                    // Action button with enhanced design
                    Button(action: handleAuth) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: isLoginMode ? "arrow.right.circle.fill" : "sparkles")
                                    .font(.title3)
                                Text(isLoginMode ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if isFormValid && !isLoading {
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
                        .shadow(color: Design.Colors.primary.opacity(isFormValid ? 0.4 : 0), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isLoading || !isFormValid)
                    .scaleEffect(isFormValid && !isLoading ? 1.0 : 0.98)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFormValid)
                    .padding(.horizontal, Design.Spacing.md)
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateForm)
                    
                    // Toggle mode with animation
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isLoginMode.toggle()
                            errorMessage = nil
                            animateForm = false
                            if isLoginMode {
                                name = ""
                                confirmPassword = ""
                            }
                        }
                        // Re-animate form after mode change
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                animateForm = true
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isLoginMode ? "Don't have an account? " : "Already have an account? ")
                                .foregroundColor(.secondary)
                            Text(isLoginMode ? "Sign Up" : "Sign In")
                                .foregroundColor(Design.Colors.primary)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(Design.Colors.primary)
                        }
                        .font(Design.Typography.body)
                    }
                    .padding(.top, Design.Spacing.md)
                    .opacity(animateForm ? 1.0 : 0.0)
                    
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
                    
                    // Sign in with Apple - Enhanced
                    Button(action: {
                        handleAppleSignInButton()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.primary)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.separator), lineWidth: 1.5)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1.0)
                    .scaleEffect(isLoading ? 0.98 : 1.0)
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.top, Design.Spacing.sm)
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateForm)
                    
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
                    .environmentObject(purchases)
                    .interactiveDismissDisabled(false) // Allow dismissing paywall after signup
                    .onDisappear {
                        // Initialize trial after signup if not already initialized
                        if auth.isLoggedIn {
                            purchases.initializeTrialForNewUser()
                        }
                    }
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        .onAppear {
            // If coming from onboarding (has onboarding data), default to signup mode
            if auth.onboardingData != nil && !auth.isLoggedIn {
                isLoginMode = false
                // Pre-fill name from onboarding
                if !auth.name.isEmpty {
                    name = auth.name
                }
            }
            
            // Start animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateLogo = true
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                animateForm = true
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showParticles = true
                }
            }
        }
        .onChange(of: auth.isLoggedIn) { oldValue, newValue in
            if newValue && !isLoginMode && !showingPaywall {
                // Initialize trial for new user after signup
                purchases.initializeTrialForNewUser()
                // Show paywall after signup (with small delay to ensure state is updated)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingPaywall = true
                }
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
                    // After successful signup, initialize trial and show paywall
                    await MainActor.run {
                        isLoading = false
                        // Initialize trial for new user after signup
                        purchases.initializeTrialForNewUser()
                        // Clear form on success
                        name = ""
                        email = ""
                        password = ""
                        confirmPassword = ""
                        // Small delay before showing paywall to ensure state is updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingPaywall = true
                        }
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
                        // Initialize trial for new Apple sign-in user
                        purchases.initializeTrialForNewUser()
                        // Small delay before showing paywall
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingPaywall = true
                        }
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

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Design.Colors.primary.opacity(0.1),
                Design.Colors.primary.opacity(0.05),
                Color.clear,
                Design.Colors.primary.opacity(0.08)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Floating Particles (Simplified for Performance)
struct FloatingParticles: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Create a few floating circles
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Design.Colors.primary.opacity(0.15))
                        .frame(width: CGFloat.random(in: 40...80), height: CGFloat.random(in: 40...80))
                        .position(
                            x: animate ? CGFloat.random(in: 0...geometry.size.width) : CGFloat.random(in: 0...geometry.size.width),
                            y: animate ? CGFloat.random(in: 0...geometry.size.height) : CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 15)
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...6))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: animate
                        )
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Custom Text Field (Enhanced with Animations)
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    @State private var isFilled = false
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? Design.Colors.primary : .secondary)
                .font(Design.Typography.subheadline)
                .frame(width: 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
            
            TextField(placeholder, text: $text)
                .font(Design.Typography.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isFilled = !newValue.isEmpty
                    }
                }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.medium)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: Design.Radius.medium)
                        .stroke(
                            isFocused ? Design.Colors.primary : Color(.separator),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? Design.Colors.primary.opacity(0.2) : Color.clear,
            radius: isFocused ? 8 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }
}

// MARK: - Custom Secure Field (Enhanced with Animations)
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    @State private var isFilled = false
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? Design.Colors.primary : .secondary)
                .font(Design.Typography.subheadline)
                .frame(width: 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(Design.Typography.body)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(Design.Typography.body)
                    .focused($isFocused)
            }
            
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isSecure.toggle()
                }
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isFocused ? Design.Colors.primary : .gray)
                    .font(Design.Typography.subheadline)
                    .rotationEffect(.degrees(isSecure ? 0 : 180))
            }
            .onChange(of: text) { oldValue, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFilled = !newValue.isEmpty
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.medium)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: Design.Radius.medium)
                        .stroke(
                            isFocused ? Design.Colors.primary : Color(.separator),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? Design.Colors.primary.opacity(0.2) : Color.clear,
            radius: isFocused ? 8 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }
}
