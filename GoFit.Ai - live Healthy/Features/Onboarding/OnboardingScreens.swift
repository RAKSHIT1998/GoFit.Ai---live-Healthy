import SwiftUI

struct OnboardingScreens: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var showingPermissions = false
    @State private var showingSignup = false
    @FocusState private var isKeyboardVisible: Bool
    
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
                
                // Content - 11 Engaging Interactive Screens
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    NameStep(viewModel: viewModel)
                        .tag(1)
                    
                    WeightHeightStep(viewModel: viewModel)
                        .tag(2)
                    
                    GoalStep(viewModel: viewModel)
                        .tag(3)
                    
                    TargetWeightStep(viewModel: viewModel)
                        .tag(4)
                    
                    ActivityStep(viewModel: viewModel)
                        .tag(5)
                    
                    DietaryPreferencesStep(viewModel: viewModel)
                        .tag(6)
                    
                    AllergiesStep(viewModel: viewModel)
                        .tag(7)
                    
                    WorkoutPreferencesStep(viewModel: viewModel)
                        .tag(8)
                    
                    CuisinesAndFoodPreferencesStep(viewModel: viewModel)
                        .tag(9)
                    
                    LifestyleAndMotivationStep(viewModel: viewModel)
                        .tag(10)
                    
                    LifestyleHabitsStep(viewModel: viewModel)
                        .tag(11)
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
                        // Dismiss keyboard when moving to next step
                        isKeyboardVisible = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
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
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isKeyboardVisible = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            // Dismiss keyboard when step changes
            isKeyboardVisible = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showingPermissions) {
            PermissionsView(viewModel: viewModel, onComplete: {
                showingPermissions = false
                showingSignup = true
            })
        }
        .sheet(isPresented: $showingSignup) {
            OnboardingSignupView(viewModel: viewModel)
                .environmentObject(auth)
                .presentationDetents([.large]) // Ensure full screen on iPad
                .presentationDragIndicator(.visible)
                .onAppear {
                    // Clear any test/default names from saved state
                    auth.clearTestData()
                    
                    // Clear "rakshit" from viewModel.name if present
                    if viewModel.name.lowercased() == "rakshit" {
                        viewModel.name = ""
                    }
                    
                    // Debug: Log the name state when signup view appears
                    print("📱 OnboardingSignupView appeared")
                    print("📱 viewModel.name: '\(viewModel.name)'")
                    print("📱 auth.name: '\(auth.name)'")
                    print("📱 auth.onboardingData?.name: '\(auth.onboardingData?.name ?? "nil")'")
                }
        }
    }
    
    private func completeOnboarding() {
        // Save all onboarding data to auth view model
        // Only update auth.name if viewModel.name is not empty (don't overwrite with empty)
        if !viewModel.name.isEmpty {
            auth.name = viewModel.name
            print("✅ Setting auth.name from onboarding: '\(viewModel.name)'")
        } else {
            print("⚠️ viewModel.name is empty, keeping existing auth.name: '\(auth.name)'")
        }
        auth.goal = viewModel.goal.rawValue
        auth.dietPrefs = viewModel.dietaryPreferences.map { $0.rawValue }
        auth.weightKg = viewModel.weightKg > 0 ? viewModel.weightKg : 70
        auth.heightCm = viewModel.heightCm > 0 ? viewModel.heightCm : 170
        
        // Store comprehensive onboarding data for signup
        auth.onboardingData = OnboardingData(
            name: viewModel.name.isEmpty ? auth.name : viewModel.name,
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
            motivationLevel: viewModel.motivationLevel.rawValue,
            drinkingFrequency: viewModel.drinkingFrequency.rawValue,
            smokingStatus: viewModel.smokingStatus.rawValue
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
                    icon: "applewatch",
                    text: "Sync with Apple Health & Watch",
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
    @FocusState private var isNameFocused: Bool
    
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
                .focused($isNameFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isNameFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .foregroundColor(Design.Colors.primary)
                    }
                }
            
            Spacer()
        }
        .padding(.top, 60)
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isNameFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
    let onComplete: () -> Void
    
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
                    dismiss()
                    onComplete() // Show signup screen
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
                healthKit.checkAuthorizationStatus()
                healthPermissionGranted = healthKit.isAuthorized
                print("📱 PermissionsView appeared - HealthKit authorized: \(healthKit.isAuthorized)")
            }
        }
    }
    
    private func requestCameraPermission() {
        // Camera permission will be requested when user first uses camera
        cameraPermissionGranted = true
    }
    
    private func requestHealthPermission() {
        // Check if already authorized before requesting
        healthKit.checkAuthorizationStatus()
        if healthKit.isAuthorized {
            print("✅ HealthKit already authorized, skipping request")
            healthPermissionGranted = true
            viewModel.appleHealthEnabled = true
            return
        }
        
        isRequestingHealth = true
        Task {
            do {
                // Actually request HealthKit authorization
                print("🔵 Requesting HealthKit authorization from PermissionsView...")
                try await HealthKitService.shared.requestAuthorization()
                // Re-check status after requesting (with a small delay to ensure status is updated)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    healthKit.checkAuthorizationStatus()
                    // Update the UI to reflect authorization status
                    healthPermissionGranted = healthKit.isAuthorized
                    viewModel.appleHealthEnabled = healthPermissionGranted
                    isRequestingHealth = false
                    print("📱 HealthKit permission request completed - authorized: \(healthKit.isAuthorized)")
                    
                    // If authorized and user is logged in (or will be after signup), start periodic sync
                    if healthKit.isAuthorized {
                        print("🔄 Starting HealthKit periodic sync after permission grant...")
                        healthKit.startPeriodicSync()
                        
                        // Also sync immediately to backend if user is logged in
                        if AuthService.shared.readToken() != nil {
                            Task {
                                do {
                                    try await healthKit.syncToBackend()
                                    print("✅ HealthKit synced to backend immediately after permission grant")
                                } catch {
                                    print("⚠️ HealthKit sync to backend failed: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            print("ℹ️ User not logged in yet - sync will start after login")
                        }
                    }
                }
            } catch {
                print("⚠️ Failed to request HealthKit authorization: \(error.localizedDescription)")
                await MainActor.run {
                    // Re-check status even on error (user might have granted in system dialog)
                    healthKit.checkAuthorizationStatus()
                    healthPermissionGranted = healthKit.isAuthorized
                    isRequestingHealth = false
                    print("📱 HealthKit permission request failed - final status: authorized=\(healthKit.isAuthorized)")
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

// MARK: - Onboarding Signup View (Integrated into onboarding flow)
struct OnboardingSignupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var purchases = PurchaseManager()
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    
    // Focus state for keyboard management
    @FocusState private var focusedField: SignupField?
    
    enum SignupField: Hashable {
        case name
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Design.Spacing.xl) {
                            Spacer(minLength: 40)
                            
                            // Logo and title
                            VStack(spacing: Design.Spacing.md) {
                                LogoView(size: .large, showText: false, color: Design.Colors.primary)
                                    .padding(.top, Design.Spacing.xl)
                                
                                Text("Create Your Account")
                                    .font(Design.Typography.display)
                                    .foregroundColor(.primary)
                                
                                Text("Almost there! Just create your account to get started")
                                    .font(Design.Typography.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Form Card with iPad width constraint
                            ModernCard {
                                VStack(spacing: Design.Spacing.md) {
                                    // Name (editable - user can change it)
                                    CustomTextField(
                                        placeholder: "Full Name",
                                        text: Binding(
                                            get: { 
                                                // Use viewModel.name if available, otherwise empty
                                                // Clear any "rakshit" default
                                                let name = viewModel.name.isEmpty ? "" : viewModel.name
                                                return name.lowercased() == "rakshit" ? "" : name
                                            },
                                            set: { 
                                                // Update viewModel.name when user types
                                                viewModel.name = $0
                                            }
                                        ),
                                        icon: "person.fill"
                                    )
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .email
                                        withAnimation {
                                            proxy.scrollTo("email", anchor: .center)
                                        }
                                    }
                                    .id("name")
                                    .autocapitalization(.words)
                                    
                                    CustomTextField(
                                        placeholder: "Email",
                                        text: $email,
                                        icon: "envelope.fill",
                                        keyboardType: .emailAddress
                                    )
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                        withAnimation {
                                            proxy.scrollTo("password", anchor: .center)
                                        }
                                    }
                                    .id("email")
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    
                                    CustomSecureField(
                                        placeholder: "Password",
                                        text: $password,
                                        icon: "lock.fill"
                                    )
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .confirmPassword
                                        withAnimation {
                                            proxy.scrollTo("confirmPassword", anchor: .center)
                                        }
                                    }
                                    .id("password")
                                    
                                    CustomSecureField(
                                        placeholder: "Confirm Password",
                                        text: $confirmPassword,
                                        icon: "lock.fill"
                                    )
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                        if isFormValid {
                                            handleSignup()
                                        }
                                    }
                                    .id("confirmPassword")
                                }
                            }
                            .padding(.horizontal, Design.Spacing.md)
                            .frame(maxWidth: 600) // Limit width on iPad for better layout
                            
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
                            
                            // Signup button
                            Button(action: handleSignup) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                }
                            }
                            .buttonStyle(ModernButtonStyle())
                            .disabled(isLoading || !isFormValid)
                            .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                            .padding(.horizontal, Design.Spacing.md)
                            
                            Spacer(minLength: 40)
                        }
                    }
                    .onChange(of: focusedField) { oldValue, newValue in
                        if let field = newValue {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(field == .email ? "email" : field == .password ? "password" : "confirmPassword", anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 600) // Limit width on iPad for better layout
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                focusedField = nil
            }
            .onAppear {
                // Clear any test/default names from saved state
                auth.clearTestData()
                
                // Clear "rakshit" from viewModel.name if present
                if viewModel.name.lowercased() == "rakshit" {
                    viewModel.name = ""
                }
                
                // Debug: Log the name state when signup view appears
                print("📱 OnboardingSignupView appeared")
                print("📱 viewModel.name: '\(viewModel.name)'")
                print("📱 auth.name: '\(auth.name)'")
                print("📱 auth.onboardingData?.name: '\(auth.onboardingData?.name ?? "nil")'")
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(purchases)
                .presentationDetents([.large]) // Ensure full screen on iPad
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false) // Allow dismissing paywall (not blocking for new signups)
                .onDisappear {
                    // After paywall dismisses, dismiss signup view
                    // RootView will automatically show MainTabView since auth.isLoggedIn is true
                    if auth.isLoggedIn {
                        dismiss()
                    }
                }
        }
        .onChange(of: auth.isLoggedIn) { oldValue, newValue in
            if newValue && !showingPaywall {
                // Initialize trial for new user
                purchases.initializeTrialForNewUser()
                
                // Show paywall after signup (if not already showing)
                // Small delay to ensure state is properly updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingPaywall = true
                }
                
                // Mark onboarding as complete
                auth.didFinishOnboarding = true
                auth.saveLocalState()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && password.count >= 8 &&
        Validators.isValidEmail(email)
    }
    
    private func handleSignup() {
        // Prevent duplicate signup attempts
        guard !isLoading else {
            print("⚠️ Signup already in progress, ignoring duplicate request")
            return
        }
        
        errorMessage = nil
        
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        
        // Ensure onboarding data is set before signup
        // It should already be set from completeOnboarding, but set it again to be safe
        if auth.onboardingData == nil {
            auth.onboardingData = OnboardingData(
                name: viewModel.name.isEmpty ? "User" : viewModel.name,
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
                motivationLevel: viewModel.motivationLevel.rawValue,
                drinkingFrequency: viewModel.drinkingFrequency.rawValue,
                smokingStatus: viewModel.smokingStatus.rawValue
            )
        }
        
        Task {
            do {
                // Get the name from onboarding - prioritize viewModel.name, then auth.name, never use "rakshit" or defaults
                let signupName: String
                if !viewModel.name.isEmpty {
                    signupName = viewModel.name
                } else if !auth.name.isEmpty && auth.name.lowercased() != "rakshit" {
                    signupName = auth.name
                } else if let onboardingName = auth.onboardingData?.name, 
                          !onboardingName.isEmpty && 
                          onboardingName.lowercased() != "rakshit" {
                    signupName = onboardingName
                } else {
                    signupName = "User"
                }
                
                print("🔵 Starting signup from OnboardingSignupView...")
                print("🔵 Name being used: '\(signupName)'")
                print("🔵 viewModel.name: '\(viewModel.name)'")
                print("🔵 auth.name: '\(auth.name)'")
                print("🔵 auth.onboardingData?.name: '\(auth.onboardingData?.name ?? "nil")'")
                print("🔵 Email: \(email.trimmingCharacters(in: .whitespacesAndNewlines))")
                print("🔵 Onboarding data available: \(auth.onboardingData != nil ? "Yes" : "No")")
                
                try await auth.signup(
                    name: signupName,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                print("✅ Signup successful from OnboardingSignupView")
                
                // Mark onboarding as complete first
                await MainActor.run {
                    isLoading = false // Reset loading state after successful signup
                    auth.didFinishOnboarding = true
                    auth.saveLocalState()
                    
                    // Initialize trial for new user after successful signup
                    purchases.initializeTrialForNewUser()
                    
                    // Small delay to ensure state is updated before showing paywall
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingPaywall = true
                    }
                }
            } catch {
                print("❌ Signup failed in OnboardingSignupView: \(error.localizedDescription)")
                print("❌ Error type: \(type(of: error))")
                if let urlError = error as? URLError {
                    print("❌ URLError code: \(urlError.code.rawValue)")
                    print("❌ URLError description: \(urlError.localizedDescription)")
                }
                await MainActor.run {
                    isLoading = false
                    if let nsError = error as NSError? {
                        let errorMsg = nsError.localizedDescription
                        
                        // Check for rate limiting errors
                        if nsError.code == 429 || errorMsg.contains("too many") || errorMsg.contains("Too many") || errorMsg.contains("rate limit") {
                            errorMessage = "Too many requests. Please wait a few minutes and try again."
                        } else {
                            errorMessage = errorMsg.isEmpty ? "Failed to create account. Please check your connection and try again." : errorMsg
                        }
                        print("❌ Error details: code=\(nsError.code), domain=\(nsError.domain), userInfo=\(nsError.userInfo)")
                    } else if let urlError = error as? URLError {
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
                    } else {
                        let errorDesc = error.localizedDescription
                        if errorDesc.contains("too many") || errorDesc.contains("Too many") || errorDesc.contains("rate limit") {
                            errorMessage = "Too many requests. Please wait a few minutes and try again."
                        } else {
                            errorMessage = "Failed to create account: \(errorDesc)"
                        }
                    }
                }
            }
        }
    }
}
