import SwiftUI

struct WorkoutPreferenceSettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPreferences: Set<WorkoutPreferenceType> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    enum WorkoutPreferenceType: String, CaseIterable, Identifiable {
        case gym = "Gym"
        case yoga = "Yoga"
        case cardio = "Cardio"
        case strength = "Strength Training"
        case hiit = "HIIT"
        case functional = "Functional Training"
        case pilates = "Pilates"
        case crossfit = "CrossFit"
        case bodyweight = "Bodyweight"
        case sports = "Sports"
        case running = "Running"
        case cycling = "Cycling"
        case swimming = "Swimming"
        case dancing = "Dancing"
        case martial_arts = "Martial Arts"
        case outdoor = "Outdoor Activities"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .gym: return "figure.strengthtraining.traditional"
            case .yoga: return "figure.yoga"
            case .cardio: return "heart.fill"
            case .strength: return "dumbbell.fill"
            case .hiit: return "flame.fill"
            case .functional: return "figure.core.training"
            case .pilates: return "figure.pilates"
            case .crossfit: return "figure.mixed.cardio"
            case .bodyweight: return "figure.walk"
            case .sports: return "sportscourt.fill"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .dancing: return "music.note"
            case .martial_arts: return "figure.kickboxing"
            case .outdoor: return "tree.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .gym, .strength: return .orange
            case .yoga, .pilates: return .purple
            case .cardio, .running: return .red
            case .hiit: return .pink
            case .functional, .crossfit: return .blue
            case .bodyweight: return .green
            case .sports, .outdoor: return .teal
            case .cycling: return .indigo
            case .swimming: return .cyan
            case .dancing: return .pink
            case .martial_arts: return .red
            }
        }
        
        var description: String {
            switch self {
            case .gym: return "Weight training and gym equipment workouts"
            case .yoga: return "Flexibility, balance, and mindfulness"
            case .cardio: return "Heart-pumping endurance exercises"
            case .strength: return "Build muscle and increase strength"
            case .hiit: return "High-intensity interval training"
            case .functional: return "Movement-based practical exercises"
            case .pilates: return "Core strength and flexibility"
            case .crossfit: return "Varied high-intensity functional movements"
            case .bodyweight: return "No equipment needed, use your body weight"
            case .sports: return "Team or individual sports activities"
            case .running: return "Outdoor or treadmill running"
            case .cycling: return "Bike workouts indoor or outdoor"
            case .swimming: return "Pool-based cardio and strength"
            case .dancing: return "Dance-based fitness"
            case .martial_arts: return "Combat sports and martial arts"
            case .outdoor: return "Hiking, climbing, outdoor adventures"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Choose Your Workout Style")
                            .font(Design.Typography.title)
                            .fontWeight(.bold)
                        
                        Text("Select your preferred workout types to get personalized recommendations tailored to your interests")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.top, Design.Spacing.md)
                    
                    // Success Message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Preferences updated successfully!")
                                .font(Design.Typography.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal, Design.Spacing.md)
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(Design.Typography.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal, Design.Spacing.md)
                    }
                    
                    // Selection Count
                    if !selectedPreferences.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Design.Colors.primary)
                            Text("\(selectedPreferences.count) workout \(selectedPreferences.count == 1 ? "type" : "types") selected")
                                .font(Design.Typography.body)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, Design.Spacing.md)
                    }
                    
                    // Workout Preferences Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Design.Spacing.md) {
                        ForEach(WorkoutPreferenceType.allCases) { preference in
                            WorkoutPreferenceCard(
                                preference: preference,
                                isSelected: selectedPreferences.contains(preference),
                                action: {
                                    toggleSelection(preference)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Design.Spacing.md)
                }
                .padding(.bottom, 100) // Space for bottom button
            }
            .background(Design.Colors.background)
            .navigationTitle("Workout Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        Task {
                            await savePreferences()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Preferences")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPreferences.isEmpty ? Color.gray : Design.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(Design.Radius.large)
                        .shadow(radius: 4)
                    }
                    .disabled(isLoading || selectedPreferences.isEmpty)
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.bottom, Design.Spacing.md)
                }
            )
            .onAppear {
                loadCurrentPreferences()
            }
        }
    }
    
    private func toggleSelection(_ preference: WorkoutPreferenceType) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }
    
    private func loadCurrentPreferences() {
        // Load from LocalUserStore
        if let profile = LocalUserStore.shared.getProfile() {
            let currentPrefs = profile.workoutPreferences
            selectedPreferences = Set(currentPrefs.compactMap { pref in
                WorkoutPreferenceType.allCases.first { $0.rawValue.lowercased() == pref.lowercased() }
            })
        }
    }
    
    private func savePreferences() async {
        isLoading = true
        errorMessage = nil
        showSuccess = false
        
        do {
            let preferencesArray = Array(selectedPreferences).map { $0.rawValue }
            
            // Update LocalUserStore to persist preferences
            LocalUserStore.shared.updateGoals(workoutPreferences: preferencesArray)
            
            // Update backend
            guard let token = AuthService.shared.readToken()?.accessToken else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            }
            
            let url = NetworkManager.shared.baseURL.appendingPathComponent("auth/profile")
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "workoutPreferences": preferencesArray
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            if httpResponse.statusCode == 200 {
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            } else {
                let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse?["message"] ?? "Failed to update preferences"])
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Workout Preference Card
struct WorkoutPreferenceCard: View {
    let preference: WorkoutPreferenceSettingsView.WorkoutPreferenceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? preference.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: preference.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? preference.color : .gray)
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(preference.color, lineWidth: 3)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(preference.color)
                            .offset(x: 20, y: -20)
                    }
                }
                
                Text(preference.rawValue)
                    .font(Design.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.medium)
                    .fill(isSelected ? preference.color.opacity(0.05) : Design.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.medium)
                    .strokeBorder(isSelected ? preference.color.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkoutPreferenceSettingsView()
        .environmentObject(AuthViewModel())
}
