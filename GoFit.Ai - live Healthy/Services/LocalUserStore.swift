import Foundation
import Combine

/// Comprehensive local storage for user information - works offline
final class LocalUserStore: ObservableObject {
    static let shared = LocalUserStore()
    private init() {
        load()
    }
    
    @Published private(set) var userProfile: UserProfileData?
    
    private let storageURL: URL = {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("user_profile.json")
    }()
    
    private let storageLock = DispatchQueue(label: "local.user.store")
    
    // MARK: - User Profile Data Model
    struct UserProfileData: Codable {
        var userId: String?
        var email: String
        var name: String
        var weightKg: Double
        var heightCm: Double
        var targetWeightKg: Double?
        var goal: String // lose, maintain, gain
        var activityLevel: String
        var dietaryPreferences: [String]
        var allergies: [String]
        var fastingPreference: String
        var workoutPreferences: [String]
        var favoriteCuisines: [String]
        var foodPreferences: [String]
        var workoutTimeAvailability: String
        var lifestyleFactors: [String]
        var favoriteFoods: [String]
        var mealTimingPreference: String
        var cookingSkill: String
        var budgetPreference: String
        var motivationLevel: String
        var drinkingFrequency: String
        var smokingStatus: String
        var targetCalories: Double?
        var targetProtein: Double?
        var targetCarbs: Double?
        var targetFat: Double?
        var liquidIntakeGoal: Double?
        var lastUpdated: Date
        
