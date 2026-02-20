import SwiftUI

// MARK: - GIF Generation View
/// UI for generating AI-powered GIFs for exercises and storing them locally
struct GifGenerationView: View {
    let exercises: [Exercise]
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var gifGenerator = AIGifGeneratorService.shared
    @State private var selectedExercises: Set<String> = []
    @State private var generatedCount = 0
    @State private var totalToGenerate = 0
    @State private var isGenerating = false
    @State private var showSuccessMessage = false
    
    private let gifService = ExerciseGifService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Header Info
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        HStack {
                            Image(systemName: "wand.and.stars.inverse")
                                .font(.system(size: 32))
                                .foregroundColor(Design.Colors.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI GIF Generator")
                                    .font(Design.Typography.title)
                                    .fontWeight(.bold)
                                
                                Text("Create animated exercise demonstrations")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Storage info
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.secondary)
                            Text("Storage used: \(String(format: "%.1f", Double(gifService.getStorageUsage()) / (1024 * 1024))) MB")
                                .font(Design.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(Design.Spacing.lg)
                    .cardStyle()
                    
                    // Generation Progress
                    if isGenerating {
                        VStack(spacing: Design.Spacing.md) {
                            HStack {
                                ProgressView(value: Double(generatedCount), total: Double(totalToGenerate))
                                    .tint(Design.Colors.primary)
                                
                                Text("\(generatedCount)/\(totalToGenerate)")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            
                            if gifGenerator.isGenerating {
                                HStack(spacing: Design.Spacing.sm) {
                                    ProgressView(value: gifGenerator.generationProgress)
                                        .tint(Design.Colors.primary)
                                    
                                    Text("\(Int(gifGenerator.generationProgress * 100))%")
                                        .font(Design.Typography.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }
                            
                            Text("Generating animations...")
                                .font(Design.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(Design.Spacing.lg)
                        .cardStyle()
                    }
                    
                    // Success message
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("GIFs generated and saved to device!")
                                .font(Design.Typography.body)
                                .foregroundColor(.primary)
                        }
                        .padding(Design.Spacing.lg)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(Design.Radius.medium)
                        .padding(.horizontal, Design.Spacing.md)
                    }
                    
                    // Exercise List
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        HStack {
                            Text("Select Exercises")
                                .font(Design.Typography.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                if selectedExercises.count == exercises.count {
                                    selectedExercises.removeAll()
                                } else {
                                    selectedExercises = Set(exercises.map { $0.name })
                                }
                            }) {
                                Text(selectedExercises.count == exercises.count ? "Deselect All" : "Select All")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(Design.Colors.primary)
                            }
                        }
                        
                        ForEach(exercises, id: \.name) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                    .padding(Design.Spacing.lg)
                    .cardStyle()
                    
                    // Generate Button
                    Button(action: generateGifs) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate \(selectedExercises.count) GIF\(selectedExercises.count == 1 ? "" : "s")")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Design.Spacing.md)
                        .background(selectedExercises.isEmpty ? Color.gray : Design.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(Design.Radius.medium)
                    }
                    .disabled(selectedExercises.isEmpty || isGenerating)
                    .padding(.horizontal, Design.Spacing.md)
                    
                    // Clear Cache Button
                    Button(action: clearCache) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All GIFs")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Design.Spacing.sm)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(Design.Radius.medium)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal, Design.Spacing.md)
                }
                .padding(.vertical, Design.Spacing.md)
            }
            .navigationTitle("AI GIF Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-select exercises that don't have GIFs
            for exercise in exercises {
                if !gifService.hasGif(for: exercise.name) {
                    selectedExercises.insert(exercise.name)
                }
            }
        }
    }
    
    // MARK: - Exercise Row
    
    private func exerciseRow(_ exercise: Exercise) -> some View {
        let hasGif = gifService.hasGif(for: exercise.name)
        let isSelected = selectedExercises.contains(exercise.name)
        
        return Button(action: {
            if isSelected {
                selectedExercises.remove(exercise.name)
            } else {
                selectedExercises.insert(exercise.name)
            }
        }) {
            HStack(spacing: Design.Spacing.md) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Design.Colors.primary : .secondary)
                
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(Design.Colors.primaryGradient)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: RecommendationVisualService.shared.getExerciseIcon(for: exercise.name))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(Design.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: Design.Spacing.sm) {
                        Text(exercise.type.capitalized)
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        if hasGif {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Has GIF")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, Design.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func generateGifs() {
        guard !selectedExercises.isEmpty else { return }
        
        isGenerating = true
        showSuccessMessage = false
        generatedCount = 0
        
        let exercisesToGenerate = exercises.filter { selectedExercises.contains($0.name) }
        totalToGenerate = exercisesToGenerate.count
        
        gifGenerator.generateGifsForExercises(exercisesToGenerate) { completed, successful in
            generatedCount = completed
            
            if completed == totalToGenerate {
                isGenerating = false
                showSuccessMessage = true
                selectedExercises.removeAll()
                
                // Hide success message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccessMessage = false
                }
            }
        }
    }
    
    private func clearCache() {
        let success = gifService.clearAllGifs()
        if success {
            // Refresh the view
            selectedExercises.removeAll()
        } else {
            print("Failed to clear cache")
        }
    }
}

// MARK: - Preview
#if DEBUG
struct GifGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExercises = [
            Exercise(
                name: "Push-ups",
                duration: 10,
                calories: 45,
                type: "chest",
                instructions: "Standard push-up form",
                sets: 3,
                reps: "15-20",
                restTime: 60,
                difficulty: "medium",
                muscleGroups: ["Chest", "Triceps"],
                equipment: ["None"],
                gifUrl: nil,
                videoUrl: nil, sources: <#[CitationSource]?#>
            ),
            Exercise(
                name: "Squats",
                duration: 10,
                calories: 50,
                type: "legs",
                instructions: "Keep back straight",
                sets: 3,
                reps: "20",
                restTime: 60,
                difficulty: "easy",
                muscleGroups: ["Quads", "Glutes"],
                equipment: ["None"],
                gifUrl: nil,
                videoUrl: nil, sources: <#[CitationSource]?#>
            )
        ]
        
        GifGenerationView(exercises: sampleExercises)
    }
}
#endif
