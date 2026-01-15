import Foundation

// MARK: - Daily Log Model
/// Comprehensive daily log containing all nutrition and activity data for a single day
struct DailyLog: Codable, Identifiable {
    let id: String
    let date: Date // Start of day (normalized to midnight)
    
    // Meals
    var meals: [LoggedMeal]
    
    // Liquid Intake
    var liquidIntake: [LiquidEntry]
    
    // Activity
    var caloriesBurned: Double // Total calories burned (from HealthKit or manual)
    var steps: Int? // Steps count (optional)
    
    // Daily Totals (calculated)
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.totalCalories }
    }
    
    var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    var totalFat: Double {
        meals.reduce(0) { $0 + $1.totalFat }
    }
    
    var totalSugar: Double {
        meals.reduce(0) { $0 + $1.totalSugar } + liquidIntake.reduce(0) { $0 + $1.sugar }
    }
    
    var totalLiquid: Double {
        liquidIntake.reduce(0) { $0 + $1.amount }
    }
    
    // Net calories (consumed - burned)
    var netCalories: Double {
        totalCalories - caloriesBurned
    }
    
    init(id: String = UUID().uuidString, date: Date, meals: [LoggedMeal] = [], liquidIntake: [LiquidEntry] = [], caloriesBurned: Double = 0, steps: Int? = nil) {
        self.id = id
        // Normalize date to start of day
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.meals = meals
        self.liquidIntake = liquidIntake
        self.caloriesBurned = caloriesBurned
        self.steps = steps
    }
}

// MARK: - Logged Meal
struct LoggedMeal: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let mealType: MealType
    let items: [MealItem]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalSugar: Double
    let imageUrl: String? // Optional image URL
    
    enum MealType: String, Codable, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snack = "snack"
        
        var displayName: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snack"
            }
        }
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.fill"
            case .snack: return "leaf.fill"
            }
        }
    }
    
    init(id: String = UUID().uuidString, timestamp: Date, mealType: MealType, items: [MealItem], totalCalories: Double, totalProtein: Double, totalCarbs: Double, totalFat: Double, totalSugar: Double, imageUrl: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType
        self.items = items
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.totalSugar = totalSugar
        self.imageUrl = imageUrl
    }
}

// MARK: - Meal Item
struct MealItem: Codable, Identifiable {
    let id: String
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let portionSize: String?
    let quantity: String? // e.g., "1 cup", "200g"
    
    init(id: String = UUID().uuidString, name: String, calories: Double, protein: Double, carbs: Double, fat: Double, sugar: Double, portionSize: String? = nil, quantity: String? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.sugar = sugar
        self.portionSize = portionSize
        self.quantity = quantity
    }
}

// MARK: - Liquid Entry
struct LiquidEntry: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let amount: Double // in liters
    let beverageType: BeverageType
    let beverageName: String? // e.g., "Coca Cola", "Red Wine"
    let calories: Double
    let sugar: Double // Sugar content in grams
    
    enum BeverageType: String, Codable, CaseIterable {
        case water = "water"
        case soda = "soda"
        case softDrink = "soft_drink"
        case juice = "juice"
        case coffee = "coffee"
        case tea = "tea"
        case alcohol = "alcohol"
        case beer = "beer"
        case wine = "wine"
        case liquor = "liquor"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .water: return "Water"
            case .soda: return "Soda"
            case .softDrink: return "Soft Drink"
            case .juice: return "Juice"
            case .coffee: return "Coffee"
            case .tea: return "Tea"
            case .alcohol: return "Alcohol"
            case .beer: return "Beer"
            case .wine: return "Wine"
            case .liquor: return "Liquor"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .soda, .softDrink: return "cup.and.saucer.fill"
            case .juice: return "glass.fill"
            case .coffee: return "cup.fill"
            case .tea: return "cup.and.saucer"
            case .alcohol, .beer, .wine, .liquor: return "wineglass.fill"
            case .other: return "drop"
            }
        }
        
        var color: String {
            switch self {
            case .water: return "blue"
            case .soda, .softDrink: return "brown"
            case .juice: return "orange"
            case .coffee: return "brown"
            case .tea: return "green"
            case .alcohol, .beer, .wine, .liquor: return "red"
            case .other: return "gray"
            }
        }
    }
    
    init(id: String = UUID().uuidString, timestamp: Date, amount: Double, beverageType: BeverageType, beverageName: String? = nil, calories: Double = 0, sugar: Double = 0) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.beverageType = beverageType
        self.beverageName = beverageName
        self.calories = calories
        self.sugar = sugar
    }
}
