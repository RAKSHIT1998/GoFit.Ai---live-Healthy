import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var totalSteps: Int = 7
    
    // User data collected during onboarding
    @Published var name: String = ""
    @Published var goal: GoalType = .maintain
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var dietaryPreferences: Set<DietaryPreference> = []
    @Published var allergies: Set<String> = []
    @Published var fastingPreference: FastingPreference = .none
    @Published var appleHealthEnabled: Bool = false
    
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
        case 1: return !name.isEmpty
        case 2: return true // Goal selection
        case 3: return true // Activity level
        case 4: return true // Dietary preferences (optional)
        case 5: return true // Allergies (optional)
        case 6: return true // Fasting preference
        default: return true
        }
    }
}
