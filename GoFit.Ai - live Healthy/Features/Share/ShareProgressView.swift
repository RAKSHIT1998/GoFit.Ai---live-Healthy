import SwiftUI

struct ShareProgressView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var healthKit = HealthKitService.shared
    
    let calories: String
    let steps: Int
    let activeCalories: Double
    let waterIntake: Double
    let heartRate: Double?
    
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    @State private var isGeneratingImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        if let image = shareImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .padding()
                        } else {
                            // Placeholder
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 400)
                                .overlay(
                                    VStack {
                                        if isGeneratingImage {
                                            ProgressView()
                                                .tint(.white)
                                            Text("Generating image...")
                                                .foregroundColor(.white)
                                                .padding(.top)
                                        } else {
                                            Text("Tap to generate shareable image")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                        }
                                    }
                                )
                                .padding()
                                .onTapGesture {
                                    generateShareImage()
                                }
                        }
                        
                        // Share Options
                        VStack(spacing: 16) {
                            // Share as Image
                            Button {
                                if shareImage != nil {
                                    shareAsImage()
                                } else {
                                    generateShareImage()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                    Text("Share as Image")
                                        .font(Design.Typography.headline)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Design.Colors.primaryGradient)
                                .cornerRadius(16)
                            }
                            
                            // Share as Text
                            Button {
                                shareAsText()
                            } label: {
                                HStack {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.title2)
                                    Text("Share as Text")
                                        .font(Design.Typography.headline)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Design.Colors.primaryGradient)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Stats Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Progress Today")
                                .font(Design.Typography.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                StatRow(icon: "flame.fill", value: calories, label: "Calories", color: .orange)
                                StatRow(icon: "figure.walk", value: "\(steps.formatted())", label: "Steps", color: .green)
                                StatRow(icon: "bolt.fill", value: "\(Int(activeCalories).formatted())", label: "Active Calories", color: .yellow)
                                StatRow(icon: "drop.fill", value: "\(String(format: "%.1f", waterIntake))L", label: "Water", color: .blue)
                                if let heartRate = heartRate, heartRate > 0 {
                                    StatRow(icon: "heart.fill", value: "\(Int(heartRate))", label: "Heart Rate (bpm)", color: .red)
                                }
                            }
                            .padding()
                            .background(Design.Colors.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [
                        image,
                        "Check out my fitness progress with GoFit.Ai! 💪\n\nTrack your health and fitness with GoFit.Ai - Your AI-powered health companion.\n\n#GoFitAi #Fitness #Health #Wellness"
                    ])
                } else {
                    ShareSheet(activityItems: [
                        generateShareText()
                    ])
                }
            }
            .onAppear {
                generateShareImage()
            }
        }
    }
    
    private func generateShareImage() {
        isGeneratingImage = true
        // Generate image for preview without auto-sharing
        ShareService.shared.shareProgressImage(
            calories: calories,
            steps: steps,
            activeCalories: activeCalories,
            waterIntake: waterIntake,
            heartRate: heartRate,
            userName: auth.name
        ) { image in
            DispatchQueue.main.async {
                self.shareImage = image
                self.isGeneratingImage = false
            }
        }
    }
    
    private func shareAsImage() {
        showingShareSheet = true
    }
    
    private func shareAsText() {
        ShareService.shared.shareProgress(
            calories: calories,
            steps: steps,
            activeCalories: activeCalories,
            waterIntake: waterIntake,
            heartRate: heartRate,
            userName: auth.name
        )
    }
    
    private func generateShareText() -> String {
        // Use ShareService's method to ensure consistency
        return ShareService.shared.generateShareText(
            calories: calories,
            steps: steps,
            activeCalories: activeCalories,
            waterIntake: waterIntake,
            heartRate: heartRate,
            userName: auth.name
        )
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(value)
                .font(Design.Typography.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Text(label)
                .font(Design.Typography.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

