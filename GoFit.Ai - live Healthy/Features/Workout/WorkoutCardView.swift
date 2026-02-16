import SwiftUI

/// Enhanced workout card view with exercise details and images
struct WorkoutCardView: View {
    let workout: WorkoutSession
    @State private var isExpanded = false
    @State private var selectedExercise: ExerciseRecord?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(formatDate(workout.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(Int(workout.caloriesBurned)) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(formatDuration(workout.duration))
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Exercises List
            if isExpanded && !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(workout.exercises) { exercise in
                        ExerciseItemView(exercise: exercise)
                            .onTapGesture {
                                selectedExercise = exercise
                            }
                    }
                }
                .padding(.vertical, 8)
                
                if !(workout.notes?.isEmpty ?? true) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text(workout.notes ?? "")
                            .font(.caption)
                            .lineLimit(nil)
                    }
                }
            } else if !isExpanded {
                // Compact view - show exercise count
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.green)
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            
            // Expand/Collapse Button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workoutName: workout.name)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Individual exercise display with details and stored images
struct ExerciseItemView: View {
    let exercise: ExerciseRecord
    @State private var exerciseImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Image or Icon
            ZStack {
                Color(.systemGray5)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                if let image = exerciseImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "figure.strengthtraining")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .onAppear {
                loadExerciseImage()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    // Sets × Reps
                    Label("\(exercise.sets) × \(exercise.reps.map(String.init).joined(separator: "-"))", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Weight
                    if let weight = exercise.weight {
                        Label("\(Int(weight)) kg", systemImage: "scalemass")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Duration (for cardio)
                    if let duration = exercise.duration {
                        Label(formatDuration(duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func loadExerciseImage() {
        isLoadingImage = true
        if let imageFilename = exercise.imageURL {
            exerciseImage = WorkoutImageManager.shared.loadExerciseFormImage(filename: imageFilename)
        }
        isLoadingImage = false
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", secs))"
        }
        return "\(secs)s"
    }
}

/// Detailed exercise view with image and full information
struct ExerciseDetailView: View {
    let exercise: ExerciseRecord
    let workoutName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise Image/Icon
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Exercise Image")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .cornerRadius(12)
                
                // Exercise Details
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exercise")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Text(exercise.exerciseName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // Workout Context
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Text(workoutName)
                            .font(.subheadline)
                    }
                    
                    Divider()
                    
                    // Performance Details
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sets")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            Text("\(exercise.sets)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            Text(exercise.reps.map(String.init).joined(separator: " • "))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        if let weight = exercise.weight {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weight")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                Text("\(Int(weight)) kg")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Duration for cardio exercises
                    if let duration = exercise.duration {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            Text(formatDuration(duration))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Form Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pro Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        tips
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private var tips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Maintain proper form throughout all sets")
                    .font(.caption)
            }
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Rest adequately between sets")
                    .font(.caption)
            }
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Stay hydrated during your workout")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(secs)s"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleWorkout = WorkoutSession(
        name: "Upper Body Strength",
        duration: 2700, // 45 minutes
        caloriesBurned: 250,
        exercises: [
            ExerciseRecord(
                exerciseName: "Barbell Bench Press",
                sets: 4,
                reps: [10, 10, 8, 8],
                weight: 100,
                duration: nil
            ),
            ExerciseRecord(
                exerciseName: "Hammer Curl",
                sets: 3,
                reps: [12, 12, 10],
                weight: 30,
                duration: nil
            ),
            ExerciseRecord(
                exerciseName: "Barbell Bent Over Row",
                sets: 4,
                reps: [10, 8, 8, 6],
                weight: 110,
                duration: nil
            )
        ],
        date: Date(),
        notes: "Great workout! Felt strong throughout."
    )
    
    return WorkoutCardView(workout: sampleWorkout)
        .padding()
}
