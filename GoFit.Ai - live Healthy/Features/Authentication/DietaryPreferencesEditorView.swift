import SwiftUI

struct DietaryPreferencesEditorView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPreferences: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    // Dietary preference options
    private let preferences: [(value: String, displayName: String)] = [
        ("vegan", "Vegan"),
        ("vegetarian", "Vegetarian"),
        ("keto", "Keto"),
        ("paleo", "Paleo"),
        ("mediterranean", "Mediterranean"),
        ("low_carb", "Low Carb")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Design.Spacing.lg) {
                    // Header
                    VStack(spacing: Design.Spacing.sm) {
                        Text("Dietary Preferences")
                            .font(Design.Typography.largeTitle)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Select all that apply. Your meal recommendations will update based on your preferences.")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, Design.Spacing.lg)
                    
                    // Preference options
                    VStack(spacing: Design.Spacing.md) {
                        ForEach(preferences, id: \.value) { pref in
                            DietaryPreferenceRow(
                                displayName: pref.displayName,
                                isSelected: selectedPreferences.contains(pref.value)
                            ) {
                                withAnimation(.spring()) {
                                    if selectedPreferences.contains(pref.value) {
                                        selectedPreferences.remove(pref.value)
                                    } else {
                                        selectedPreferences.insert(pref.value)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Design.Spacing.lg)
                    
                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Preferences updated! Meal recommendations will refresh.")
                                .font(Design.Typography.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if let errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(Design.Typography.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .background(Design.Colors.background)
            .navigationTitle("Dietary Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await savePreferences()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                // Initialize with current preferences
                selectedPreferences = Set(auth.dietPrefs)
            }
        }
    }
    
    private func savePreferences() async {
        isLoading = true
        errorMessage = nil
        showSuccess = false
        
        do {
            // Update local state first
            let preferencesArray = Array(selectedPreferences)
            auth.dietPrefs = preferencesArray
            
            // Save to local state
            auth.saveLocalState()
            
            // Update LocalUserStore to persist preferences
            LocalUserStore.shared.updateGoals(dietaryPreferences: preferencesArray)
            
            // Update backend
            guard let token = AuthService.shared.readToken()?.accessToken else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            }
            
            let url = NetworkManager.shared.baseURL.appendingPathComponent("auth/profile")
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30.0
            
            let body: [String: Any] = [
                "dietaryPreferences": preferencesArray
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            if httpResponse.statusCode == 200 {
                // Success - regenerate recommendations
                await regenerateRecommendations()
                
                await MainActor.run {
                    showSuccess = true
                    isLoading = false
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMsg = errorData?["message"] as? String ?? "Failed to update preferences"
                throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func regenerateRecommendations() async {
        // Trigger recommendation regeneration with new dietary preferences
        do {
            guard let token = AuthService.shared.readToken()?.accessToken else {
                return
            }
            
            let url = NetworkManager.shared.baseURL.appendingPathComponent("recommendations/regenerate")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 60.0 // Longer timeout for AI generation
            
            // Send empty body for regenerate endpoint
            request.httpBody = try JSONSerialization.data(withJSONObject: [:])
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Recommendations regenerated with new dietary preferences")
            } else {
                print("⚠️ Failed to regenerate recommendations, but preferences were saved")
            }
        } catch {
            print("⚠️ Error regenerating recommendations: \(error.localizedDescription)")
            // Don't show error to user - preferences were saved successfully
        }
    }
}

struct DietaryPreferenceRow: View {
    let displayName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Design.Colors.primary : .secondary)
                
                Text(displayName)
                    .font(Design.Typography.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(Design.Spacing.md)
            .background(isSelected ? Design.Colors.primary.opacity(0.1) : Design.Colors.secondaryBackground)
            .cornerRadius(Design.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.medium)
                    .stroke(isSelected ? Design.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