        init(userId: String? = nil, email: String = "", name: String = "", weightKg: Double = 70, heightCm: Double = 170, targetWeightKg: Double? = nil, goal: String = "maintain", activityLevel: String = "moderate", dietaryPreferences: [String] = [], allergies: [String] = [], fastingPreference: String = "none", workoutPreferences: [String] = [], favoriteCuisines: [String] = [], foodPreferences: [String] = [], workoutTimeAvailability: String = "moderate", lifestyleFactors: [String] = [], favoriteFoods: [String] = [], mealTimingPreference: String = "regular", cookingSkill: String = "intermediate", budgetPreference: String = "moderate", motivationLevel: String = "moderate", drinkingFrequency: String = "never", smokingStatus: String = "never", targetCalories: Double? = nil, targetProtein: Double? = nil, targetCarbs: Double? = nil, targetFat: Double? = nil, liquidIntakeGoal: Double? = 2.5, lastUpdated: Date = Date()) {
            self.userId = userId
            self.email = email
            self.name = name
            self.weightKg = weightKg
            self.heightCm = heightCm
            self.targetWeightKg = targetWeightKg
            self.goal = goal
            self.activityLevel = activityLevel
            self.dietaryPreferences = dietaryPreferences
            self.allergies = allergies
            self.fastingPreference = fastingPreference
            self.workoutPreferences = workoutPreferences
            self.favoriteCuisines = favoriteCuisines
            self.foodPreferences = foodPreferences
            self.workoutTimeAvailability = workoutTimeAvailability
            self.lifestyleFactors = lifestyleFactors
            self.favoriteFoods = favoriteFoods
            self.mealTimingPreference = mealTimingPreference
            self.cookingSkill = cookingSkill
            self.budgetPreference = budgetPreference
            self.motivationLevel = motivationLevel
            self.drinkingFrequency = drinkingFrequency
            self.smokingStatus = smokingStatus
            self.targetCalories = targetCalories
            self.targetProtein = targetProtein
            self.targetCarbs = targetCarbs
            self.targetFat = targetFat
            self.liquidIntakeGoal = liquidIntakeGoal
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Load & Save
    private func load() {
        storageLock.sync {
            guard FileManager.default.fileExists(atPath: storageURL.path) else {
                userProfile = nil
                return
            }
            do {
                let data = try Data(contentsOf: storageURL)
                let profile = try JSONDecoder().decode(UserProfileData.self, from: data)
                DispatchQueue.main.async {
                    self.userProfile = profile
                }
                print("✅ Loaded user profile from local storage")
            } catch {
                print("⚠️ Failed to load user profile: \(error)")
                userProfile = nil
            }
        }
    }
    
    private func persist() {
        storageLock.async {
            guard let profile = self.userProfile else { return }
            do {
                let data = try JSONEncoder().encode(profile)
                try data.write(to: self.storageURL, options: [.atomic])
            } catch {
                print("⚠️ Failed to persist user profile: \(error)")
            }
        }
    }
    
    // MARK: - Update Methods
    func updateProfile(_ profile: UserProfileData) {
        storageLock.sync {
            var updated = profile
            updated.lastUpdated = Date()
            DispatchQueue.main.async {
                self.userProfile = updated
            }
            persist()
        }
    }
    
    func updateBasicInfo(name: String? = nil, email: String? = nil, weightKg: Double? = nil, heightCm: Double? = nil, targetWeightKg: Double? = nil) {
        storageLock.sync {
            var updated = userProfile ?? UserProfileData()
            if let name = name { updated.name = name }
            if let email = email { updated.email = email }
            if let weightKg = weightKg { updated.weightKg = weightKg }
            if let heightCm = heightCm { updated.heightCm = heightCm }
            if let targetWeightKg = targetWeightKg { updated.targetWeightKg = targetWeightKg }
            updated.lastUpdated = Date()
            
            DispatchQueue.main.async {
                self.userProfile = updated
            }
            persist()
        }
    }
    
    func updateGoals(goal: String? = nil, activityLevel: String? = nil, dietaryPreferences: [String]? = nil, allergies: [String]? = nil) {
        storageLock.sync {
            var updated = userProfile ?? UserProfileData()
            if let goal = goal { updated.goal = goal }
            if let activityLevel = activityLevel { updated.activityLevel = activityLevel }
            if let dietaryPreferences = dietaryPreferences { updated.dietaryPreferences = dietaryPreferences }
            if let allergies = allergies { updated.allergies = allergies }
            updated.lastUpdated = Date()
            
            DispatchQueue.main.async {
                self.userProfile = updated
            }
            persist()
        }
    }
    
    func updateNutritionTargets(targetCalories: Double? = nil, targetProtein: Double? = nil, targetCarbs: Double? = nil, targetFat: Double? = nil, liquidIntakeGoal: Double? = nil) {
        storageLock.sync {
            var updated = userProfile ?? UserProfileData()
            if let targetCalories = targetCalories { updated.targetCalories = targetCalories }
            if let targetProtein = targetProtein { updated.targetProtein = targetProtein }
            if let targetCarbs = targetCarbs { updated.targetCarbs = targetCarbs }
            if let targetFat = targetFat { updated.targetFat = targetFat }
            if let liquidIntakeGoal = liquidIntakeGoal { updated.liquidIntakeGoal = liquidIntakeGoal }
            updated.lastUpdated = Date()
            
            DispatchQueue.main.async {
                self.userProfile = updated
            }
            persist()
        }
    }
    
    func updateOnboardingData(_ onboardingData: OnboardingData, userId: String? = nil, email: String? = nil) {
        storageLock.sync {
            let profile = UserProfileData(
                userId: userId,
                email: email ?? "", // Use provided email or empty string (email comes from auth)
                name: onboardingData.name,
                weightKg: onboardingData.weightKg,
                heightCm: onboardingData.heightCm,
                targetWeightKg: nil, // Can be set separately
                goal: onboardingData.goal,
                activityLevel: onboardingData.activityLevel,
                dietaryPreferences: onboardingData.dietaryPreferences,
                allergies: onboardingData.allergies,
                fastingPreference: onboardingData.fastingPreference,
                workoutPreferences: onboardingData.workoutPreferences,
                favoriteCuisines: onboardingData.favoriteCuisines,
                foodPreferences: onboardingData.foodPreferences,
                workoutTimeAvailability: onboardingData.workoutTimeAvailability,
                lifestyleFactors: onboardingData.lifestyleFactors,
                favoriteFoods: onboardingData.favoriteFoods,
                mealTimingPreference: onboardingData.mealTimingPreference,
                cookingSkill: onboardingData.cookingSkill,
                budgetPreference: onboardingData.budgetPreference,
                motivationLevel: onboardingData.motivationLevel,
                drinkingFrequency: onboardingData.drinkingFrequency,
                smokingStatus: onboardingData.smokingStatus
            )
            
            DispatchQueue.main.async {
                self.userProfile = profile
            }
            persist()
        }
    }
    
    // MARK: - Query Methods
    func getProfile() -> UserProfileData? {
        return storageLock.sync { userProfile }
    }
    
    func clearProfile() {
        storageLock.sync {
            DispatchQueue.main.async {
                self.userProfile = nil
            }
            // Delete file
            try? FileManager.default.removeItem(at: storageURL)
        }
    }
}
