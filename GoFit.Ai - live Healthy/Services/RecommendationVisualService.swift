import Foundation
import UIKit

/// Service to provide visual assets (images) for workouts and meals
/// Uses SF Symbols and generated placeholder images
final class RecommendationVisualService {
    static let shared = RecommendationVisualService()
    
    private init() {}
    
    // MARK: - Workout Exercise Images
    
    /// Get SF Symbol for exercise type
    func getExerciseIcon(for exerciseName: String) -> String {
        let nameLower = exerciseName.lowercased()
        
        // Cardio exercises
        if nameLower.contains("running") || nameLower.contains("sprint") {
            return "figure.run"
        }
        if nameLower.contains("cycling") || nameLower.contains("bike") {
            return "bicycle"
        }
        if nameLower.contains("jump") || nameLower.contains("rope") {
            return "figure.jump.rope"
        }
        if nameLower.contains("walk") {
            return "figure.walk"
        }
        if nameLower.contains("swim") {
            return "figure.pool.swim"
        }
        
        // Strength exercises
        if nameLower.contains("push") || nameLower.contains("press") {
            return "figure.strengthtraining"
        }
        if nameLower.contains("squat") {
            return "figure.strengthtraining"
        }
        if nameLower.contains("deadlift") {
            return "figure.strengthtraining"
        }
        if nameLower.contains("pull") || nameLower.contains("chin") {
            return "figure.strengthtraining"
        }
        if nameLower.contains("dumbbell") || nameLower.contains("weight") {
            return "figure.strengthtraining"
        }
        
        // Flexibility exercises
        if nameLower.contains("yoga") || nameLower.contains("stretch") || nameLower.contains("pilates") {
            return "figure.flexibility"
        }
        
        // Core exercises
        if nameLower.contains("plank") || nameLower.contains("crunch") {
            return "figure.strengthtraining"
        }
        
        // HIIT
        if nameLower.contains("burpee") || nameLower.contains("hiit") {
            return "bolt.fill"
        }
        
        // Default
        return "figure.strengthtraining"
    }
    
