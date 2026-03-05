import SwiftUI

struct AIDataConsentView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasAcceptedAIConsent") private var hasAcceptedAIConsent = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "brain")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                        
                        Text("AI-Powered Food Analysis")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity)
                        
                        Text("GoFit.Ai uses artificial intelligence to analyze your food photos and provide nutritional information.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                    
                    // What data is collected
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What Data We Send", systemImage: "photo")
                            .font(.headline)
                        
                        DataPointRow(icon: "camera.fill", text: "Food photos you take or upload")
                        DataPointRow(icon: "calendar", text: "Timestamp of when the photo was taken")
                        DataPointRow(icon: "fork.knife", text: "Meal type (breakfast, lunch, dinner, snack)")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Who receives the data
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI Service Provider", systemImage: "cloud")
                            .font(.headline)
                        
                        Text("**Google Gemini AI**")
                            .font(.subheadline)
                        
                        Text("Your food photos are sent to Google's Gemini AI service for analysis. Google Gemini processes the image to identify food items and estimate nutritional values.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link(destination: URL(string: "https://ai.google.dev/gemini-api/terms")!) {
                            HStack {
                                Text("View Google Gemini Terms")
                                    .font(.caption)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // How we protect your data
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Privacy Protection", systemImage: "lock.shield")
                            .font(.headline)
                        
                        PrivacyPointRow(icon: "lock.fill", text: "Photos are sent securely over encrypted connections")
                        PrivacyPointRow(icon: "trash", text: "Photos are not permanently stored by Google Gemini")
                        PrivacyPointRow(icon: "eye.slash", text: "No personally identifiable information is sent with your photos")
                        PrivacyPointRow(icon: "hand.raised.fill", text: "You can delete your meal history anytime")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Purpose
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How AI Helps You", systemImage: "checkmark.circle")
                            .font(.headline)
                        
                        Text("• Instantly analyze food photos")
                        Text("• Identify multiple food items in one image")
                        Text("• Calculate calories, protein, carbs, fat, and sugar")
                        Text("• Estimate portion sizes")
                        Text("• Track your nutrition effortlessly")
                        
                        Text("All of this is only possible with AI-powered image analysis.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Your choice
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Choice", systemImage: "person.fill.checkmark")
                            .font(.headline)
                        
                        Text("By continuing, you agree to:")
                            .font(.subheadline)
                        
                        Text("• Share food photos with Google Gemini AI for analysis")
                        Text("• Allow GoFit.Ai to send your photos to third-party AI services")
                        Text("• Accept that AI analysis may not always be 100% accurate")
                        
                        Text("You can manually log meals without using AI, or you can disable the meal scanner feature anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            hasAcceptedAIConsent = true
                            dismiss()
                        } label: {
                            Text("I Agree - Use AI Food Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Decline - Manual Entry Only")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Privacy policy link
                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        Text("View Full Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
}

struct DataPointRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PrivacyPointRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    AIDataConsentView()
}
