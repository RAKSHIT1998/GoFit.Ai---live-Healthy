import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var totalSteps: Int = 10 // 10 engaging screens
    
    // User data collected during onboarding
    @Published var name: String = ""
    @Published var goal: GoalType = .maintain
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var dietaryPreferences: Set<DietaryPreference> = []
    @Published var allergies: Set<String> = []
    @Published var fastingPreference: FastingPreference = .none
    @Published var appleHealthEnabled: Bool = false
    
    // New comprehensive questions
    @Published var weightKg: Double = 70
    @Published var heightCm: Double = 170
    @Published var workoutPreferences: Set<WorkoutType> = []
    @Published var favoriteFoods: [String] = []
    @Published var favoriteCuisines: Set<CuisineType> = []
    @Published var foodPreferences: Set<FoodPreference> = []
    @Published var workoutTimeAvailability: WorkoutTime = .moderate
    @Published var lifestyleFactors: Set<LifestyleFactor> = []
    
    // Additional engaging questions
    @Published var favoriteFoods: [String] = []
    @Published var mealTimingPreference: MealTiming = .regular
    @Published var cookingSkill: CookingSkill = .intermediate
    @Published var budgetPreference: BudgetPreference = .moderate
    @Published var motivationLevel: MotivationLevel = .moderate
    
    enum GoalType: String, CaseIterable, Codable {
        case lose = "lose"
        case maintain = "maintain"
        case gain = "gain"
        
        var displayName: String {
            switch self {
            case .lose: return "Lose Weight"
            case .maintain: return "Maintain Weight"
            case .gain: return "Gain Weight"
            }
        }
        
        var icon: String {
            switch self {
            case .lose: return "arrow.down.circle.fill"
            case .maintain: return "equal.circle.fill"
            case .gain: return "arrow.up.circle.fill"
            }
        }
    }
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "sedentary"
        case light = "light"
        case moderate = "moderate"
        case active = "active"
        case veryActive = "very_active"
        
        var displayName: String {
            switch self {
            case .sedentary: return "Sedentary"
            case .light: return "Light Activity"
            case .moderate: return "Moderate Activity"
            case .active: return "Active"
            case .veryActive: return "Very Active"
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Little to no exercise"
            case .light: return "Light exercise 1-3 days/week"
            case .moderate: return "Moderate exercise 3-5 days/week"
            case .active: return "Hard exercise 6-7 days/week"
            case .veryActive: return "Very hard exercise, physical job"
            }
        }
    }
    
    enum DietaryPreference: String, CaseIterable, Codable {
        case vegan = "vegan"
        case vegetarian = "vegetarian"
        case keto = "keto"
        case paleo = "paleo"
        case mediterranean = "mediterranean"
        case lowCarb = "low_carb"
        case none = "none"
        
        var displayName: String {
            switch self {
            case .vegan: return "Vegan"
            case .vegetarian: return "Vegetarian"
            case .keto: return "Keto"
            case .paleo: return "Paleo"
            case .mediterranean: return "Mediterranean"
            case .lowCarb: return "Low Carb"
            case .none: return "No Preference"
            }
        }
    }
    
    enum FastingPreference: String, CaseIterable, Codable {
        case none = "none"
        case sixteenEight = "16:8"
        case eighteenSix = "18:6"
        case twentyFour = "20:4"
        case omad = "OMAD"
        
        var displayName: String {
            switch self {
            case .none: return "No Fasting"
            case .sixteenEight: return "16:8 (16 hours fast, 8 hour eating window)"
            case .eighteenSix: return "18:6 (18 hours fast, 6 hour eating window)"
            case .twentyFour: return "20:4 (20 hours fast, 4 hour eating window)"
            case .omad: return "OMAD (One Meal A Day)"
            }
        }
    }
    
    enum WorkoutType: String, CaseIterable, Codable {
        case cardio = "cardio"
        case strength = "strength"
        case yoga = "yoga"
        case pilates = "pilates"
        case hiit = "hiit"
        case running = "running"
        case cycling = "cycling"
        case swimming = "swimming"
        case dancing = "dancing"
        case boxing = "boxing"
        case homeWorkouts = "home_workouts"
        case gym = "gym"
        
        var displayName: String {
            switch self {
            case .cardio: return "Cardio"
            case .strength: return "Strength Training"
            case .yoga: return "Yoga"
            case .pilates: return "Pilates"
            case .hiit: return "HIIT"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .swimming: return "Swimming"
            case .dancing: return "Dancing"
            case .boxing: return "Boxing"
            case .homeWorkouts: return "Home Workouts"
            case .gym: return "Gym Training"
            }
        }
        
        var icon: String {
            switch self {
            case .cardio: return "heart.fill"
            case .strength: return "dumbbell.fill"
            case .yoga: return "figure.flexibility"
            case .pilates: return "figure.core.training"
            case .hiit: return "flame.fill"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .dancing: return "music.note"
            case .boxing: return "figure.boxing"
            case .homeWorkouts: return "house.fill"
            case .gym: return "building.2.fill"
            }
        }
    }
    
    enum CuisineType: String, CaseIterable, Codable {
        case italian = "italian"
        case mexican = "mexican"
        case asian = "asian"
        case indian = "indian"
        case mediterranean = "mediterranean"
        case american = "american"
        case japanese = "japanese"
        case thai = "thai"
        case chinese = "chinese"
        case french = "french"
        case middleEastern = "middle_eastern"
        case none = "none"
        
        var displayName: String {
            switch self {
            case .italian: return "Italian"
            case .mexican: return "Mexican"
            case .asian: return "Asian"
            case .indian: return "Indian"
            case .mediterranean: return "Mediterranean"
            case .american: return "American"
            case .japanese: return "Japanese"
            case .thai: return "Thai"
            case .chinese: return "Chinese"
            case .french: return "French"
            case .middleEastern: return "Middle Eastern"
            case .none: return "No Preference"
            }
        }
    }
    
    enum FoodPreference: String, CaseIterable, Codable {
        case spicy = "spicy"
        case sweet = "sweet"
        case savory = "savory"
        case healthy = "healthy"
        case comfort = "comfort"
        case quick = "quick"
        case gourmet = "gourmet"
        case simple = "simple"
        
        var displayName: String {
            switch self {
            case .spicy: return "Spicy Foods"
            case .sweet: return "Sweet Foods"
            case .savory: return "Savory Foods"
            case .healthy: return "Healthy Options"
            case .comfort: return "Comfort Food"
            case .quick: return "Quick Meals"
            case .gourmet: return "Gourmet"
            case .simple: return "Simple & Clean"
            }
        }
    }
    
    enum WorkoutTime: String, CaseIterable, Codable {
        case veryLittle = "very_little"
        case little = "little"
        case moderate = "moderate"
        case plenty = "plenty"
        case unlimited = "unlimited"
        
        var displayName: String {
            switch self {
            case .veryLittle: return "15-30 min/day"
            case .little: return "30-45 min/day"
            case .moderate: return "45-60 min/day"
            case .plenty: return "1-2 hours/day"
            case .unlimited: return "2+ hours/day"
            }
        }
    }
    
    enum LifestyleFactor: String, CaseIterable, Codable {
        case busySchedule = "busy_schedule"
        case travelFrequently = "travel_frequently"
        case cookAtHome = "cook_at_home"
        case eatOutOften = "eat_out_often"
        case mealPrep = "meal_prep"
        case familyMeals = "family_meals"
        case workFromHome = "work_from_home"
        case nightShift = "night_shift"
        
        var displayName: String {
            switch self {
            case .busySchedule: return "Busy Schedule"
            case .travelFrequently: return "Travel Frequently"
            case .cookAtHome: return "Cook at Home"
            case .eatOutOften: return "Eat Out Often"
            case .mealPrep: return "Meal Prep"
            case .familyMeals: return "Family Meals"
            case .workFromHome: return "Work from Home"
            case .nightShift: return "Night Shift"
            }
        }
    }
    
    enum MealTiming: String, CaseIterable, Codable {
        case early = "early"
        case regular = "regular"
        case late = "late"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .early: return "Early Bird (6-8 AM breakfast)"
            case .regular: return "Regular (8-10 AM breakfast)"
            case .late: return "Late Riser (10 AM+ breakfast)"
            case .flexible: return "Flexible Schedule"
            }
        }
    }
    
    enum CookingSkill: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner - Simple recipes"
            case .intermediate: return "Intermediate - Can follow recipes"
            case .advanced: return "Advanced - Can modify recipes"
            case .expert: return "Expert - Create my own recipes"
            }
        }
        
        var icon: String {
            switch self {
            case .beginner: return "1.circle.fill"
            case .intermediate: return "2.circle.fill"
            case .advanced: return "3.circle.fill"
            case .expert: return "star.fill"
            }
        }
    }
    
    enum BudgetPreference: String, CaseIterable, Codable {
        case budget = "budget"
        case moderate = "moderate"
        case premium = "premium"
        case flexible = "flexible"
        
        var displayName: String {
            switch self {
            case .budget: return "Budget Friendly ($)"
            case .moderate: return "Moderate ($$)"
            case .premium: return "Premium ($$$)"
            case .flexible: return "Flexible - Quality matters"
            }
        }
    }
    
    enum MotivationLevel: String, CaseIterable, Codable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case veryHigh = "very_high"
        
        var displayName: String {
            switch self {
            case .low: return "Just Starting Out"
            case .moderate: return "Motivated"
            case .high: return "Very Motivated"
            case .veryHigh: return "Extremely Committed"
            }
        }
        
        var emoji: String {
            switch self {
            case .low: return "🌱"
            case .moderate: return "💪"
            case .high: return "🔥"
            case .veryHigh: return "⚡"
            }
        }
    }
    
    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStep -= 1
            }
        }
    }
    
    func canProceed() -> Bool {
        switch currentStep {
        case 0: return true // Welcome screen
        case 1: return !name.isEmpty // Name required
        case 2: return weightKg > 0 && heightCm > 0 // Weight & Height required
        case 3: return true // Goal selection
        case 4: return true // Activity level
        case 5: return true // Dietary preferences (optional)
        case 6: return true // Allergies (optional)
        case 7: return true // Workout preferences (optional)
        case 8: return true // Favorite cuisines & food preferences (optional)
        case 9: return true // Lifestyle & motivation (optional)
        default: return true
        }
    }
}
