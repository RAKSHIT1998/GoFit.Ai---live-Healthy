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
                    .foregroundColor(.white)
                
                Text("Your Body Stats")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us personalize your plan")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text(unitSystem == .metric ? "Weight (kg)" : "Weight (lbs)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(unitSystem == .metric ? "Enter weight in kg" : "Enter weight in lbs", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.2))
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
                        .foregroundColor(.white)
                    
                    if unitSystem == .metric {
                        TextField("Enter height in cm", text: $heightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
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
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                            .focused($focusedField, equals: .heightFeet)
                            
                            Text("'")
                                .font(.title2)
                                .foregroundColor(.white)
                            
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
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                            .focused($focusedField, equals: .heightInches)
                            
                            Text("\"")
                                .font(.title2)
                                .foregroundColor(.white)
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
                    .foregroundColor(.white)
                
                Text("What Workouts Do You Like?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply (optional)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
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
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                    .foregroundColor(.white)
                
                Text("Favorite Cuisines?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select all that you enjoy (optional)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
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
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
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

// MARK: - Food Preferences Step
struct FoodPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Food Preferences?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("What types of food do you enjoy? (optional)")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
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
                .foregroundColor(isSelected ? Design.Colors.primary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                    .foregroundColor(.white)
                
                Text("Workout Time & Lifestyle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us understand your schedule")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                // Workout time availability
                VStack(alignment: .leading, spacing: 12) {
                    Text("How much time can you dedicate to workouts?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.white)
                    
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
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
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

struct LifestyleFactorCard: View {
    let factor: OnboardingViewModel.LifestyleFactor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(factor.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
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

// MARK: - Combined Cuisines & Food Preferences Step (More Engaging)
struct CuisinesAndFoodPreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: viewModel.favoriteCuisines.count)
                
                Text("What Do You Love to Eat?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us create meals you'll actually enjoy")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Favorite Cuisines Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Cuisines")
                            .font(.headline)
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
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
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, value: viewModel.motivationLevel)
                
                Text("Tell Us About Your Lifestyle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us personalize your experience")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Motivation Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How motivated are you?")
                            .font(.headline)
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
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
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
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
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, value: viewModel.drinkingFrequency)
                
                Text("Lifestyle Habits")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Help us understand your lifestyle for better recommendations")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Drinking Frequency Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alcohol Consumption")
                            .font(.headline)
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
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
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                    .frame(width: 40)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Design.Colors.primary : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .padding()
            .background(isSelected ? Design.Colors.cardBackground : Design.Colors.cardBackground.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

