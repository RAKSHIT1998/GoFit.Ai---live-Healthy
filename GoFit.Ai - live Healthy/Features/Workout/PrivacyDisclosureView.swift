import SwiftUI

// MARK: - Privacy Disclosure View
struct PrivacyDisclosureView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingPrivacyPolicy = false
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title)
                                .foregroundColor(Design.Colors.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Data Sharing")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Please review before continuing")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(Design.Spacing.lg)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(Design.Radius.medium)
                    
                    // Main Content
                    VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                        // What Data Gets Shared
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("What Data is Shared")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                Text("To generate personalized meal and workout recommendations, GoFit.Ai shares the following information with OpenAI:")
                                    .font(Design.Typography.body)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                                    dataItem(icon: "person.fill", title: "Profile Information", description: "Your name, age, goals, activity level")
                                    dataItem(icon: "ruler.fill", title: "Physical Metrics", description: "Weight, height, target weight, target calories")
                                    dataItem(icon: "fork.knife", title: "Food Preferences", description: "Dietary restrictions, allergies, favorite foods, cuisines")
                                    dataItem(icon: "heart.fill", title: "Health Data", description: "Recent meals, nutrition history, workout patterns")
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, Design.Spacing.md)
                        
                        // Who It's Shared With
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Who It's Shared With")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: Design.Spacing.md) {
                                    Image(systemName: "network")
                                        .font(.title3)
                                        .foregroundColor(Design.Colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                                        Text("OpenAI (GPT-4o API)")
                                            .font(Design.Typography.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("OpenAI Inc. processes this data to generate AI recommendations and follows their privacy standards.")
                                            .font(Design.Typography.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Link("View OpenAI Privacy Policy", destination: URL(string: "https://openai.com/privacy-policy") ?? URL(string: "about:blank")!)
                                            .font(Design.Typography.caption)
                                            .foregroundColor(Design.Colors.primary)
                                    }
                                }
                                .padding(Design.Spacing.md)
                                .background(Design.Colors.secondaryBackground)
                                .cornerRadius(Design.Radius.medium)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, Design.Spacing.md)
                        
                        // Purpose
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Purpose")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                                    purposeItem(icon: "list.clipboard.fill", title: "Personalized Meal Plans", description: "Generate daily meal recommendations tailored to your preferences")
                                    purposeItem(icon: "figure.strengthtraining.traditional", title: "Workout Routines", description: "Create customized exercise plans based on your fitness level")
                                    purposeItem(icon: "brain.head.profile", title: "Smart Insights", description: "Provide evidence-based health and fitness guidance")
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, Design.Spacing.md)
                        
                        // Your Control
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("Your Control")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                    controlItem(icon: "slider.horizontal.3", title: "Manage Preferences", description: "You can opt-out of AI recommendations at any time in Settings")
                                    controlItem(icon: "trash.fill", title: "Delete Data", description: "Request deletion of data shared with AI services")
                                    controlItem(icon: "eye.fill", title: "Transparency", description: "All recommendations include sources and citations")
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, Design.Spacing.md)
                        
                        // Data Security
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "lock.fill")
                                        .font(.title3)
                                        .foregroundColor(Design.Colors.primary)
                                    
                                    Text("Data Security")
                                        .font(Design.Typography.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text("All data is transmitted securely over HTTPS encryption. OpenAI does not permanently store your personal data used for recommendations.")
                                    .font(Design.Typography.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, Design.Spacing.md)
                        
                        // Privacy Policy Link
                        Section {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                Text("More Information")
                                    .font(Design.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                Button(action: { showingPrivacyPolicy = true }) {
                                    HStack(spacing: Design.Spacing.md) {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(Design.Colors.primary)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Full Privacy Policy")
                                                .font(Design.Typography.subheadline)
                                                .fontWeight(.semibold)
                                            
                                            Text("Read our complete privacy policy")
                                                .font(Design.Typography.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(Design.Colors.primary)
                                    }
                                }
                                .padding(Design.Spacing.md)
                                .background(Design.Colors.primary.opacity(0.1))
                                .cornerRadius(Design.Radius.medium)
                            }
                        }
                    }
                    .padding(Design.Spacing.lg)
                }
                .padding(.bottom, Design.Spacing.xl)
            }
            .navigationTitle("AI Data Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
    
    // MARK: - Helper Components
    
    private func dataItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func purposeItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func controlItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PrivacyDisclosureView(
        onAccept: { print("Accepted") },
        onDecline: { print("Declined") }
    )
}
