import SwiftUI

struct OnboardingScreens: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var showingPermissions = false
    
    var body: some View {
        ZStack {
            // Adaptive background for dark mode
            Design.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button (dev mode only)
                if EnvironmentConfig.skipAuthentication {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Skip onboarding and go straight to app
                            auth.didFinishOnboarding = true
                            auth.saveLocalState()
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                
                // Progress indicator
                ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    NameStep(viewModel: viewModel)
                        .tag(1)
                    
                    GoalStep(viewModel: viewModel)
                        .tag(2)
                    
                    ActivityStep(viewModel: viewModel)
                        .tag(3)
                    
                    DietaryPreferencesStep(viewModel: viewModel)
                        .tag(4)
                    
                    AllergiesStep(viewModel: viewModel)
                        .tag(5)
                    
                    FastingPreferenceStep(viewModel: viewModel)
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(), value: viewModel.currentStep)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if viewModel.currentStep > 0 {
                        Button(action: { viewModel.previousStep() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.currentStep < viewModel.totalSteps - 1 {
                            viewModel.nextStep()
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(viewModel.currentStep < viewModel.totalSteps - 1 ? "Next" : "Get Started")
                            if viewModel.currentStep < viewModel.totalSteps - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .disabled(!viewModel.canProceed())
                    .opacity(viewModel.canProceed() ? 1 : 0.6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView(viewModel: viewModel)
        }
    }
    
    private func completeOnboarding() {
        // Save onboarding data to auth view model
        auth.name = viewModel.name.isEmpty ? "User" : viewModel.name
        auth.goal = viewModel.goal.rawValue
        auth.dietPrefs = viewModel.dietaryPreferences.map { $0.rawValue }
        auth.weightKg = 70 // Default if not set
        auth.heightCm = 170 // Default if not set
        
        // If skip authentication is enabled, skip permissions too
        if EnvironmentConfig.skipAuthentication {
            auth.didFinishOnboarding = true
            auth.saveLocalState()
        } else {
            // Show permissions screen
            showingPermissions = true
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo
            VStack(spacing: 16) {
                LogoViewLight(size: .xlarge, showText: false)
                
                Text("Welcome to\nGoFit.Ai")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 16)
            
            Text("Your AI-powered health companion")
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                OnboardingFeatureRow(icon: "camera.fill", text: "Snap meals for instant nutrition analysis")
                OnboardingFeatureRow(icon: "sparkles", text: "Get personalized AI meal & workout plans")
                OnboardingFeatureRow(icon: "applewatch", text: "Sync with Apple Health & Watch")
                OnboardingFeatureRow(icon: "timer", text: "Track intermittent fasting")
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Name Step
struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("What's your name?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to personalize your experience")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter your name", text: $viewModel.name)
                .textFieldStyle(.plain)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                .padding(.horizontal, 32)
                .autocapitalization(.words)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

// MARK: - Goal Step
struct GoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's your goal?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll tailor your plan accordingly")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(OnboardingViewModel.GoalType.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.goal == goal
                    ) {
                        withAnimation(.spring()) {
                            viewModel.goal = goal
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct GoalCard: View {
    let goal: OnboardingViewModel.GoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)
                    .frame(width: 40)
                
                Text(goal.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                }
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(16)
        }
    }
}

// MARK: - Activity Step
struct ActivityStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("How active are you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us calculate your calorie needs")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ForEach(OnboardingViewModel.ActivityLevel.allCases, id: \.self) { level in
                    ActivityCard(
                        level: level,
                        isSelected: viewModel.activityLevel == level
                    ) {
                        withAnimation(.spring()) {
                            viewModel.activityLevel = level
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct ActivityCard: View {
    let level: OnboardingViewModel.ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)

            Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                    }
                }
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.8) : .white.opacity(0.7))
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Dietary Preferences Step
struct DietaryPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Dietary Preferences")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply (optional)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(OnboardingViewModel.DietaryPreference.allCases.filter { $0 != .none }, id: \.self) { pref in
                        DietaryPreferenceCard(
                            preference: pref,
                            isSelected: viewModel.dietaryPreferences.contains(pref)
                        ) {
                            withAnimation(.spring()) {
                                if viewModel.dietaryPreferences.contains(pref) {
                                    viewModel.dietaryPreferences.remove(pref)
                                } else {
                                    viewModel.dietaryPreferences.insert(pref)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct DietaryPreferenceCard: View {
    let preference: OnboardingViewModel.DietaryPreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(preference.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)

                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                }
        }
        .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Allergies Step
struct AllergiesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var allergyText: String = ""
    
    let commonAllergies = ["Peanuts", "Tree Nuts", "Dairy", "Eggs", "Fish", "Shellfish", "Soy", "Wheat", "Gluten"]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
        VStack(spacing: 16) {
                Text("Any Allergies?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll avoid these in your recommendations")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(commonAllergies, id: \.self) { allergy in
                        AllergyCard(
                            allergy: allergy,
                            isSelected: viewModel.allergies.contains(allergy)
                        ) {
                            withAnimation(.spring()) {
                                if viewModel.allergies.contains(allergy) {
                                    viewModel.allergies.remove(allergy)
                                } else {
                                    viewModel.allergies.insert(allergy)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct AllergyCard: View {
    let allergy: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(allergy)
                    .font(.body)
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                }
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Fasting Preference Step
struct FastingPreferenceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Intermittent Fasting?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Choose your preferred fasting window (optional)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(OnboardingViewModel.FastingPreference.allCases, id: \.self) { pref in
                        FastingPreferenceCard(
                            preference: pref,
                            isSelected: viewModel.fastingPreference == pref
                        ) {
                            withAnimation(.spring()) {
                                viewModel.fastingPreference = pref
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct FastingPreferenceCard: View {
    let preference: OnboardingViewModel.FastingPreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preference.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? Color(red: 0.2, green: 0.7, blue: 0.6) : .white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var cameraPermissionGranted = false
    @State private var healthPermissionGranted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                    
                    Text("Enable Permissions")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("We need a few permissions to provide the best experience")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    PermissionCard(
                        icon: "camera.fill",
                        title: "Camera Access",
                        description: "To scan your meals and analyze nutrition",
                        isGranted: cameraPermissionGranted
                    ) {
                        requestCameraPermission()
                    }
                    
                    PermissionCard(
                        icon: "heart.fill",
                        title: "Apple Health",
                        description: "To sync steps, heart rate, and calories",
                        isGranted: healthPermissionGranted
                    ) {
                        requestHealthPermission()
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    viewModel.appleHealthEnabled = healthPermissionGranted
                    auth.didFinishOnboarding = true
                    auth.saveLocalState()
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
        .padding()
                        .background(Color(red: 0.2, green: 0.7, blue: 0.6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func requestCameraPermission() {
        // Camera permission will be requested when user first uses camera
        cameraPermissionGranted = true
    }
    
    private func requestHealthPermission() {
        // HealthKit permission will be requested when user first syncs
        healthPermissionGranted = true
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isGranted ? .green : Color(red: 0.2, green: 0.7, blue: 0.6))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
