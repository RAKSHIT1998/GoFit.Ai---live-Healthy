import SwiftUI

// MARK: - Weight & Height Step
struct WeightHeightStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var weightText: String = ""
    @State private var heightText: String = ""
    @State private var unitSystem: UnitSystem = .metric
    @FocusState private var focusedField: WeightHeightField?
    
    enum WeightHeightField: Hashable {
        case weight
        case height
        case heightFeet
        case heightInches
    }
    
    enum UnitSystem {
        case metric
        case imperial
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                
                Text("Your Body Stats")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Help us personalize your plan")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text(unitSystem == .metric ? "Weight (kg)" : "Weight (lbs)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField(unitSystem == .metric ? "Enter weight in kg" : "Enter weight in lbs", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Design.Colors.cardBackground)
                        .cornerRadius(16)
                        .focused($focusedField, equals: .weight)
                        .onChange(of: weightText) { oldValue, newValue in
                            if let value = Double(newValue) {
                                if unitSystem == .metric {
                                    viewModel.weightKg = value
                                } else {
                                    viewModel.weightKg = value * 0.453592 // Convert lbs to kg
                                }
                            }
                        }
                }
                
                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text(unitSystem == .metric ? "Height (cm)" : "Height (ft/in)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if unitSystem == .metric {
                        TextField("Enter height in cm", text: $heightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(16)
                            .focused($focusedField, equals: .height)
                            .onChange(of: heightText) { oldValue, newValue in
                                if let value = Double(newValue) {
                                    viewModel.heightCm = value
                                }
                            }
                    } else {
                        HStack(spacing: 12) {
                            TextField("Feet", text: Binding(
                                get: { heightText.split(separator: "'").first.map(String.init) ?? "" },
                                set: { newValue in
                                    let parts = heightText.split(separator: "'")
                                    let inches = parts.count > 1 ? String(parts[1].dropLast()) : ""
                                    heightText = "\(newValue)'\(inches)\""
                                    updateHeightFromImperial()
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(16)
                            .focused($focusedField, equals: .heightFeet)
                            
                            Text("'")
                                .font(.title2)
                                .foregroundColor(.primary)
                            
                            TextField("Inches", text: Binding(
                                get: { heightText.split(separator: "'").count > 1 ? String(heightText.split(separator: "'")[1].dropLast()) : "" },
                                set: { newValue in
                                    let parts = heightText.split(separator: "'")
                                    let feet = parts.first.map(String.init) ?? ""
                                    heightText = "\(feet)'\(newValue)\""
                                    updateHeightFromImperial()
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(16)
                            .focused($focusedField, equals: .heightInches)
                            
                            Text("\"")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Unit toggle
                Picker("Unit System", selection: $unitSystem) {
                    Text("Metric (kg/cm)").tag(UnitSystem.metric)
                    Text("Imperial (lbs/ft)").tag(UnitSystem.imperial)
                }
                .pickerStyle(.segmented)
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.top, 40)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(Design.Colors.primary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            focusedField = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            // Initialize text fields with current values
            if viewModel.weightKg > 0 {
                weightText = String(format: "%.1f", viewModel.weightKg)
            }
            if viewModel.heightCm > 0 {
                heightText = String(format: "%.0f", viewModel.heightCm)
            }
        }
    }
    
    private func updateHeightFromImperial() {
        let parts = heightText.split(separator: "'")
        if parts.count >= 2,
           let feetStr = parts.first,
           let feet = Double(String(feetStr)),
           let inchesStr = parts.dropFirst().first {
            let inchesString = String(inchesStr).dropLast()
            if let inches = Double(String(inchesString)) {
                // Convert feet and inches to cm
                let totalInches = (feet * 12) + inches
                viewModel.heightCm = totalInches * 2.54
            }
        }
    }
}

// MARK: - Workout Preferences Step
struct WorkoutPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                
                Text("What Workouts Do You Like?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply (optional)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(OnboardingViewModel.WorkoutType.allCases, id: \.self) { workout in
                        WorkoutPreferenceCard(
                            workout: workout,
                            isSelected: viewModel.workoutPreferences.contains(workout)
                        ) {
                            withAnimation(.spring()) {
                                if viewModel.workoutPreferences.contains(workout) {
                                    viewModel.workoutPreferences.remove(workout)
                                } else {
                                    viewModel.workoutPreferences.insert(workout)
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

struct WorkoutPreferenceCard: View {
    let workout: OnboardingViewModel.WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: workout.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Favorite Cuisines Step
struct FavoriteCuisinesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                
                Text("Favorite Cuisines?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Select all that you enjoy (optional)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(OnboardingViewModel.CuisineType.allCases.filter { $0 != .none }, id: \.self) { cuisine in
                        CuisineCard(
                            cuisine: cuisine,
                            isSelected: viewModel.favoriteCuisines.contains(cuisine)
                        ) {
                            withAnimation(.spring()) {
                                if viewModel.favoriteCuisines.contains(cuisine) {
                                    viewModel.favoriteCuisines.remove(cuisine)
                                } else {
                                    viewModel.favoriteCuisines.insert(cuisine)
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

struct CuisineCard: View {
    let cuisine: OnboardingViewModel.CuisineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(cuisine.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Food Preferences Step
struct FoodPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                
                Text("Food Preferences?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("What types of food do you enjoy? (optional)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(OnboardingViewModel.FoodPreference.allCases, id: \.self) { pref in
                        FoodPreferenceCard(
                            preference: pref,
                            isSelected: viewModel.foodPreferences.contains(pref)
                        ) {
                            withAnimation(.spring()) {
                                if viewModel.foodPreferences.contains(pref) {
                                    viewModel.foodPreferences.remove(pref)
                                } else {
                                    viewModel.foodPreferences.insert(pref)
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

struct FoodPreferenceCard: View {
    let preference: OnboardingViewModel.FoodPreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(preference.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Lifestyle Step
struct LifestyleStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                
                Text("Workout Time & Lifestyle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Help us understand your schedule")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                // Workout time availability
                VStack(alignment: .leading, spacing: 12) {
                    Text("How much time can you dedicate to workouts?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        ForEach(OnboardingViewModel.WorkoutTime.allCases, id: \.self) { time in
                            WorkoutTimeCard(
                                time: time,
                                isSelected: viewModel.workoutTimeAvailability == time
                            ) {
                                withAnimation(.spring()) {
                                    viewModel.workoutTimeAvailability = time
                                }
                            }
                        }
                    }
                }
                
                // Lifestyle factors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lifestyle Factors (optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(OnboardingViewModel.LifestyleFactor.allCases, id: \.self) { factor in
                                LifestyleFactorCard(
                                    factor: factor,
                                    isSelected: viewModel.lifestyleFactors.contains(factor)
                                ) {
                                    withAnimation(.spring()) {
                                        if viewModel.lifestyleFactors.contains(factor) {
                                            viewModel.lifestyleFactors.remove(factor)
                                        } else {
                                            viewModel.lifestyleFactors.insert(factor)
                                        }
                                    }
                                }
                            }
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

struct WorkoutTimeCard: View {
    let time: OnboardingViewModel.WorkoutTime
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(time.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

struct LifestyleFactorCard: View {
    let factor: OnboardingViewModel.LifestyleFactor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(factor.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Combined Cuisines & Food Preferences Step (More Engaging)
struct CuisinesAndFoodPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                    .symbolEffect(.bounce, value: viewModel.favoriteCuisines.count)
                
                Text("What Do You Love to Eat?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Help us create meals you'll actually enjoy")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Favorite Cuisines Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Cuisines")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(OnboardingViewModel.CuisineType.allCases.filter { $0 != .none }, id: \.self) { cuisine in
                                CuisineCard(
                                    cuisine: cuisine,
                                    isSelected: viewModel.favoriteCuisines.contains(cuisine)
                                ) {
                                    withAnimation(.spring()) {
                                        if viewModel.favoriteCuisines.contains(cuisine) {
                                            viewModel.favoriteCuisines.remove(cuisine)
                                        } else {
                                            viewModel.favoriteCuisines.insert(cuisine)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Food Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Food Preferences")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(OnboardingViewModel.FoodPreference.allCases, id: \.self) { pref in
                                FoodPreferenceCard(
                                    preference: pref,
                                    isSelected: viewModel.foodPreferences.contains(pref)
                                ) {
                                    withAnimation(.spring()) {
                                        if viewModel.foodPreferences.contains(pref) {
                                            viewModel.foodPreferences.remove(pref)
                                        } else {
                                            viewModel.foodPreferences.insert(pref)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Combined Lifestyle & Motivation Step (More Engaging)
struct LifestyleAndMotivationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                    .symbolEffect(.pulse, value: viewModel.motivationLevel)
                
                Text("Tell Us About Your Lifestyle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us personalize your experience")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Motivation Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How motivated are you?")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(OnboardingViewModel.MotivationLevel.allCases, id: \.self) { level in
                                MotivationCard(
                                    level: level,
                                    isSelected: viewModel.motivationLevel == level
                                ) {
                                    withAnimation(.spring()) {
                                        viewModel.motivationLevel = level
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Lifestyle Factors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lifestyle Factors (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(OnboardingViewModel.LifestyleFactor.allCases, id: \.self) { factor in
                                LifestyleFactorCard(
                                    factor: factor,
                                    isSelected: viewModel.lifestyleFactors.contains(factor)
                                ) {
                                    withAnimation(.spring()) {
                                        if viewModel.lifestyleFactors.contains(factor) {
                                            viewModel.lifestyleFactors.remove(factor)
                                        } else {
                                            viewModel.lifestyleFactors.insert(factor)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct MotivationCard: View {
    let level: OnboardingViewModel.MotivationLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(level.emoji)
                    .font(.system(size: 32))
                
                Text(level.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Lifestyle Habits Step (Drinking & Smoking)
struct LifestyleHabitsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Design.Colors.primary)
                    .symbolEffect(.pulse, value: viewModel.drinkingFrequency)
                
                Text("Lifestyle Habits")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Help us understand your lifestyle for better recommendations")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Drinking Frequency Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alcohol Consumption")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(OnboardingViewModel.DrinkingFrequency.allCases, id: \.self) { frequency in
                                LifestyleHabitCard(
                                    icon: frequency.icon,
                                    title: frequency.displayName,
                                    isSelected: viewModel.drinkingFrequency == frequency
                                ) {
                                    withAnimation(.spring()) {
                                        viewModel.drinkingFrequency = frequency
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Smoking Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Smoking Status")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(OnboardingViewModel.SmokingStatus.allCases, id: \.self) { status in
                                LifestyleHabitCard(
                                    icon: status.icon,
                                    title: status.displayName,
                                    isSelected: viewModel.smokingStatus == status
                                ) {
                                    withAnimation(.spring()) {
                                        viewModel.smokingStatus = status
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct LifestyleHabitCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                    .frame(width: 40)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Design.Colors.primary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}


// MARK: - Target Weight Step with AI Recommendations
struct TargetWeightStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var targetWeightText: String = ""
    @State private var unitSystem: UnitSystem = .metric
    @State private var isLoading = false
    @State private var recommendations: TargetWeightRecommendations? = nil
    @State private var errorMessage: String? = nil
    @FocusState private var isFocused: Bool
    
    enum UnitSystem {
        case metric
        case imperial
    }
    
    struct TargetWeightRecommendations: Codable {
        let dailyCalories: Int
        let dailyProtein: Int
        let dailyCarbs: Int
        let dailyFat: Int
        let proteinPercent: Int
        let carbsPercent: Int
        let fatPercent: Int
        let message: String
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)
                
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(Design.Colors.primary)
                    
                    Text("Your Target Weight")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tell us your goal weight and we'll calculate your ideal calorie and protein intake")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 24) {
                    // Target Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(unitSystem == .metric ? "Target Weight (kg)" : "Target Weight (lbs)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField(unitSystem == .metric ? "Enter target weight in kg" : "Enter target weight in lbs", text: $targetWeightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(16)
                            .focused($isFocused)
                            .onChange(of: targetWeightText) { oldValue, newValue in
                                if let value = Double(newValue) {
                                    if unitSystem == .metric {
                                        viewModel.targetWeightKg = value
                                    } else {
                                        viewModel.targetWeightKg = value * 0.453592 // Convert lbs to kg
                                    }
                                    // Clear previous recommendations when weight changes
                                    recommendations = nil
                                    errorMessage = nil
                                } else {
                                    viewModel.targetWeightKg = nil
                                }
                            }
                    }
                    
                    // Unit Toggle
                    HStack {
                        Button(action: {
                            unitSystem = .metric
                            updateWeightForUnit()
                        }) {
                            Text("kg")
                                .font(.headline)
                                .foregroundColor(unitSystem == .metric ? Design.Colors.primary : .white.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(unitSystem == .metric ? Design.Colors.cardBackground : Color.clear)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            unitSystem = .imperial
                            updateWeightForUnit()
                        }) {
                            Text("lbs")
                                .font(.headline)
                                .foregroundColor(unitSystem == .imperial ? Design.Colors.primary : .white.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(unitSystem == .imperial ? Design.Colors.cardBackground : Color.clear)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Calculate Button
                    if viewModel.targetWeightKg != nil && viewModel.targetWeightKg! > 0 {
                        Button(action: {
                            calculateRecommendations()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Get AI Recommendations")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Design.Colors.primaryGradient)
                            .cornerRadius(16)
                        }
                        .disabled(isLoading)
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Recommendations Display
                    if let recs = recommendations {
                        VStack(spacing: 20) {
                            Text("Your Personalized Plan")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                // Calories Card
                                RecommendationCard(
                                    icon: "flame.fill",
                                    title: "Daily Calories",
                                    value: "\(recs.dailyCalories)",
                                    unit: "kcal",
                                    color: Design.Colors.calories,
                                    description: "Based on your target weight and activity level"
                                )
                                
                                // Protein Card
                                RecommendationCard(
                                    icon: "figure.strengthtraining.traditional",
                                    title: "Daily Protein",
                                    value: "\(recs.dailyProtein)",
                                    unit: "g",
                                    color: Design.Colors.protein,
                                    description: "\(recs.proteinPercent)% of your daily calories"
                                )
                                
                                // Carbs Card
                                RecommendationCard(
                                    icon: "leaf.fill",
                                    title: "Daily Carbs",
                                    value: "\(recs.dailyCarbs)",
                                    unit: "g",
                                    color: Design.Colors.carbs,
                                    description: "\(recs.carbsPercent)% of your daily calories"
                                )
                                
                                // Fat Card
                                RecommendationCard(
                                    icon: "drop.fill",
                                    title: "Daily Fat",
                                    value: "\(recs.dailyFat)",
                                    unit: "g",
                                    color: Design.Colors.fat,
                                    description: "\(recs.fatPercent)% of your daily calories"
                                )
                            }
                            
                            Text(recs.message)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Design.Colors.cardBackground.opacity(0.5))
                                .cornerRadius(12)
                        }
                        .padding()
                        .background(Design.Colors.cardBackground.opacity(0.3))
                        .cornerRadius(20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }
    }
    
    private func updateWeightForUnit() {
        guard let targetWeight = viewModel.targetWeightKg else { return }
        if unitSystem == .metric {
            targetWeightText = String(format: "%.1f", targetWeight)
        } else {
            let lbs = targetWeight / 0.453592
            targetWeightText = String(format: "%.1f", lbs)
        }
    }
    
    private func calculateRecommendations() {
        guard let targetWeight = viewModel.targetWeightKg,
              targetWeight > 0,
              viewModel.weightKg > 0,
              viewModel.heightCm > 0 else {
            errorMessage = "Please enter your target weight"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let url = URL(string: "\(NetworkManager.shared.baseURL)/onboarding/target-weight-calories")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "weightKg": viewModel.weightKg,
                    "heightCm": viewModel.heightCm,
                    "targetWeightKg": targetWeight,
                    "goal": viewModel.goal.rawValue,
                    "activityLevel": viewModel.activityLevel.rawValue,
                    "dietaryPreferences": Array(viewModel.dietaryPreferences.map { $0.rawValue })
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let recsData = json?["recommendations"] as? [String: Any] else {
                    throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                }
                
                await MainActor.run {
                    recommendations = TargetWeightRecommendations(
                        dailyCalories: recsData["dailyCalories"] as? Int ?? 0,
                        dailyProtein: recsData["dailyProtein"] as? Int ?? 0,
                        dailyCarbs: recsData["dailyCarbs"] as? Int ?? 0,
                        dailyFat: recsData["dailyFat"] as? Int ?? 0,
                        proteinPercent: recsData["proteinPercent"] as? Int ?? 0,
                        carbsPercent: recsData["carbsPercent"] as? Int ?? 0,
                        fatPercent: recsData["fatPercent"] as? Int ?? 0,
                        message: json?["message"] as? String ?? "Here are your personalized recommendations."
                    )
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to calculate recommendations: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(description)
                .font(.caption)
                                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Design.Colors.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
}
