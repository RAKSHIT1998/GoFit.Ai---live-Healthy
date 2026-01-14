import SwiftUI

struct TargetSettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 170
    @State private var targetWeightKg: Double?
    @State private var targetCalories: Double?
    @State private var targetProtein: Double?
    @State private var targetCarbs: Double?
    @State private var targetFat: Double?
    @State private var liquidIntakeGoal: Double = 2.5
    @State private var goal: String = "maintain"
    @State private var activityLevel: String = "moderate"
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    
    let goals = ["lose", "maintain", "gain"]
    let activityLevels = ["sedentary", "light", "moderate", "active", "very_active"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Design.Spacing.xl) {
                        // Weight and Height
                        ModernCard {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Body Metrics")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: Design.Spacing.md) {
                                    HStack {
                                        Text("Current Weight")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("kg", value: $weightKg, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("kg")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Height")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("cm", value: $heightCm, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("cm")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Target Weight")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("kg", value: $targetWeightKg, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("kg")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(Design.Spacing.md)
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        
                        // Goals
                        ModernCard {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Fitness Goal")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Goal", selection: $goal) {
                                    ForEach(goals, id: \.self) { goalOption in
                                        Text(goalOption.capitalized).tag(goalOption)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                Text("Activity Level")
                                    .font(Design.Typography.body)
                                    .padding(.top, Design.Spacing.sm)
                                
                                Picker("Activity Level", selection: $activityLevel) {
                                    ForEach(activityLevels, id: \.self) { level in
                                        Text(level.replacingOccurrences(of: "_", with: " ").capitalized).tag(level)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(Design.Spacing.md)
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        
                        // Nutrition Targets
                        ModernCard {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Nutrition Targets")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: Design.Spacing.md) {
                                    HStack {
                                        Text("Target Calories")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("kcal", value: $targetCalories, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("kcal")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Target Protein")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("g", value: $targetProtein, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("g")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Target Carbs")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("g", value: $targetCarbs, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("g")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("Target Fat")
                                            .font(Design.Typography.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("g", value: $targetFat, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .background(Design.Colors.secondaryBackground)
                                            .frame(width: 100)
                                        Text("g")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Button(action: {
                                    // Recalculate targets based on weight, height, goal, and activity level
                                    recalculateTargets()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Recalculate Targets")
                                    }
                                    .font(Design.Typography.body)
                                    .foregroundColor(Design.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Design.Spacing.sm)
                                    .background(Design.Colors.primary.opacity(0.1))
                                    .cornerRadius(Design.Radius.medium)
                                }
                                .padding(.top, Design.Spacing.sm)
                            }
                            .padding(Design.Spacing.md)
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        
                        // Liquid Intake Goal
                        ModernCard {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Daily Liquid Intake Goal")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("Target Liquid Intake")
                                        .font(Design.Typography.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("L", value: $liquidIntakeGoal, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .background(Design.Colors.secondaryBackground)
                                        .frame(width: 100)
                                    Text("L")
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Set your daily water/liquid intake goal. The default is 2.5L per day.")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, Design.Spacing.xs)
                            }
                            .padding(Design.Spacing.md)
                        }
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
                        .background(Design.Colors.secondaryBackground)
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal, Design.Spacing.md)
                        }
                        
                        // Save button
                        Button(action: saveTargets) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if !isLoading {
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
                            .shadow(color: Design.Colors.primary.opacity(isLoading ? 0 : 0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, Design.Spacing.md)
                        .padding(.bottom, Design.Spacing.xl)
                    }
                    .padding(.top, Design.Spacing.md)
                }
            }
            .navigationTitle("Goals & Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .onAppear {
                loadCurrentTargets()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your targets have been updated successfully!")
            }
        }
    }
    
    private func loadCurrentTargets() {
        weightKg = auth.weightKg
        heightCm = auth.heightCm
        goal = auth.goal
        
        // Load from backend if available
        Task {
            do {
                let response: [String: Any] = try await NetworkManager.shared.requestDictionary("auth/me", method: "GET", body: nil)
                await MainActor.run {
                    if let metrics = response["metrics"] as? [String: Any] {
                        if let w = metrics["weightKg"] as? Double {
                            weightKg = w
                        }
                        if let h = metrics["heightCm"] as? Double {
                            heightCm = h
                        }
                        if let tw = metrics["targetWeightKg"] as? Double {
                            targetWeightKg = tw
                        }
                        if let tc = metrics["targetCalories"] as? Double {
                            targetCalories = tc
                        }
                        if let tp = metrics["targetProtein"] as? Double {
                            targetProtein = tp
                        }
                        if let tcarbs = metrics["targetCarbs"] as? Double {
                            targetCarbs = tcarbs
                        }
                    if let tf = metrics["targetFat"] as? Double {
                        targetFat = tf
                    }
                    if let liquid = metrics["liquidIntakeGoal"] as? Double {
                        liquidIntakeGoal = liquid
                    }
                }
                if let activity = response["activityLevel"] as? String {
                    activityLevel = activity
                }
                }
            } catch {
                print("⚠️ Failed to load targets: \(error.localizedDescription)")
            }
        }
    }
    
    private func recalculateTargets() {
        // This would typically call the backend to recalculate based on weight, height, goal, activity level
        // For now, we'll just save and let the backend recalculate
        saveTargets()
    }
    
    private func saveTargets() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let body: [String: Any?] = [
                    "weightKg": weightKg,
                    "heightCm": heightCm,
                    "targetWeightKg": targetWeightKg,
                    "targetCalories": targetCalories,
                    "targetProtein": targetProtein,
                    "targetCarbs": targetCarbs,
                    "targetFat": targetFat,
                    "liquidIntakeGoal": liquidIntakeGoal,
                    "goals": goal,
                    "activityLevel": activityLevel
                ]
                
                // Remove nil values and convert to non-optional dictionary
                let cleanBody = body.compactMapValues { $0 }
                
                // Encode body to Data
                let bodyData = try JSONSerialization.data(withJSONObject: cleanBody, options: [])
                
                let _: [String: Any] = try await NetworkManager.shared.requestDictionary(
                    "auth/targets",
                    method: "PUT",
                    body: bodyData
                )
                
                await MainActor.run {
                    // Update local auth state
                    auth.weightKg = weightKg
                    auth.heightCm = heightCm
                    auth.goal = goal
                    auth.saveLocalState()
                    
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let nsError = error as NSError? {
                        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showingError = true
                }
            }
        }
    }
}