    /// Get color gradient for exercise type
    func getExerciseGradient(for exerciseType: String) -> [UIColor] {
        let typeLower = exerciseType.lowercased()
        
        if typeLower.contains("cardio") {
            return [UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0),
                    UIColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1.0)]
        }
        if typeLower.contains("strength") {
            return [UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
                    UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)]
        }
        if typeLower.contains("flexibility") {
            return [UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0),
                    UIColor(red: 0.9, green: 0.4, blue: 0.7, alpha: 1.0)]
        }
        if typeLower.contains("hiit") {
            return [UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0),
                    UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)]
        }
        
        // Default gradient
        return [UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),
                UIColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 1.0)]
    }
    
    /// Generate a stylized exercise visualization
    func generateExerciseImage(for exerciseName: String, exerciseType: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let colors = getExerciseGradient(for: exerciseType)
        let icon = getExerciseIcon(for: exerciseName)
        
        let image = renderer.image { context in
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors.map { $0.cgColor } as CFArray,
                                     locations: [0, 1])!
            
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: size.width, y: size.height)
            
            context.cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            
            // Add rounded corners effect
            let rect = CGRect(origin: .zero, size: size)
            UIColor.clear.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 16).addClip()
            
            // Draw icon name at bottom
            let textRect = CGRect(x: 10, y: size.height - 40, width: size.width - 20, height: 30)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            exerciseName.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
    
    // MARK: - Meal Images
    
    /// Get emoji representation for meal type
    func getMealEmoji(for mealName: String) -> String {
        let nameLower = mealName.lowercased()
        
        // Proteins
        if nameLower.contains("chicken") { return "🍗" }
        if nameLower.contains("fish") || nameLower.contains("salmon") { return "🐟" }
        if nameLower.contains("beef") || nameLower.contains("steak") { return "🥩" }
        if nameLower.contains("egg") { return "🥚" }
        if nameLower.contains("tofu") { return "🟫" }
        
        // Vegetables
        if nameLower.contains("salad") { return "🥗" }
        if nameLower.contains("broccoli") { return "🥦" }
        if nameLower.contains("carrot") { return "🥕" }
        if nameLower.contains("spinach") { return "🥬" }
        if nameLower.contains("vegetable") { return "🥒" }
        
        // Grains
        if nameLower.contains("rice") { return "🍚" }
        if nameLower.contains("pasta") { return "🍝" }
        if nameLower.contains("bread") { return "🍞" }
        if nameLower.contains("oat") { return "🌾" }
        
        // Fruits
        if nameLower.contains("apple") { return "🍎" }
        if nameLower.contains("banana") { return "🍌" }
        if nameLower.contains("berry") || nameLower.contains("blueberry") { return "🫐" }
        if nameLower.contains("avocado") { return "🥑" }
        
        // Dairy
        if nameLower.contains("yogurt") { return "🥛" }
        if nameLower.contains("cheese") { return "🧀" }
        if nameLower.contains("milk") { return "🥛" }
        
        // Prepared meals
        if nameLower.contains("bowl") { return "🥣" }
        if nameLower.contains("soup") { return "🍲" }
        if nameLower.contains("curry") { return "🍛" }
        if nameLower.contains("pizza") { return "🍕" }
        if nameLower.contains("sandwich") { return "🥪" }
        
        // Snacks
        if nameLower.contains("nuts") { return "🥜" }
        if nameLower.contains("bar") { return "🍫" }
        if nameLower.contains("granola") { return "🥣" }
        
        // Default
        return "🍽️"
    }
    
    /// Get food category color
    func getMealColor(for mealName: String) -> UIColor {
        let nameLower = mealName.lowercased()
        
        if nameLower.contains("vegetable") || nameLower.contains("salad") || nameLower.contains("broccoli") {
            return UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0) // Green
        }
        if nameLower.contains("chicken") || nameLower.contains("fish") || nameLower.contains("beef") {
            return UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0) // Orange (protein)
        }
        if nameLower.contains("rice") || nameLower.contains("pasta") || nameLower.contains("oat") {
            return UIColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0) // Yellow (carbs)
        }
        if nameLower.contains("cheese") || nameLower.contains("yogurt") || nameLower.contains("milk") {
            return UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0) // Cream (dairy)
        }
        if nameLower.contains("fruit") || nameLower.contains("berry") || nameLower.contains("apple") {
            return UIColor(red: 0.9, green: 0.3, blue: 0.4, alpha: 1.0) // Red (fruit)
        }
        
        // Default
        return UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1.0)
    }
    
    /// Generate meal visualization image
    func generateMealImage(for mealName: String, calories: Double, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let color = getMealColor(for: mealName)
        let emoji = getMealEmoji(for: mealName)
        
        let image = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Gradient overlay
            let colors: [CGColor] = [
                color.withAlphaComponent(0.1).cgColor,
                color.withAlphaComponent(0.3).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0, 1])!
            
            context.cgContext.drawLinearGradient(gradient,
                                                start: CGPoint(x: 0, y: 0),
                                                end: CGPoint(x: size.width, y: size.height),
                                                options: [])
            
            // Draw emoji (food representation)
            let emojiSize: CGFloat = 60
            let emojiAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: emojiSize)
            ]
            let emojiRect = CGRect(x: (size.width - emojiSize) / 2,
                                  y: (size.height - emojiSize) / 2 - 20,
                                  width: emojiSize,
                                  height: emojiSize)
            emoji.draw(in: emojiRect, withAttributes: emojiAttributes)
            
            // Draw meal name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: color
            ]
            let nameRect = CGRect(x: 10, y: size.height - 35, width: size.width - 20, height: 30)
            mealName.draw(in: nameRect, withAttributes: nameAttributes)
            
            // Draw calorie info
            let calorieAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let calorieRect = CGRect(x: 10, y: size.height - 20, width: size.width - 20, height: 15)
            "\(Int(calories)) kcal".draw(in: calorieRect, withAttributes: calorieAttributes)
        }
        
        return image
    }
    
    // MARK: - Muscle Group Icons
    
    func getMuscleGroupIcon(_ muscleGroup: String) -> String {
        let nameLower = muscleGroup.lowercased()
        
        if nameLower.contains("chest") { return "figure.strengthtraining" }
        if nameLower.contains("back") { return "figure.strengthtraining" }
        if nameLower.contains("bicep") { return "figure.arms.open" }
        if nameLower.contains("tricep") { return "figure.strengthtraining" }
        if nameLower.contains("shoulder") { return "figure.strengthtraining" }
        if nameLower.contains("leg") || nameLower.contains("quad") || nameLower.contains("hamstring") { return "figure.stairs" }
        if nameLower.contains("glute") || nameLower.contains("butt") { return "figure.stairs" }
        if nameLower.contains("calf") { return "figure.stairs" }
        if nameLower.contains("core") || nameLower.contains("abs") { return "figure.strengthtraining" }
        
        return "figure.strengthtraining"
    }
    
    func getMuscleGroupColor(_ muscleGroup: String) -> Color {
        let nameLower = muscleGroup.lowercased()
        
        if nameLower.contains("chest") { return Color.red }
        if nameLower.contains("back") { return Color.orange }
        if nameLower.contains("bicep") || nameLower.contains("arm") { return Color.yellow }
        if nameLower.contains("shoulder") { return Color.pink }
        if nameLower.contains("leg") || nameLower.contains("glute") || nameLower.contains("quad") { return Color.green }
        if nameLower.contains("core") || nameLower.contains("abs") { return Color.purple }
        
        return Color.blue
    }
}

// MARK: - SwiftUI Helper View
import SwiftUI

struct MealVisualCard: View {
    let meal: RecommendationMealItem
    let service = RecommendationVisualService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Emoji + Name
            VStack {
                Text(service.getMealEmoji(for: meal.name))
                    .font(.system(size: 40))
                Text(meal.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            // Calories
            HStack {
                Label("\(Int(meal.calories))kcal", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(Color(service.getMealColor(for: meal.name)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(service.getMealColor(for: meal.name)).opacity(0.1))
        .cornerRadius(12)
    }
}

struct ExerciseVisualCard: View {
    let exercise: Exercise
    let service = RecommendationVisualService.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: service.getExerciseIcon(for: exercise.name))
                .font(.system(size: 30))
            
            Text(exercise.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Details
            HStack(spacing: 8) {
                Label("\(exercise.duration)min", systemImage: "clock.fill")
                    .font(.caption)
                Label("\(exercise.calories)kcal", systemImage: "flame.fill")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
