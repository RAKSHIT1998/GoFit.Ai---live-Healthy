import Foundation

/// Local meal cache for instant data display
struct CachedMeal: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let items: [CachedMealItem]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalSugar: Double
    let mealType: String
    let synced: Bool // Whether this meal has been synced to backend
    
    struct CachedMealItem: Codable {
        let name: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let sugar: Double
        let portionSize: String?
    }
}

/// Local meal cache service - stores meals immediately for instant UI updates
final class LocalMealCache {
    static let shared = LocalMealCache()
    private init() { load() }
    
    private var meals: [CachedMeal] = []
    private let cacheURL: URL = {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("local_meals_cache.json")
    }()
    
    private let cacheLock = DispatchQueue(label: "local.meal.cache")
    
    // Load cache from disk
    private func load() {
        cacheLock.sync {
            guard FileManager.default.fileExists(atPath: cacheURL.path) else {
                meals = []
                return
            }
            do {
                let data = try Data(contentsOf: cacheURL)
                meals = try JSONDecoder().decode([CachedMeal].self, from: data)
                print("✅ Loaded \(meals.count) cached meals")
            } catch {
                print("⚠️ Failed to load meal cache: \(error)")
                meals = []
            }
        }
    }
    
    // Persist cache to disk
    private func persist() {
        cacheLock.async {
            do {
                let data = try JSONEncoder().encode(self.meals)
                try data.write(to: self.cacheURL, options: [.atomic])
            } catch {
                print("⚠️ Failed to persist meal cache: \(error)")
            }
        }
    }
    
    // Add meal to cache (called immediately when meal is logged)
    func addMeal(_ meal: CachedMeal) {
        cacheLock.sync {
            meals.insert(meal, at: 0) // Add to beginning for newest first
            // Keep only last 1000 meals to prevent cache bloat
            if meals.count > 1000 {
                meals = Array(meals.prefix(1000))
            }
            persist()
            print("✅ Added meal to local cache: \(meal.id)")
        }
    }
    
    // Mark meal as synced
    func markSynced(mealId: String) {
        cacheLock.sync {
            if let index = meals.firstIndex(where: { $0.id == mealId }) {
                let existingMeal = meals[index]
                // Create new meal with synced flag
                let syncedMeal = CachedMeal(
                    id: existingMeal.id,
                    timestamp: existingMeal.timestamp,
                    items: existingMeal.items,
                    totalCalories: existingMeal.totalCalories,
                    totalProtein: existingMeal.totalProtein,
                    totalCarbs: existingMeal.totalCarbs,
                    totalFat: existingMeal.totalFat,
                    totalSugar: existingMeal.totalSugar,
                    mealType: existingMeal.mealType,
                    synced: true
                )
                meals[index] = syncedMeal
                persist()
            }
        }
    }
    
    // Get all meals
    func getAllMeals() -> [CachedMeal] {
        return cacheLock.sync { meals }
    }
    
    // Get today's meals
    func getTodayMeals() -> [CachedMeal] {
        return cacheLock.sync {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return meals.filter { calendar.startOfDay(for: $0.timestamp) == today }
        }
    }
    
    // Get today's nutrition totals
    func getTodayTotals() -> (calories: Double, protein: Double, carbs: Double, fat: Double, sugar: Double) {
        let todayMeals = getTodayMeals()
        let totals = todayMeals.reduce((calories: 0.0, protein: 0.0, carbs: 0.0, fat: 0.0, sugar: 0.0)) { acc, meal in
            (
                calories: acc.calories + meal.totalCalories,
                protein: acc.protein + meal.totalProtein,
                carbs: acc.carbs + meal.totalCarbs,
                fat: acc.fat + meal.totalFat,
                sugar: acc.sugar + meal.totalSugar
            )
        }
        return totals
    }
    
    // Remove meal from cache
    func removeMeal(mealId: String) {
        cacheLock.sync {
            meals.removeAll { $0.id == mealId }
            persist()
        }
    }
    
    // Clear all cache
    func clearAll() {
        cacheLock.sync {
            meals.removeAll()
            persist()
        }
    }
    
    // Clear old meals (older than 30 days)
    func clearOldMeals() {
        cacheLock.sync {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            meals = meals.filter { $0.timestamp >= thirtyDaysAgo }
            persist()
        }
    }
}

