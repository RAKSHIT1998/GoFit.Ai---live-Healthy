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
                    .progressViewStyle(LinearProgressViewStyle(tint: Design.Colors.primary))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Content - 10 Engaging Interactive Screens
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    NameStep(viewModel: viewModel)
                        .tag(1)
                    
                    WeightHeightStep(viewModel: viewModel)
                        .tag(2)
                    
                    GoalStep(viewModel: viewModel)
                        .tag(3)
                    
                    ActivityStep(viewModel: viewModel)
                        .tag(4)
                    
                    DietaryPreferencesStep(viewModel: viewModel)
                        .tag(5)
                    
                    AllergiesStep(viewModel: viewModel)
                        .tag(6)
                    
                    WorkoutPreferencesStep(viewModel: viewModel)
                        .tag(7)
                    
                    CuisinesAndFoodPreferencesStep(viewModel: viewModel)
                        .tag(8)
                    
                    LifestyleAndMotivationStep(viewModel: viewModel)
                        .tag(9)
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
                        .foregroundColor(Design.Colors.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Design.Colors.cardBackground)
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
        // Save all onboarding data to auth view model
        auth.name = viewModel.name.isEmpty ? "User" : viewModel.name
        auth.goal = viewModel.goal.rawValue
        auth.dietPrefs = viewModel.dietaryPreferences.map { $0.rawValue }
        auth.weightKg = viewModel.weightKg > 0 ? viewModel.weightKg : 70
        auth.heightCm = viewModel.heightCm > 0 ? viewModel.heightCm : 170
        
        // Store comprehensive onboarding data for signup
        auth.onboardingData = OnboardingData(
            name: viewModel.name,
            weightKg: viewModel.weightKg,
            heightCm: viewModel.heightCm,
            goal: viewModel.goal.rawValue,
            activityLevel: viewModel.activityLevel.rawValue,
            dietaryPreferences: viewModel.dietaryPreferences.map { $0.rawValue },
            allergies: Array(viewModel.allergies),
            fastingPreference: viewModel.fastingPreference.rawValue,
            workoutPreferences: viewModel.workoutPreferences.map { $0.rawValue },
            favoriteCuisines: viewModel.favoriteCuisines.map { $0.rawValue },
            foodPreferences: viewModel.foodPreferences.map { $0.rawValue },
            workoutTimeAvailability: viewModel.workoutTimeAvailability.rawValue,
            lifestyleFactors: viewModel.lifestyleFactors.map { $0.rawValue },
            favoriteFoods: viewModel.favoriteFoods,
            mealTimingPreference: viewModel.mealTimingPreference.rawValue,
            cookingSkill: viewModel.cookingSkill.rawValue,
            budgetPreference: viewModel.budgetPreference.rawValue,
            motivationLevel: viewModel.motivationLevel.rawValue
        )
        
        // If skip authentication is enabled, skip permissions too
        if EnvironmentConfig.skipAuthentication {
            auth.didFinishOnboarding = true
            auth.saveLocalState()
        } else {
            // Show permissions screen, then signup
            showingPermissions = true
        }
    }
}

// MARK: - Welcome Step (Enhanced & More Engaging)
struct WelcomeStep: View {
    @State private var animateFeatures = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo with animation
            VStack(spacing: 20) {
                LogoViewLight(size: .xlarge, showText: false)
                    .scaleEffect(animateFeatures ? 1.0 : 0.8)
                    .opacity(animateFeatures ? 1.0 : 0.0)
                
                Text("Welcome to\nGoFit.Ai")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateFeatures ? 1.0 : 0.0)
            }
            .padding(.bottom, 24)
            
            Text("Your AI-powered health companion")
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .opacity(animateFeatures ? 1.0 : 0.0)
            
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeatureRow(
                    icon: "camera.fill",
                    text: "Snap meals for instant nutrition analysis",
                    delay: 0.1
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -20)
                
                OnboardingFeatureRow(
                    icon: "sparkles",
                    text: "Get personalized AI meal & workout plans",
                    delay: 0.2
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -20)
                
                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    text: "Track your progress and goals",
                    delay: 0.3
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -20)
                
                OnboardingFeatureRow(
                    icon: "timer",
                    text: "Track intermittent fasting",
                    delay: 0.4
                )
                .opacity(animateFeatures ? 1.0 : 0.0)
                .offset(x: animateFeatures ? 0 : -20)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateFeatures = true
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let text: String
    var delay: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Design.Colors.primary)
                .frame(width: 40)
                .symbolEffect(.pulse, value: delay)
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding()
        .background(Design.Colors.cardBackground.opacity(0.3))
        .cornerRadius(16)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: delay)
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
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                        .foregroundColor(isSelected ? Design.Colors.primary : .white)

            Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Design.Colors.primary)
                    }
                }
                
                Text(level.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? Design.Colors.primary.opacity(0.8) : .white.opacity(0.7))
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                        .foregroundColor(Design.Colors.primary)
                }
        }
        .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                        .foregroundColor(isSelected ? Design.Colors.primary : .white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var healthKit = HealthKitService.shared
    @State private var cameraPermissionGranted = false
    @State private var healthPermissionGranted = false
    @State private var isRequestingHealth = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Design.Colors.primary)
                    
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
                        isGranted: healthKit.isAuthorized || healthPermissionGranted
                    ) {
                        if !isRequestingHealth {
                            requestHealthPermission()
                        }
                    }
                    .overlay(
                        Group {
                            if isRequestingHealth {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    viewModel.appleHealthEnabled = healthKit.isAuthorized || healthPermissionGranted
                    auth.didFinishOnboarding = true
                    auth.saveLocalState()
                    dismiss()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
        .padding()
                        .background(Design.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check current authorization status when view appears
            healthPermissionGranted = healthKit.isAuthorized
        }
    }
    }
    
    private func requestCameraPermission() {
        // Camera permission will be requested when user first uses camera
        cameraPermissionGranted = true
    }
    
    private func requestHealthPermission() {
        isRequestingHealth = true
        Task {
            do {
                // Actually request HealthKit authorization
                try await HealthKitService.shared.requestAuthorization()
                await MainActor.run {
                    // Update the UI to reflect authorization status
                    healthPermissionGranted = HealthKitService.shared.isAuthorized
                    viewModel.appleHealthEnabled = healthPermissionGranted
                    isRequestingHealth = false
                }
            } catch {
                print("⚠️ Failed to request HealthKit authorization: \(error.localizedDescription)")
                await MainActor.run {
                    healthPermissionGranted = false
                    isRequestingHealth = false
                }
            }
        }
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
                    .foregroundColor(isGranted ? .green : Design.Colors.primary)
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
