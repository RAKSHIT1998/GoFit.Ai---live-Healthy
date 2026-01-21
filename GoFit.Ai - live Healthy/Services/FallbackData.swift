import Foundation

// MARK: - Fallback Data Service
// Provides 100+ built-in meals and 100+ workouts when API fails or server is down
struct FallbackDataService {
    static let shared = FallbackDataService()
    
    // MARK: - Get Daily Rotating Meals (50+ options, changes every day)
    func getRandomMeals(goal: String = "maintain", count: Int = 4, useTimestamp: Bool = false, dietaryPreferences: [String] = []) -> MealPlan {
        var allMeals = getAllMeals(goal: goal)
        
        // Filter meals based on dietary preferences
        if !dietaryPreferences.isEmpty {
            allMeals = allMeals.filter { meal in
                !violatesDietaryPreference(meal: meal, dietaryPreferences: dietaryPreferences)
            }
        }
        
        // Use timestamp for refresh (different each time) or day of year for consistent daily rotation
        let seed: UInt64
        if useTimestamp {
            // Use current timestamp for truly random selection on each refresh
            seed = UInt64(Date().timeIntervalSince1970)
        } else {
            // Use day of year as seed for consistent daily rotation
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            seed = UInt64(dayOfYear)
        }
        
        // Create seeded random number generator
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        // Shuffle using seeded generator
        let shuffled = allMeals.shuffled(using: &generator)
        
        return MealPlan(
            breakfast: Array(shuffled.filter { $0.category == "breakfast" }.prefix(2).map { $0.toMealItem() }),
            lunch: Array(shuffled.filter { $0.category == "lunch" }.prefix(2).map { $0.toMealItem() }),
            dinner: Array(shuffled.filter { $0.category == "dinner" }.prefix(2).map { $0.toMealItem() }),
            snacks: Array(shuffled.filter { $0.category == "snack" }.prefix(2).map { $0.toMealItem() })
        )
    }
    
    // MARK: - Check if meal violates dietary preferences
    private func violatesDietaryPreference(meal: MealData, dietaryPreferences: [String]) -> Bool {
        let mealName = meal.name.lowercased()
        let ingredients = meal.ingredients.joined(separator: " ").lowercased()
        var allText = "\(mealName) \(ingredients)"

        // IMPORTANT:
        // We use keyword-based filtering for dietary preferences. Some vegan items contain words like "milk"
        // (e.g., "almond milk", "oat milk", "coconut milk") and would be incorrectly flagged as non-vegan.
        // To prevent false positives, remove/neutralize common plant-based phrases before scanning.
        if dietaryPreferences.contains("vegan") {
            let veganAllowPhrases: [String] = [
                // Plant milks
                "almond milk", "oat milk", "soy milk", "coconut milk", "cashew milk", "rice milk", "pea milk",
                // Plant creams
                "coconut cream", "cashew cream",
                // Vegan replacements (still contain dairy keywords)
                "vegan cheese", "plant-based cheese", "dairy-free cheese",
                "vegan butter", "plant-based butter",
                "vegan mayo", "plant-based mayo"
            ]
            for phrase in veganAllowPhrases {
                // Replace with a token that won't match dairy/meat keywords.
                allText = allText.replacingOccurrences(of: phrase, with: phrase.replacingOccurrences(of: " ", with: "_"))
            }
        }
        
        // Non-vegan items - comprehensive list
        let nonVeganItems = [
            // Meats
            "beef", "pork", "chicken", "turkey", "lamb", "duck", "goose", "venison", "bison", "rabbit",
            "meat", "poultry", "red meat", "white meat", "ground beef", "ground pork", "ground turkey",
            "chicken breast", "chicken thigh", "chicken wing", "chicken leg", "chicken drumstick",
            "pork chop", "pork loin", "pork shoulder", "beef steak", "beef roast", "beef burger",
            "turkey breast", "turkey leg", "lamb chop", "lamb shank", "duck breast", "duck leg",
            // Fish and seafood
            "fish", "salmon", "tuna", "cod", "haddock", "mackerel", "sardine", "anchovy", "herring",
            "shrimp", "prawn", "crab", "lobster", "crayfish", "mussel", "oyster", "clam", "scallop",
            "seafood", "shellfish", "squid", "octopus", "calamari",
            // Eggs (all forms) - CRITICAL for vegan
            "egg", "eggs", "scrambled", "scrambled egg", "scrambled eggs", "fried egg", "fried eggs",
            "boiled egg", "boiled eggs", "poached egg", "poached eggs", "omelet", "omelette",
            "frittata", "quiche", "egg white", "egg whites", "egg yolk", "egg yolks",
            "deviled egg", "deviled eggs", "egg salad", "egg sandwich",
            // Dairy products
            "milk", "cheese", "butter", "yogurt", "yoghurt", "cream", "sour cream", "heavy cream",
            "dairy", "whey", "casein", "lactose", "ghee", "buttermilk", "cottage cheese",
            "mozzarella", "cheddar", "parmesan", "feta", "ricotta", "cream cheese",
            // Other animal products
            "honey", "gelatin", "lard", "tallow", "rendered fat",
            // Processed meats
            "bacon", "sausage", "ham", "pepperoni", "salami", "prosciutto", "chorizo", "bologna",
            "hot dog", "hotdog", "frankfurter", "bratwurst", "kielbasa", "pastrami", "corned beef",
            // Broth/stock
            "chicken broth", "beef broth", "fish stock", "bone broth", "chicken stock", "beef stock"
        ]
        
        // Non-vegetarian items (meat and fish, but allow eggs/dairy)
        let nonVegetarianItems = [
            // Meats - CRITICAL for vegetarian
            "beef", "pork", "chicken", "turkey", "lamb", "duck", "goose", "venison", "bison", "rabbit",
            "meat", "poultry", "red meat", "white meat", "ground beef", "ground pork", "ground turkey",
            "chicken breast", "chicken thigh", "chicken wing", "chicken leg", "chicken drumstick",
            "pork chop", "pork loin", "pork shoulder", "beef steak", "beef roast", "beef burger",
            "turkey breast", "turkey leg", "lamb chop", "lamb shank", "duck breast", "duck leg",
            // Fish and seafood
            "fish", "salmon", "tuna", "cod", "haddock", "mackerel", "sardine", "anchovy", "herring",
            "shrimp", "prawn", "crab", "lobster", "crayfish", "mussel", "oyster", "clam", "scallop",
            "seafood", "shellfish", "squid", "octopus", "calamari",
            // Processed meats
            "bacon", "sausage", "ham", "pepperoni", "salami", "prosciutto", "chorizo", "bologna",
            "hot dog", "hotdog", "frankfurter", "bratwurst", "kielbasa", "pastrami", "corned beef",
            // Broth/stock
            "chicken broth", "beef broth", "fish stock", "bone broth", "chicken stock", "beef stock"
        ]
        
        if dietaryPreferences.contains("vegan") {
            // Check for any non-vegan items - use word boundaries to avoid false positives
            for item in nonVeganItems {
                // Use word boundary matching to avoid false positives (e.g., "chickpea" shouldn't match "chicken")
                // Check if item appears as a whole word or at word boundaries
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: item))\\b"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: allText, range: NSRange(allText.startIndex..., in: allText)) != nil {
                    return true
                }
            }
        } else if dietaryPreferences.contains("vegetarian") {
            // Check for meat/fish but allow eggs/dairy - use word boundaries
            for item in nonVegetarianItems {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: item))\\b"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: allText, range: NSRange(allText.startIndex..., in: allText)) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Get Daily Rotating Workouts (50+ options, changes every day)
    func getRandomWorkouts(activityLevel: String = "moderate", count: Int = 4, useTimestamp: Bool = false) -> WorkoutPlan {
        let allWorkouts = getAllWorkouts(activityLevel: activityLevel)
        
        // Use timestamp for refresh (different each time) or day of year for consistent daily rotation
        let seed: UInt64
        if useTimestamp {
            // Use current timestamp for truly random selection on each refresh
            seed = UInt64(Date().timeIntervalSince1970)
        } else {
            // Use day of year as seed for consistent daily rotation
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            seed = UInt64(dayOfYear)
        }
        
        // Create seeded random number generator
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        // Shuffle using seeded generator
        let shuffled = allWorkouts.shuffled(using: &generator)
        return WorkoutPlan(exercises: Array(shuffled.prefix(count)))
    }
    
    // MARK: - Get Random Meal for Scanning Fallback
    func getRandomMealForScan() -> ParsedMealItem {
        let allMeals = getAllMeals(goal: "maintain")
        return allMeals.randomElement()?.toParsedMealItem() ?? defaultMealItem
    }
    
    // MARK: - All Meals Database (50+ meals)
    private func getAllMeals(goal: String) -> [MealData] {
        var meals: [MealData] = []
        
        // BREAKFAST (20 meals)
        meals.append(contentsOf: [
            MealData(
                name: "Protein-Packed Oatmeal Bowl",
                category: "breakfast",
                calories: 350, protein: 18, carbs: 55, fat: 8,
                ingredients: ["1 cup rolled oats", "1 cup almond milk", "1 scoop protein powder", "1/2 banana", "1 tbsp almond butter", "1 tbsp chia seeds", "1/2 cup blueberries"],
                instructions: "Cook oats with almond milk for 5 minutes. Remove from heat and stir in protein powder. Top with banana, almond butter, chia seeds, and blueberries.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Greek Yogurt Parfait",
                category: "breakfast",
                calories: 280, protein: 20, carbs: 35, fat: 6,
                ingredients: ["1 cup Greek yogurt", "1/2 cup mixed berries", "1 tbsp honey", "2 tbsp granola", "1 tbsp walnuts"],
                instructions: "Layer yogurt, berries, and granola in a glass. Drizzle with honey and top with walnuts.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Avocado Toast with Eggs",
                category: "breakfast",
                calories: 420, protein: 22, carbs: 38, fat: 20,
                ingredients: ["2 slices whole grain bread", "1 avocado", "2 eggs", "Cherry tomatoes", "Salt and pepper", "Red pepper flakes"],
                instructions: "Toast bread. Mash avocado and spread on toast. Top with poached or fried eggs, tomatoes, and seasonings.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Spinach and Feta Omelet",
                category: "breakfast",
                calories: 320, protein: 24, carbs: 8, fat: 22,
                ingredients: ["3 eggs", "1 cup fresh spinach", "2 tbsp feta cheese", "1 tbsp olive oil", "Salt and pepper"],
                instructions: "Whisk eggs. Heat oil in pan, add spinach until wilted. Pour eggs over spinach, add feta. Cook until set, fold in half.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Chia Seed Pudding",
                category: "breakfast",
                calories: 290, protein: 12, carbs: 42, fat: 10,
                ingredients: ["1/4 cup chia seeds", "1 cup almond milk", "1 tbsp maple syrup", "1/2 tsp vanilla", "Fresh berries"],
                instructions: "Mix chia seeds, milk, syrup, and vanilla. Refrigerate overnight. Top with berries before serving.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Whole Grain Pancakes",
                category: "breakfast",
                calories: 380, protein: 15, carbs: 58, fat: 12,
                ingredients: ["1 cup whole wheat flour", "1 egg", "3/4 cup milk", "1 tbsp honey", "1 tsp baking powder", "Berries"],
                instructions: "Mix dry ingredients. Whisk wet ingredients separately. Combine and cook pancakes. Serve with berries.",
                prepTime: 15, servings: 2
            ),
            MealData(
                name: "Breakfast Smoothie Bowl",
                category: "breakfast",
                calories: 340, protein: 18, carbs: 52, fat: 8,
                ingredients: ["1 banana", "1/2 cup frozen berries", "1/2 cup Greek yogurt", "1/4 cup granola", "1 tbsp almond butter"],
                instructions: "Blend banana, berries, and yogurt until smooth. Pour into bowl. Top with granola and almond butter.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Scrambled Eggs with Vegetables",
                category: "breakfast",
                calories: 300, protein: 20, carbs: 12, fat: 20,
                ingredients: ["3 eggs", "1/2 bell pepper", "1/2 onion", "1/2 cup mushrooms", "1 tbsp olive oil", "Salt and pepper"],
                instructions: "Sauté vegetables until tender. Whisk eggs and pour over vegetables. Scramble until cooked through.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Quinoa Breakfast Bowl",
                category: "breakfast",
                calories: 360, protein: 16, carbs: 58, fat: 10,
                ingredients: ["1 cup cooked quinoa", "1/2 cup almond milk", "1/2 banana", "1 tbsp almond butter", "1 tbsp chia seeds", "Cinnamon"],
                instructions: "Heat quinoa with almond milk. Top with banana, almond butter, chia seeds, and cinnamon.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Breakfast Burrito",
                category: "breakfast",
                calories: 450, protein: 28, carbs: 42, fat: 18,
                ingredients: ["1 whole wheat tortilla", "2 eggs", "1/4 cup black beans", "1/4 avocado", "Salsa", "Cheese"],
                instructions: "Scramble eggs. Warm tortilla. Fill with eggs, beans, avocado, salsa, and cheese. Roll and serve.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Egg White Scramble",
                category: "breakfast",
                calories: 250, protein: 28, carbs: 10, fat: 10,
                ingredients: ["6 egg whites", "1/2 cup spinach", "1/4 cup mushrooms", "1 oz feta cheese", "1 tsp olive oil"],
                instructions: "Sauté vegetables. Add egg whites and scramble. Top with feta cheese.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Banana Nut Smoothie",
                category: "breakfast",
                calories: 320, protein: 15, carbs: 45, fat: 10,
                ingredients: ["1 banana", "1 cup almond milk", "1 tbsp almond butter", "1 scoop protein powder", "1/2 tsp cinnamon"],
                instructions: "Blend all ingredients until smooth. Serve immediately.",
                prepTime: 3, servings: 1
            ),
            MealData(
                name: "Breakfast Hash",
                category: "breakfast",
                calories: 380, protein: 22, carbs: 42, fat: 14,
                ingredients: ["1 sweet potato", "2 eggs", "1/2 bell pepper", "1/4 onion", "2 tbsp olive oil", "Herbs"],
                instructions: "Dice and roast sweet potato. Sauté vegetables. Fry eggs. Combine and season.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Protein Waffles",
                category: "breakfast",
                calories: 360, protein: 28, carbs: 38, fat: 10,
                ingredients: ["1 scoop protein powder", "1/2 cup oats", "1 egg", "1/2 banana", "1/4 cup Greek yogurt"],
                instructions: "Blend ingredients until smooth. Cook in waffle iron. Top with Greek yogurt and berries.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Smoked Salmon Toast",
                category: "breakfast",
                calories: 340, protein: 24, carbs: 32, fat: 12,
                ingredients: ["2 slices rye bread", "3 oz smoked salmon", "2 tbsp cream cheese", "Capers", "Red onion", "Dill"],
                instructions: "Toast bread. Spread cream cheese. Top with salmon, capers, onion, and dill.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Breakfast Quiche",
                category: "breakfast",
                calories: 320, protein: 20, carbs: 18, fat: 18,
                ingredients: ["4 eggs", "1/2 cup milk", "1/2 cup spinach", "1/4 cup feta", "1/4 cup mushrooms"],
                instructions: "Whisk eggs and milk. Add vegetables and cheese. Bake at 375°F for 25 minutes.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Acai Bowl",
                category: "breakfast",
                calories: 350, protein: 8, carbs: 58, fat: 12,
                ingredients: ["1 pack frozen acai", "1 banana", "1/2 cup berries", "2 tbsp granola", "1 tbsp coconut flakes"],
                instructions: "Blend acai and banana. Pour into bowl. Top with berries, granola, and coconut.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Breakfast Tacos",
                category: "breakfast",
                calories: 400, protein: 26, carbs: 38, fat: 16,
                ingredients: ["2 corn tortillas", "2 eggs", "1/4 cup black beans", "Salsa", "Avocado", "Cilantro"],
                instructions: "Scramble eggs. Warm tortillas. Fill with eggs, beans, salsa, avocado, and cilantro.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "French Toast",
                category: "breakfast",
                calories: 380, protein: 18, carbs: 52, fat: 12,
                ingredients: ["2 slices whole grain bread", "2 eggs", "1/4 cup milk", "1 tsp vanilla", "Cinnamon", "Berries"],
                instructions: "Dip bread in egg mixture. Cook until golden. Top with berries and cinnamon.",
                prepTime: 12, servings: 1
            )
        ])
        
        // LUNCH (20 meals)
        meals.append(contentsOf: [
            MealData(
                name: "Mediterranean Quinoa Bowl",
                category: "lunch",
                calories: 450, protein: 22, carbs: 60, fat: 15,
                ingredients: ["1 cup cooked quinoa", "150g grilled chicken", "1/2 cup cherry tomatoes", "1/4 cup cucumber", "2 tbsp feta", "2 tbsp olive oil", "Lemon juice"],
                instructions: "Grill chicken and slice. Combine quinoa with vegetables and feta. Top with chicken and drizzle with olive oil and lemon.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Grilled Chicken Salad",
                category: "lunch",
                calories: 380, protein: 35, carbs: 20, fat: 18,
                ingredients: ["150g chicken breast", "Mixed greens", "Cherry tomatoes", "Cucumber", "Red onion", "2 tbsp olive oil", "Lemon vinaigrette"],
                instructions: "Grill chicken and slice. Toss greens with vegetables. Top with chicken and drizzle with dressing.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Turkey and Avocado Wrap",
                category: "lunch",
                calories: 420, protein: 28, carbs: 38, fat: 18,
                ingredients: ["1 whole wheat tortilla", "100g turkey slices", "1/2 avocado", "Lettuce", "Tomato", "Mustard"],
                instructions: "Layer turkey, avocado, lettuce, and tomato on tortilla. Add mustard. Roll tightly and slice.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Lentil Soup",
                category: "lunch",
                calories: 320, protein: 18, carbs: 52, fat: 6,
                ingredients: ["1 cup red lentils", "1 onion", "2 carrots", "2 celery stalks", "4 cups vegetable broth", "Spices"],
                instructions: "Sauté vegetables. Add lentils and broth. Simmer for 30 minutes until lentils are tender. Season to taste.",
                prepTime: 35, servings: 2
            ),
            MealData(
                name: "Salmon Poke Bowl",
                category: "lunch",
                calories: 480, protein: 32, carbs: 55, fat: 16,
                ingredients: ["150g salmon", "1 cup brown rice", "Edamame", "Cucumber", "Avocado", "Sesame seeds", "Soy sauce"],
                instructions: "Cook rice. Cube salmon. Arrange rice in bowl, top with salmon, vegetables, and avocado. Drizzle with soy sauce.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Chicken Stir-Fry",
                category: "lunch",
                calories: 420, protein: 30, carbs: 45, fat: 12,
                ingredients: ["150g chicken", "Mixed vegetables", "1 cup brown rice", "Soy sauce", "Ginger", "Garlic"],
                instructions: "Cook rice. Stir-fry chicken and vegetables with ginger and garlic. Add soy sauce. Serve over rice.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Black Bean Burger",
                category: "lunch",
                calories: 380, protein: 18, carbs: 52, fat: 12,
                ingredients: ["1 black bean patty", "Whole grain bun", "Lettuce", "Tomato", "Onion", "Avocado"],
                instructions: "Cook patty according to package. Toast bun. Assemble burger with vegetables and avocado.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Tuna Salad Sandwich",
                category: "lunch",
                calories: 400, protein: 28, carbs: 42, fat: 14,
                ingredients: ["1 can tuna", "2 tbsp Greek yogurt", "Celery", "Onion", "Whole grain bread", "Lettuce"],
                instructions: "Mix tuna with yogurt, celery, and onion. Spread on bread with lettuce.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Vegetable Curry",
                category: "lunch",
                calories: 360, protein: 12, carbs: 58, fat: 12,
                ingredients: ["Mixed vegetables", "Coconut milk", "Curry paste", "1 cup brown rice", "Cilantro"],
                instructions: "Sauté vegetables. Add curry paste and coconut milk. Simmer until vegetables are tender. Serve over rice.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Chicken Caesar Salad",
                category: "lunch",
                calories: 420, protein: 32, carbs: 25, fat: 20,
                ingredients: ["150g chicken", "Romaine lettuce", "Parmesan cheese", "Caesar dressing", "Croutons"],
                instructions: "Grill chicken and slice. Toss lettuce with dressing. Top with chicken, parmesan, and croutons.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Chicken Wrap",
                category: "lunch",
                calories: 400, protein: 30, carbs: 40, fat: 14,
                ingredients: ["1 whole wheat wrap", "150g grilled chicken", "Lettuce", "Tomato", "Cucumber", "Hummus"],
                instructions: "Warm wrap. Layer chicken, vegetables, and hummus. Roll tightly and serve.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Quinoa Stuffed Bell Peppers",
                category: "lunch",
                calories: 380, protein: 20, carbs: 52, fat: 12,
                ingredients: ["2 bell peppers", "1 cup cooked quinoa", "1/2 cup black beans", "Corn", "Cheese", "Salsa"],
                instructions: "Hollow peppers. Mix quinoa, beans, and corn. Stuff peppers. Top with cheese. Bake at 375°F for 25 minutes.",
                prepTime: 35, servings: 2
            ),
            MealData(
                name: "Beef and Broccoli",
                category: "lunch",
                calories: 440, protein: 35, carbs: 42, fat: 14,
                ingredients: ["150g lean beef", "2 cups broccoli", "1 cup brown rice", "Soy sauce", "Ginger", "Garlic"],
                instructions: "Stir-fry beef and broccoli. Add soy sauce, ginger, and garlic. Serve over rice.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Caprese Salad",
                category: "lunch",
                calories: 360, protein: 18, carbs: 28, fat: 20,
                ingredients: ["Fresh mozzarella", "Tomatoes", "Basil", "2 tbsp olive oil", "Balsamic vinegar"],
                instructions: "Slice mozzarella and tomatoes. Arrange with basil. Drizzle with olive oil and balsamic.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Chicken Teriyaki Bowl",
                category: "lunch",
                calories: 480, protein: 38, carbs: 55, fat: 12,
                ingredients: ["150g chicken", "1 cup brown rice", "Steamed vegetables", "Teriyaki sauce", "Sesame seeds"],
                instructions: "Grill chicken with teriyaki sauce. Cook rice. Steam vegetables. Combine and top with sesame seeds.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Mediterranean Wrap",
                category: "lunch",
                calories: 420, protein: 22, carbs: 45, fat: 18,
                ingredients: ["1 whole wheat wrap", "Hummus", "Feta cheese", "Cucumber", "Tomatoes", "Olives", "Lettuce"],
                instructions: "Spread hummus on wrap. Add vegetables, feta, and olives. Roll and serve.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Chicken and Rice Bowl",
                category: "lunch",
                calories: 460, protein: 40, carbs: 48, fat: 14,
                ingredients: ["150g chicken", "1 cup brown rice", "Black beans", "Corn", "Salsa", "Avocado"],
                instructions: "Grill chicken. Cook rice. Combine with beans, corn, salsa, and avocado.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Greek Salad with Chicken",
                category: "lunch",
                calories: 400, protein: 32, carbs: 22, fat: 20,
                ingredients: ["150g chicken", "Mixed greens", "Feta", "Olives", "Cucumber", "Tomatoes", "Greek dressing"],
                instructions: "Grill chicken. Toss greens with vegetables, feta, and olives. Top with chicken and dressing.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Vegetable Soup",
                category: "lunch",
                calories: 280, protein: 12, carbs: 45, fat: 8,
                ingredients: ["Mixed vegetables", "Vegetable broth", "Herbs", "1 cup whole grain bread"],
                instructions: "Sauté vegetables. Add broth and herbs. Simmer 20 minutes. Serve with bread.",
                prepTime: 30, servings: 2
            )
        ])
        
        // DINNER (20 meals)
        meals.append(contentsOf: [
            MealData(
                name: "Herb-Crusted Salmon",
                category: "dinner",
                calories: 520, protein: 38, carbs: 35, fat: 22,
                ingredients: ["200g salmon", "Mixed vegetables", "2 tbsp olive oil", "Fresh herbs", "Lemon"],
                instructions: "Preheat oven to 400°F. Rub salmon with herbs and oil. Roast with vegetables for 15-18 minutes. Serve with lemon.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Lean Beef Steak",
                category: "dinner",
                calories: 480, protein: 42, carbs: 30, fat: 20,
                ingredients: ["200g lean steak", "Sweet potato", "Broccoli", "Olive oil", "Garlic"],
                instructions: "Season and grill steak. Roast sweet potato and broccoli. Serve together.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Grilled Chicken Breast",
                category: "dinner",
                calories: 450, protein: 40, carbs: 35, fat: 16,
                ingredients: ["200g chicken breast", "Quinoa", "Asparagus", "Lemon", "Herbs"],
                instructions: "Grill chicken with herbs. Cook quinoa. Steam asparagus. Serve together with lemon.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Shrimp Scampi",
                category: "dinner",
                calories: 420, protein: 32, carbs: 45, fat: 14,
                ingredients: ["200g shrimp", "Whole wheat pasta", "Garlic", "White wine", "Lemon", "Parsley"],
                instructions: "Cook pasta. Sauté shrimp with garlic. Add wine and lemon. Toss with pasta and parsley.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Turkey Meatballs",
                category: "dinner",
                calories: 460, protein: 35, carbs: 42, fat: 18,
                ingredients: ["200g ground turkey", "Whole wheat pasta", "Marinara sauce", "Parmesan", "Herbs"],
                instructions: "Form meatballs and bake. Cook pasta. Heat sauce. Combine and top with parmesan.",
                prepTime: 35, servings: 1
            ),
            MealData(
                name: "Baked Cod",
                category: "dinner",
                calories: 380, protein: 32, carbs: 38, fat: 12,
                ingredients: ["200g cod", "Brown rice", "Green beans", "Lemon", "Herbs"],
                instructions: "Season cod and bake at 375°F for 15 minutes. Cook rice and steam beans. Serve together.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Chicken Fajitas",
                category: "dinner",
                calories: 480, protein: 38, carbs: 45, fat: 18,
                ingredients: ["200g chicken", "Bell peppers", "Onion", "Whole wheat tortillas", "Salsa", "Avocado"],
                instructions: "Sauté chicken and vegetables. Warm tortillas. Serve with salsa and avocado.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Pork Tenderloin",
                category: "dinner",
                calories: 440, protein: 40, carbs: 32, fat: 16,
                ingredients: ["200g pork tenderloin", "Sweet potato", "Brussels sprouts", "Apple sauce"],
                instructions: "Roast pork at 400°F for 25 minutes. Roast vegetables. Serve with apple sauce.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Vegetarian Stuffed Peppers",
                category: "dinner",
                calories: 380, protein: 18, carbs: 55, fat: 12,
                ingredients: ["Bell peppers", "Quinoa", "Black beans", "Corn", "Cheese", "Salsa"],
                instructions: "Hollow out peppers. Mix quinoa, beans, and corn. Stuff peppers, top with cheese. Bake at 375°F for 30 minutes.",
                prepTime: 40, servings: 2
            ),
            MealData(
                name: "Baked Chicken Thighs",
                category: "dinner",
                calories: 460, protein: 36, carbs: 35, fat: 20,
                ingredients: ["200g chicken thighs", "Roasted vegetables", "Quinoa", "Herbs"],
                instructions: "Season chicken and roast at 400°F for 30 minutes. Roast vegetables. Cook quinoa. Serve together.",
                prepTime: 35, servings: 1
            ),
            MealData(
                name: "Grilled Tuna Steak",
                category: "dinner",
                calories: 420, protein: 45, carbs: 25, fat: 16,
                ingredients: ["200g tuna steak", "Quinoa", "Asparagus", "Lemon", "Herbs"],
                instructions: "Season and grill tuna 3-4 minutes per side. Cook quinoa. Steam asparagus. Serve with lemon.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Chicken Tikka Masala",
                category: "dinner",
                calories: 480, protein: 38, carbs: 48, fat: 16,
                ingredients: ["200g chicken", "Tikka masala sauce", "1 cup brown rice", "Naan bread"],
                instructions: "Cook chicken in sauce. Serve over rice with naan bread.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Beef Stir-Fry",
                category: "dinner",
                calories: 460, protein: 40, carbs: 45, fat: 16,
                ingredients: ["200g lean beef", "Mixed vegetables", "1 cup brown rice", "Soy sauce", "Ginger"],
                instructions: "Stir-fry beef and vegetables. Add soy sauce and ginger. Serve over rice.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Baked Tilapia",
                category: "dinner",
                calories: 380, protein: 35, carbs: 32, fat: 12,
                ingredients: ["200g tilapia", "Brown rice", "Steamed vegetables", "Lemon", "Herbs"],
                instructions: "Season fish and bake at 375°F for 15 minutes. Cook rice. Steam vegetables. Serve together.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Chicken Enchiladas",
                category: "dinner",
                calories: 500, protein: 38, carbs: 48, fat: 18,
                ingredients: ["200g chicken", "Whole wheat tortillas", "Enchilada sauce", "Cheese", "Black beans"],
                instructions: "Shred chicken. Fill tortillas with chicken and beans. Top with sauce and cheese. Bake at 375°F for 20 minutes.",
                prepTime: 35, servings: 2
            ),
            MealData(
                name: "Lamb Chops",
                category: "dinner",
                calories: 520, protein: 42, carbs: 30, fat: 24,
                ingredients: ["200g lamb chops", "Roasted vegetables", "Quinoa", "Mint sauce"],
                instructions: "Season and grill lamb chops. Roast vegetables. Cook quinoa. Serve with mint sauce.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Chicken and Vegetable Skewers",
                category: "dinner",
                calories: 440, protein: 40, carbs: 35, fat: 16,
                ingredients: ["200g chicken", "Bell peppers", "Zucchini", "Onion", "Olive oil", "Herbs"],
                instructions: "Thread chicken and vegetables on skewers. Grill until cooked. Serve with quinoa.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Baked Ziti",
                category: "dinner",
                calories: 480, protein: 32, carbs: 52, fat: 16,
                ingredients: ["Whole wheat ziti", "Marinara sauce", "Ricotta cheese", "Mozzarella", "Parmesan"],
                instructions: "Cook pasta. Layer with sauce and cheeses. Bake at 375°F for 25 minutes.",
                prepTime: 40, servings: 2
            ),
            MealData(
                name: "Grilled Swordfish",
                category: "dinner",
                calories: 400, protein: 38, carbs: 30, fat: 16,
                ingredients: ["200g swordfish", "Brown rice", "Roasted vegetables", "Lemon", "Herbs"],
                instructions: "Season and grill swordfish. Cook rice. Roast vegetables. Serve together with lemon.",
                prepTime: 25, servings: 1
            )
        ])
        
        // SNACKS (15 meals)
        meals.append(contentsOf: [
            MealData(
                name: "Apple with Almond Butter",
                category: "snack",
                calories: 200, protein: 6, carbs: 28, fat: 10,
                ingredients: ["1 medium apple", "2 tbsp almond butter"],
                instructions: "Slice apple and serve with almond butter for dipping.",
                prepTime: 2, servings: 1
            ),
            MealData(
                name: "Greek Yogurt with Berries",
                category: "snack",
                calories: 150, protein: 15, carbs: 20, fat: 2,
                ingredients: ["1 cup Greek yogurt", "1/2 cup mixed berries", "1 tsp honey"],
                instructions: "Top yogurt with berries and drizzle with honey.",
                prepTime: 2, servings: 1
            ),
            MealData(
                name: "Protein Smoothie",
                category: "snack",
                calories: 220, protein: 25, carbs: 25, fat: 4,
                ingredients: ["1 scoop protein powder", "1 banana", "1 cup almond milk", "1 tbsp almond butter"],
                instructions: "Blend all ingredients until smooth. Serve immediately.",
                prepTime: 3, servings: 1
            ),
            MealData(
                name: "Hummus with Vegetables",
                category: "snack",
                calories: 180, protein: 8, carbs: 22, fat: 8,
                ingredients: ["1/2 cup hummus", "Carrot sticks", "Celery sticks", "Bell pepper strips"],
                instructions: "Serve hummus with fresh vegetable sticks for dipping.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Trail Mix",
                category: "snack",
                calories: 200, protein: 6, carbs: 18, fat: 12,
                ingredients: ["Mixed nuts", "Dried fruit", "Dark chocolate chips"],
                instructions: "Combine equal parts nuts, dried fruit, and chocolate chips.",
                prepTime: 2, servings: 1
            ),
            MealData(
                name: "Rice Cakes with Peanut Butter",
                category: "snack",
                calories: 180, protein: 8, carbs: 22, fat: 8,
                ingredients: ["2 rice cakes", "2 tbsp peanut butter", "Banana slices"],
                instructions: "Spread peanut butter on rice cakes and top with banana slices.",
                prepTime: 3, servings: 1
            ),
            MealData(
                name: "Cottage Cheese with Fruit",
                category: "snack",
                calories: 160, protein: 18, carbs: 18, fat: 2,
                ingredients: ["1/2 cup cottage cheese", "1/2 cup mixed berries", "1 tsp honey"],
                instructions: "Top cottage cheese with berries and drizzle with honey.",
                prepTime: 2, servings: 1
            ),
            MealData(
                name: "Hard-Boiled Eggs",
                category: "snack",
                calories: 140, protein: 12, carbs: 1, fat: 10,
                ingredients: ["2 hard-boiled eggs", "Salt and pepper"],
                instructions: "Boil eggs for 8-10 minutes. Cool, peel, and season with salt and pepper.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Protein Bar",
                category: "snack",
                calories: 200, protein: 20, carbs: 22, fat: 6,
                ingredients: ["1 protein bar"],
                instructions: "Enjoy as a convenient on-the-go snack.",
                prepTime: 0, servings: 1
            ),
            MealData(
                name: "Vegetable Sticks with Guacamole",
                category: "snack",
                calories: 190, protein: 4, carbs: 18, fat: 14,
                ingredients: ["1/2 avocado", "Lime juice", "Salt", "Vegetable sticks"],
                instructions: "Mash avocado with lime and salt. Serve with vegetable sticks.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Protein Shake",
                category: "snack",
                calories: 200, protein: 30, carbs: 15, fat: 3,
                ingredients: ["1 scoop protein powder", "1 cup water", "1/2 banana", "Ice"],
                instructions: "Blend all ingredients until smooth. Serve immediately.",
                prepTime: 2, servings: 1
            ),
            MealData(
                name: "Almonds and Dried Cranberries",
                category: "snack",
                calories: 180, protein: 6, carbs: 20, fat: 10,
                ingredients: ["1/4 cup almonds", "2 tbsp dried cranberries"],
                instructions: "Mix almonds and cranberries. Enjoy as a healthy snack.",
                prepTime: 1, servings: 1
            ),
            MealData(
                name: "Cheese and Crackers",
                category: "snack",
                calories: 200, protein: 10, carbs: 22, fat: 8,
                ingredients: ["2 oz cheese", "6 whole grain crackers", "Apple slices"],
                instructions: "Serve cheese with crackers and apple slices.",
                prepTime: 3, servings: 1
            ),
            MealData(
                name: "Edamame",
                category: "snack",
                calories: 120, protein: 11, carbs: 10, fat: 5,
                ingredients: ["1 cup edamame", "Sea salt"],
                instructions: "Steam edamame. Season with sea salt. Enjoy warm.",
                prepTime: 5, servings: 1
            ),
            // Additional vegan snacks
            MealData(
                name: "Vegan Protein Smoothie",
                category: "snack",
                calories: 210, protein: 22, carbs: 28, fat: 4,
                ingredients: ["1 scoop vegan protein powder", "1 banana", "1 cup oat milk", "1 tbsp chia seeds"],
                instructions: "Blend all ingredients until smooth. Serve immediately.",
                prepTime: 3, servings: 1
            ),
            MealData(
                name: "Roasted Chickpeas",
                category: "snack",
                calories: 150, protein: 8, carbs: 22, fat: 4,
                ingredients: ["1 cup chickpeas", "1 tbsp olive oil", "Spices"],
                instructions: "Toss chickpeas with oil and spices. Roast at 400°F for 25 minutes until crispy.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Vegan Energy Balls",
                category: "snack",
                calories: 180, protein: 6, carbs: 20, fat: 10,
                ingredients: ["Dates", "Almonds", "Cocoa powder", "Coconut flakes"],
                instructions: "Blend dates and almonds. Add cocoa and coconut. Form into balls. Refrigerate.",
                prepTime: 15, servings: 4
            )
        ])
        
        // Add more VEGAN meals (30+ additional meals)
        meals.append(contentsOf: [
            // Vegan Breakfast (10 more)
            MealData(
                name: "Vegan Scrambled Tofu",
                category: "breakfast",
                calories: 280, protein: 20, carbs: 12, fat: 18,
                ingredients: ["200g firm tofu", "1 tbsp nutritional yeast", "Turmeric", "Black salt", "1 tbsp olive oil", "Spinach"],
                instructions: "Crumble tofu. Sauté with oil, turmeric, and nutritional yeast. Add spinach. Season with black salt.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Vegan Pancakes",
                category: "breakfast",
                calories: 320, protein: 10, carbs: 55, fat: 8,
                ingredients: ["1 cup whole wheat flour", "1 cup plant milk", "1 tbsp maple syrup", "1 tsp baking powder", "1 tbsp flaxseed meal"],
                instructions: "Mix dry ingredients. Add wet ingredients. Cook pancakes. Serve with berries.",
                prepTime: 15, servings: 2
            ),
            MealData(
                name: "Vegan Breakfast Burrito",
                category: "breakfast",
                calories: 380, protein: 18, carbs: 52, fat: 12,
                ingredients: ["1 whole wheat tortilla", "Scrambled tofu", "Black beans", "Avocado", "Salsa"],
                instructions: "Scramble tofu. Warm tortilla. Fill with tofu, beans, avocado, and salsa. Roll and serve.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Vegan Overnight Oats",
                category: "breakfast",
                calories: 340, protein: 14, carbs: 58, fat: 10,
                ingredients: ["1 cup rolled oats", "1 cup almond milk", "1 tbsp chia seeds", "1/2 banana", "Berries", "1 tbsp almond butter"],
                instructions: "Mix oats, milk, and chia seeds. Refrigerate overnight. Top with banana, berries, and almond butter.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Vegan Smoothie Bowl",
                category: "breakfast",
                calories: 360, protein: 12, carbs: 62, fat: 10,
                ingredients: ["1 banana", "1/2 cup frozen berries", "1 cup plant milk", "Granola", "Coconut flakes", "Chia seeds"],
                instructions: "Blend banana, berries, and milk. Pour into bowl. Top with granola, coconut, and chia seeds.",
                prepTime: 5, servings: 1
            ),
            MealData(
                name: "Vegan French Toast",
                category: "breakfast",
                calories: 320, protein: 10, carbs: 55, fat: 8,
                ingredients: ["2 slices whole grain bread", "1 cup plant milk", "1 tbsp flaxseed meal", "1 tsp vanilla", "Cinnamon", "Berries"],
                instructions: "Mix milk, flaxseed, and vanilla. Dip bread. Cook until golden. Top with berries and cinnamon.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Vegan Breakfast Hash",
                category: "breakfast",
                calories: 320, protein: 12, carbs: 48, fat: 10,
                ingredients: ["1 sweet potato", "1/2 bell pepper", "1/4 onion", "Black beans", "2 tbsp olive oil", "Herbs"],
                instructions: "Dice and roast sweet potato. Sauté vegetables and beans. Combine and season.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Vegan Breakfast Bowl",
                category: "breakfast",
                calories: 350, protein: 16, carbs: 55, fat: 10,
                ingredients: ["1 cup cooked quinoa", "1/2 cup plant milk", "1/2 banana", "1 tbsp almond butter", "Berries", "Nuts"],
                instructions: "Heat quinoa with plant milk. Top with banana, almond butter, berries, and nuts.",
                prepTime: 8, servings: 1
            ),
            MealData(
                name: "Vegan Waffles",
                category: "breakfast",
                calories: 340, protein: 12, carbs: 58, fat: 8,
                ingredients: ["1 cup whole wheat flour", "1 cup plant milk", "1 tbsp maple syrup", "1 tsp baking powder", "1 tbsp coconut oil"],
                instructions: "Mix ingredients. Cook in waffle iron. Top with berries and maple syrup.",
                prepTime: 12, servings: 1
            ),
            MealData(
                name: "Vegan Breakfast Tacos",
                category: "breakfast",
                calories: 360, protein: 16, carbs: 52, fat: 10,
                ingredients: ["2 corn tortillas", "Scrambled tofu", "Black beans", "Salsa", "Avocado", "Cilantro"],
                instructions: "Scramble tofu. Warm tortillas. Fill with tofu, beans, salsa, avocado, and cilantro.",
                prepTime: 10, servings: 1
            ),
            
            // Vegan Lunch (10 more)
            MealData(
                name: "Vegan Buddha Bowl",
                category: "lunch",
                calories: 420, protein: 20, carbs: 62, fat: 12,
                ingredients: ["1 cup brown rice", "Chickpeas", "Roasted vegetables", "Tahini dressing", "Greens"],
                instructions: "Cook rice. Roast chickpeas and vegetables. Arrange in bowl with greens. Drizzle with tahini.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Vegan Quinoa Salad",
                category: "lunch",
                calories: 380, protein: 18, carbs: 55, fat: 12,
                ingredients: ["1 cup cooked quinoa", "Black beans", "Corn", "Tomatoes", "Cucumber", "Lime vinaigrette"],
                instructions: "Combine quinoa with beans, corn, and vegetables. Toss with lime vinaigrette.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Vegan Lentil Curry",
                category: "lunch",
                calories: 400, protein: 22, carbs: 58, fat: 12,
                ingredients: ["1 cup red lentils", "Coconut milk", "Curry spices", "1 cup brown rice", "Vegetables"],
                instructions: "Cook lentils with coconut milk and spices. Simmer until tender. Serve over rice with vegetables.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Vegan Tofu Stir-Fry",
                category: "lunch",
                calories: 380, protein: 24, carbs: 48, fat: 10,
                ingredients: ["200g firm tofu", "Mixed vegetables", "1 cup brown rice", "Soy sauce", "Ginger", "Garlic"],
                instructions: "Press and cube tofu. Stir-fry with vegetables, ginger, and garlic. Add soy sauce. Serve over rice.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Vegan Black Bean Soup",
                category: "lunch",
                calories: 320, protein: 18, carbs: 52, fat: 6,
                ingredients: ["2 cups black beans", "Vegetable broth", "Onion", "Garlic", "Cumin", "Lime"],
                instructions: "Sauté onion and garlic. Add beans and broth. Simmer 20 minutes. Season with cumin and lime.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Vegan Falafel Wrap",
                category: "lunch",
                calories: 420, protein: 18, carbs: 58, fat: 14,
                ingredients: ["4 falafel balls", "1 whole wheat wrap", "Hummus", "Lettuce", "Tomato", "Cucumber", "Tahini"],
                instructions: "Warm falafel. Spread hummus on wrap. Add falafel, vegetables, and tahini. Roll and serve.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Vegan Sushi Bowl",
                category: "lunch",
                calories: 400, protein: 16, carbs: 62, fat: 10,
                ingredients: ["1 cup brown rice", "Avocado", "Cucumber", "Carrots", "Edamame", "Sesame seeds", "Soy sauce"],
                instructions: "Cook rice. Arrange rice in bowl. Top with vegetables and edamame. Drizzle with soy sauce and sesame.",
                prepTime: 20, servings: 1
            ),
            MealData(
                name: "Vegan Chickpea Salad Sandwich",
                category: "lunch",
                calories: 380, protein: 20, carbs: 48, fat: 12,
                ingredients: ["1 cup chickpeas", "Vegan mayo", "Celery", "Onion", "Whole grain bread", "Lettuce", "Tomato"],
                instructions: "Mash chickpeas. Mix with mayo, celery, and onion. Spread on bread with lettuce and tomato.",
                prepTime: 10, servings: 1
            ),
            MealData(
                name: "Vegan Pad Thai",
                category: "lunch",
                calories: 440, protein: 18, carbs: 68, fat: 12,
                ingredients: ["Rice noodles", "Tofu", "Bean sprouts", "Carrots", "Peanuts", "Lime", "Tamarind sauce"],
                instructions: "Cook noodles. Stir-fry tofu and vegetables. Toss with sauce. Top with peanuts and lime.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Vegan Mediterranean Bowl",
                category: "lunch",
                calories: 400, protein: 16, carbs: 55, fat: 14,
                ingredients: ["1 cup couscous", "Chickpeas", "Tomatoes", "Cucumber", "Olives", "Tahini", "Lemon"],
                instructions: "Cook couscous. Combine with chickpeas and vegetables. Drizzle with tahini and lemon.",
                prepTime: 15, servings: 1
            ),
            
            // Vegan Dinner (10 more)
            MealData(
                name: "Vegan Mushroom Risotto",
                category: "dinner",
                calories: 420, protein: 14, carbs: 68, fat: 12,
                ingredients: ["1 cup arborio rice", "Mushrooms", "Vegetable broth", "White wine", "Nutritional yeast", "Herbs"],
                instructions: "Sauté mushrooms. Add rice and wine. Gradually add broth, stirring. Finish with nutritional yeast.",
                prepTime: 35, servings: 2
            ),
            MealData(
                name: "Vegan Stuffed Bell Peppers",
                category: "dinner",
                calories: 380, protein: 18, carbs: 58, fat: 10,
                ingredients: ["2 bell peppers", "1 cup cooked quinoa", "Black beans", "Corn", "Salsa", "Vegan cheese"],
                instructions: "Hollow peppers. Mix quinoa, beans, and corn. Stuff peppers. Top with salsa and cheese. Bake at 375°F for 30 minutes.",
                prepTime: 40, servings: 2
            ),
            MealData(
                name: "Vegan Spaghetti with Lentil Bolognese",
                category: "dinner",
                calories: 440, protein: 22, carbs: 72, fat: 8,
                ingredients: ["Whole wheat spaghetti", "Lentils", "Tomato sauce", "Onion", "Garlic", "Herbs"],
                instructions: "Cook pasta. Sauté onion and garlic. Add lentils and tomato sauce. Simmer 20 minutes. Serve over pasta.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Vegan Thai Green Curry",
                category: "dinner",
                calories: 400, protein: 16, carbs: 58, fat: 14,
                ingredients: ["Tofu", "Green curry paste", "Coconut milk", "Vegetables", "1 cup brown rice", "Basil"],
                instructions: "Sauté tofu and vegetables. Add curry paste and coconut milk. Simmer 15 minutes. Serve over rice with basil.",
                prepTime: 30, servings: 2
            ),
            MealData(
                name: "Vegan Cauliflower Steak",
                category: "dinner",
                calories: 360, protein: 14, carbs: 42, fat: 18,
                ingredients: ["1 large cauliflower", "2 tbsp olive oil", "Herbs", "Quinoa", "Roasted vegetables"],
                instructions: "Slice cauliflower into steaks. Roast at 400°F for 25 minutes. Serve with quinoa and vegetables.",
                prepTime: 30, servings: 1
            ),
            MealData(
                name: "Vegan Tempeh Tacos",
                category: "dinner",
                calories: 420, protein: 24, carbs: 52, fat: 12,
                ingredients: ["200g tempeh", "Corn tortillas", "Black beans", "Salsa", "Avocado", "Cabbage slaw"],
                instructions: "Marinate and cook tempeh. Warm tortillas. Fill with tempeh, beans, salsa, avocado, and slaw.",
                prepTime: 25, servings: 1
            ),
            MealData(
                name: "Vegan Zucchini Noodles with Pesto",
                category: "dinner",
                calories: 380, protein: 12, carbs: 28, fat: 28,
                ingredients: ["2 large zucchinis", "Basil pesto (vegan)", "Cherry tomatoes", "Pine nuts", "Nutritional yeast"],
                instructions: "Spiralize zucchini. Toss with pesto and tomatoes. Top with pine nuts and nutritional yeast.",
                prepTime: 15, servings: 1
            ),
            MealData(
                name: "Vegan Chili",
                category: "dinner",
                calories: 400, protein: 20, carbs: 62, fat: 8,
                ingredients: ["Black beans", "Kidney beans", "Tomatoes", "Onion", "Bell pepper", "Chili spices"],
                instructions: "Sauté vegetables. Add beans, tomatoes, and spices. Simmer 30 minutes until thick.",
                prepTime: 40, servings: 2
            ),
            MealData(
                name: "Vegan Sweet Potato Curry",
                category: "dinner",
                calories: 420, protein: 14, carbs: 68, fat: 12,
                ingredients: ["Sweet potatoes", "Chickpeas", "Coconut milk", "Curry spices", "1 cup brown rice", "Spinach"],
                instructions: "Cook sweet potatoes and chickpeas in coconut milk with spices. Add spinach. Serve over rice.",
                prepTime: 35, servings: 2
            ),
            MealData(
                name: "Vegan Eggplant Parmesan",
                category: "dinner",
                calories: 440, protein: 18, carbs: 58, fat: 16,
                ingredients: ["Eggplant", "Marinara sauce", "Vegan cheese", "Breadcrumbs", "Herbs"],
                instructions: "Slice and bread eggplant. Layer with sauce and cheese. Bake at 375°F for 30 minutes.",
                prepTime: 45, servings: 2
            )
        ])

        // MARK: - Generated on-device catalog
        // To ensure we have lots of options *per dietary choice* (especially vegan/vegetarian),
        // generate additional meals from safe ingredient templates. This keeps the app fully functional
        // even without backend/AI.
        meals.append(contentsOf: generateTemplateMeals(dietaryStyle: .vegan))
        meals.append(contentsOf: generateTemplateMeals(dietaryStyle: .vegetarian))
        
        return meals
    }

    // MARK: - Meal generation (on-device, dietary-aware)
    private enum DietaryStyle {
        case vegan
        case vegetarian
    }

    private func generateTemplateMeals(dietaryStyle: DietaryStyle) -> [MealData] {
        // We generate a large list deterministically (no randomness here) to keep the catalog stable.
        // The selection randomness happens later via seeded shuffle.
        let plantProteins = ["tofu", "tempeh", "chickpeas", "lentils", "black beans", "kidney beans", "edamame"]
        let grains = ["brown rice", "quinoa", "whole wheat pasta", "couscous", "rolled oats", "barley"]
        let veggies = ["spinach", "bell pepper", "zucchini", "broccoli", "mushrooms", "carrots", "tomatoes", "cucumber"]
        let saucesVegan = ["tahini lemon sauce", "salsa", "tomato herb sauce", "ginger garlic sauce", "peanut lime sauce"]
        let saucesVegetarian = saucesVegan + ["pesto", "cheese topping", "egg scramble mix"]

        func makeMeal(name: String, category: String, calories: Double, protein: Double, carbs: Double, fat: Double, ingredients: [String], instructions: String) -> MealData {
            MealData(
                name: name,
                category: category,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                ingredients: ingredients,
                instructions: instructions,
                prepTime: 15,
                servings: 1
            )
        }

        let sauces = (dietaryStyle == .vegan) ? saucesVegan : saucesVegetarian

        var generated: [MealData] = []

        // Breakfast templates (40)
        for (i, grain) in grains.enumerated() {
            let v = veggies[i % veggies.count]
            if dietaryStyle == .vegan {
                generated.append(makeMeal(
                    name: "Vegan \(grain.capitalized) Power Bowl \(i+1)",
                    category: "breakfast",
                    calories: 340,
                    protein: 16,
                    carbs: 54,
                    fat: 10,
                    ingredients: ["1 serving \(grain)", v, "chia seeds", "berries", "maple syrup"],
                    instructions: "Combine cooked \(grain) with toppings. Adjust sweetness to taste."
                ))
            } else {
                generated.append(makeMeal(
                    name: "Vegetarian \(grain.capitalized) Power Bowl \(i+1)",
                    category: "breakfast",
                    calories: 360,
                    protein: 18,
                    carbs: 52,
                    fat: 12,
                    ingredients: ["1 serving \(grain)", v, "nuts", "fruit", "optional cheese topping"],
                    instructions: "Combine cooked \(grain) with toppings. Add cheese topping if desired."
                ))
            }
        }
        // Add more breakfast variety
        for idx in 0..<24 {
            let protein = plantProteins[idx % plantProteins.count]
            let v = veggies[(idx + 2) % veggies.count]
            if dietaryStyle == .vegan {
                generated.append(makeMeal(
                    name: "Vegan \(protein.capitalized) Breakfast Skillet \(idx+1)",
                    category: "breakfast",
                    calories: 320,
                    protein: 20,
                    carbs: 34,
                    fat: 12,
                    ingredients: [protein, v, "onion", "olive oil", "spices"],
                    instructions: "Sauté onion and \(v). Add \(protein) and spices. Cook until hot and serve."
                ))
            } else {
                generated.append(makeMeal(
                    name: "Vegetarian \(protein.capitalized) Breakfast Skillet \(idx+1)",
                    category: "breakfast",
                    calories: 340,
                    protein: 22,
                    carbs: 32,
                    fat: 14,
                    ingredients: [protein, v, "onion", "olive oil", "optional egg scramble mix"],
                    instructions: "Sauté onion and \(v). Add \(protein). Optionally add egg scramble mix. Serve hot."
                ))
            }
        }

        // Lunch templates (40)
        for idx in 0..<40 {
            let protein = plantProteins[idx % plantProteins.count]
            let grain = grains[(idx + 1) % grains.count]
            let v = veggies[(idx + 3) % veggies.count]
            let sauce = sauces[idx % sauces.count]
            generated.append(makeMeal(
                name: "\(dietaryStyle == .vegan ? "Vegan" : "Vegetarian") \(protein.capitalized) \(grain.capitalized) Bowl \(idx+1)",
                category: "lunch",
                calories: 420,
                protein: 22,
                carbs: 58,
                fat: 12,
                ingredients: ["1 serving \(grain)", protein, v, "mixed greens", sauce],
                instructions: "Assemble bowl with \(grain), \(protein), and vegetables. Top with \(sauce)."
            ))
        }

        // Dinner templates (40)
        for idx in 0..<40 {
            let protein = plantProteins[(idx + 2) % plantProteins.count]
            let v = veggies[(idx + 5) % veggies.count]
            let sauce = sauces[(idx + 1) % sauces.count]
            generated.append(makeMeal(
                name: "\(dietaryStyle == .vegan ? "Vegan" : "Vegetarian") \(protein.capitalized) Dinner Plate \(idx+1)",
                category: "dinner",
                calories: 440,
                protein: 24,
                carbs: 54,
                fat: 14,
                ingredients: [protein, v, "roasted vegetables", sauce],
                instructions: "Cook \(protein) and roast vegetables. Plate and finish with \(sauce)."
            ))
        }

        // Snack templates (20)
        for idx in 0..<20 {
            let protein = plantProteins[idx % plantProteins.count]
            generated.append(makeMeal(
                name: "\(dietaryStyle == .vegan ? "Vegan" : "Vegetarian") Snack Box \(idx+1)",
                category: "snack",
                calories: 190,
                protein: 10,
                carbs: 22,
                fat: 8,
                ingredients: [protein, "fruit", "nuts", "vegetable sticks"],
                instructions: "Combine protein + fruit + nuts + veggie sticks into a quick snack box."
            ))
        }

        return generated
    }
    
    // MARK: - All Workouts Database (50+ workouts)
    private func getAllWorkouts(activityLevel: String) -> [Exercise] {
        var workouts: [Exercise] = []
        
        // CARDIO (20 workouts)
        workouts.append(contentsOf: [
            Exercise(name: "Brisk Walking", duration: 30, calories: 150, type: "cardio", instructions: "Walk at a brisk pace, maintaining steady speed. Keep head up and shoulders relaxed. Swing arms naturally.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["legs", "core"], equipment: ["none"]),
            Exercise(name: "Running", duration: 30, calories: 300, type: "cardio", instructions: "Start with 5-minute warm-up walk. Run at moderate pace for 20 minutes. Cool down with 5-minute walk.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "cardiovascular"], equipment: ["none"]),
            Exercise(name: "Jump Rope", duration: 15, calories: 200, type: "cardio", instructions: "Jump rope continuously for 30 seconds, rest 30 seconds. Repeat for 15 minutes. Keep core engaged.", sets: nil, reps: "30 seconds on, 30 seconds off", restTime: 30, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["jump rope"]),
            Exercise(name: "Cycling", duration: 45, calories: 400, type: "cardio", instructions: "Cycle at moderate intensity. Maintain steady pace. Keep back straight and core engaged.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["legs", "cardio"], equipment: ["bicycle"]),
            Exercise(name: "HIIT Cardio Blast", duration: 20, calories: 250, type: "cardio", instructions: "Warm up 2 minutes. Alternate 30 seconds high intensity with 30 seconds rest. Exercises: jumping jacks, burpees, mountain climbers, high knees.", sets: nil, reps: "30 seconds on, 30 seconds off", restTime: 30, difficulty: "advanced", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Elliptical Training", duration: 30, calories: 280, type: "cardio", instructions: "Use elliptical at moderate resistance. Maintain steady pace. Keep posture upright.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["legs", "cardio"], equipment: ["elliptical"]),
            Exercise(name: "Stair Climbing", duration: 20, calories: 200, type: "cardio", instructions: "Climb stairs at steady pace. Use handrail if needed. Focus on controlled movements.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "glutes", "cardio"], equipment: ["stairs"]),
            Exercise(name: "Swimming", duration: 30, calories: 350, type: "cardio", instructions: "Swim laps using freestyle stroke. Maintain steady pace. Focus on breathing rhythm.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["pool"]),
            Exercise(name: "Rowing", duration: 25, calories: 300, type: "cardio", instructions: "Row at moderate pace. Keep back straight. Drive with legs, pull with arms.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["rowing machine"]),
            Exercise(name: "Dance Cardio", duration: 30, calories: 250, type: "cardio", instructions: "Follow dance routine or freestyle. Keep moving continuously. Have fun and stay active!", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Interval Running", duration: 25, calories: 320, type: "cardio", instructions: "Warm up 5 minutes. Alternate 2 minutes fast run with 1 minute walk. Repeat 5 times. Cool down 5 minutes.", sets: nil, reps: "2 min fast, 1 min walk", restTime: 60, difficulty: "intermediate", muscleGroups: ["legs", "cardio"], equipment: ["none"]),
            Exercise(name: "Burpees", duration: 15, calories: 180, type: "cardio", instructions: "Start standing. Drop to squat, jump back to plank, do push-up, jump feet forward, jump up. Repeat continuously.", sets: nil, reps: "30 seconds on, 30 seconds off", restTime: 30, difficulty: "advanced", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "High Knees", duration: 10, calories: 100, type: "cardio", instructions: "Run in place, bringing knees up high. Pump arms. Keep core engaged. Move quickly.", sets: nil, reps: "30 seconds on, 30 seconds off", restTime: 30, difficulty: "beginner", muscleGroups: ["legs", "cardio"], equipment: ["none"]),
            Exercise(name: "Jumping Jacks", duration: 10, calories: 80, type: "cardio", instructions: "Jump feet apart while raising arms overhead. Jump back together. Repeat continuously.", sets: nil, reps: "30 seconds on, 30 seconds off", restTime: 30, difficulty: "beginner", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Box Jumps", duration: 15, calories: 150, type: "cardio", instructions: "Jump onto box or platform. Step down. Repeat. Start with lower height, progress gradually.", sets: nil, reps: "10-15 reps", restTime: 60, difficulty: "intermediate", muscleGroups: ["legs", "cardio"], equipment: ["box"]),
            Exercise(name: "Sprint Intervals", duration: 20, calories: 280, type: "cardio", instructions: "Warm up 3 minutes. Sprint 30 seconds, walk 90 seconds. Repeat 8 times. Cool down 3 minutes.", sets: nil, reps: "30 sec sprint, 90 sec walk", restTime: 90, difficulty: "advanced", muscleGroups: ["legs", "cardio"], equipment: ["none"]),
            Exercise(name: "Kickboxing", duration: 30, calories: 300, type: "cardio", instructions: "Perform kickboxing combinations. Focus on form and power. Keep moving continuously.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Rowing Machine Intervals", duration: 25, calories: 320, type: "cardio", instructions: "Row hard for 1 minute, easy for 1 minute. Repeat 10 times. Focus on form.", sets: nil, reps: "1 min hard, 1 min easy", restTime: 60, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["rowing machine"]),
            Exercise(name: "StairMaster", duration: 20, calories: 220, type: "cardio", instructions: "Use StairMaster at moderate pace. Maintain steady rhythm. Keep posture upright.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "glutes", "cardio"], equipment: ["stairmaster"])
        ])
        
        // STRENGTH (25 workouts)
        workouts.append(contentsOf: [
            Exercise(name: "Bodyweight Squats", duration: 10, calories: 50, type: "strength", instructions: "Stand with feet shoulder-width apart. Lower hips back and down as if sitting. Keep chest up. Return to standing.", sets: 3, reps: "12-15", restTime: 60, difficulty: "beginner", muscleGroups: ["legs", "glutes"], equipment: ["none"]),
            Exercise(name: "Push-ups", duration: 10, calories: 50, type: "strength", instructions: "Start in plank position. Lower body until chest nearly touches floor. Push back up. Keep core tight.", sets: 3, reps: "10-12", restTime: 60, difficulty: "beginner", muscleGroups: ["chest", "triceps", "shoulders"], equipment: ["none"]),
            Exercise(name: "Plank", duration: 5, calories: 30, type: "strength", instructions: "Hold plank position. Keep body in straight line from head to heels. Engage core. Breathe steadily.", sets: 3, reps: "30 seconds", restTime: 45, difficulty: "beginner", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "Lunges", duration: 12, calories: 60, type: "strength", instructions: "Step forward into lunge. Lower back knee toward ground. Push through front heel to return. Alternate legs.", sets: 3, reps: "10 each leg", restTime: 60, difficulty: "beginner", muscleGroups: ["legs", "glutes"], equipment: ["none"]),
            Exercise(name: "Dumbbell Rows", duration: 15, calories: 80, type: "strength", instructions: "Bend forward slightly. Pull dumbbells to sides. Squeeze shoulder blades. Lower with control.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["back", "biceps"], equipment: ["dumbbells"]),
            Exercise(name: "Shoulder Press", duration: 12, calories: 70, type: "strength", instructions: "Press dumbbells overhead. Keep core engaged. Lower with control. Don't lock elbows.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["shoulders", "triceps"], equipment: ["dumbbells"]),
            Exercise(name: "Deadlifts", duration: 15, calories: 90, type: "strength", instructions: "Stand with feet hip-width. Hinge at hips, lower weight. Keep back straight. Drive through heels to stand.", sets: 3, reps: "8-10", restTime: 90, difficulty: "advanced", muscleGroups: ["legs", "back", "glutes"], equipment: ["barbell"]),
            Exercise(name: "Bicep Curls", duration: 10, calories: 40, type: "strength", instructions: "Curl dumbbells to shoulders. Keep elbows still. Lower with control. Don't swing.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["biceps"], equipment: ["dumbbells"]),
            Exercise(name: "Tricep Dips", duration: 10, calories: 45, type: "strength", instructions: "Sit on edge of chair. Lower body by bending arms. Push back up. Keep elbows pointing back.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["triceps"], equipment: ["chair"]),
            Exercise(name: "Leg Press", duration: 15, calories: 100, type: "strength", instructions: "Press weight with legs. Lower with control. Don't lock knees. Keep core engaged.", sets: 3, reps: "12-15", restTime: 60, difficulty: "intermediate", muscleGroups: ["legs", "glutes"], equipment: ["leg press machine"]),
            Exercise(name: "Chest Press", duration: 12, calories: 80, type: "strength", instructions: "Press dumbbells from chest. Keep core engaged. Lower with control. Don't arch back excessively.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["chest", "triceps"], equipment: ["dumbbells", "bench"]),
            Exercise(name: "Lat Pulldowns", duration: 12, calories: 75, type: "strength", instructions: "Pull bar to chest. Squeeze shoulder blades. Lower with control. Keep core engaged.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["back", "biceps"], equipment: ["cable machine"]),
            Exercise(name: "Romanian Deadlifts", duration: 12, calories: 70, type: "strength", instructions: "Hinge at hips, lower weight. Keep legs mostly straight. Feel stretch in hamstrings. Return to standing.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["hamstrings", "glutes"], equipment: ["dumbbells"]),
            Exercise(name: "Overhead Squats", duration: 10, calories: 60, type: "strength", instructions: "Hold weight overhead. Squat down. Keep weight stable. Return to standing. Advanced movement.", sets: 3, reps: "8-10", restTime: 90, difficulty: "advanced", muscleGroups: ["legs", "shoulders", "core"], equipment: ["barbell"]),
            Exercise(name: "Bulgarian Split Squats", duration: 12, calories: 65, type: "strength", instructions: "Place back foot on bench. Lunge down with front leg. Push through front heel. Alternate legs.", sets: 3, reps: "10 each leg", restTime: 60, difficulty: "intermediate", muscleGroups: ["legs", "glutes"], equipment: ["bench"]),
            Exercise(name: "Calf Raises", duration: 8, calories: 30, type: "strength", instructions: "Rise onto toes. Hold briefly. Lower with control. Can use weights for added resistance.", sets: 3, reps: "15-20", restTime: 30, difficulty: "beginner", muscleGroups: ["calves"], equipment: ["none"]),
            Exercise(name: "Hammer Curls", duration: 10, calories: 40, type: "strength", instructions: "Curl dumbbells with neutral grip. Keep elbows still. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["biceps", "forearms"], equipment: ["dumbbells"]),
            Exercise(name: "Lateral Raises", duration: 10, calories: 35, type: "strength", instructions: "Raise dumbbells to sides. Keep slight bend in elbows. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["shoulders"], equipment: ["dumbbells"]),
            Exercise(name: "Front Raises", duration: 10, calories: 35, type: "strength", instructions: "Raise dumbbells in front. Keep core engaged. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["shoulders"], equipment: ["dumbbells"]),
            Exercise(name: "Chest Flyes", duration: 12, calories: 60, type: "strength", instructions: "Fly dumbbells out and together. Keep slight bend in elbows. Control the movement.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["chest"], equipment: ["dumbbells", "bench"]),
            Exercise(name: "Goblet Squats", duration: 12, calories: 70, type: "strength", instructions: "Hold dumbbell at chest. Squat down keeping chest up. Drive through heels to stand.", sets: 3, reps: "12-15", restTime: 60, difficulty: "beginner", muscleGroups: ["legs", "glutes"], equipment: ["dumbbell"]),
            Exercise(name: "Bent-Over Rows", duration: 12, calories: 75, type: "strength", instructions: "Bend forward, pull dumbbells to lower chest. Squeeze shoulder blades. Lower with control.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["back", "biceps"], equipment: ["dumbbells"]),
            Exercise(name: "Arnold Press", duration: 12, calories: 70, type: "strength", instructions: "Start with palms facing you. Rotate and press overhead. Reverse motion. Control throughout.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["shoulders"], equipment: ["dumbbells"]),
            Exercise(name: "Sumo Deadlifts", duration: 15, calories: 95, type: "strength", instructions: "Wide stance, toes pointed out. Lower weight between legs. Drive through heels to stand.", sets: 3, reps: "8-10", restTime: 90, difficulty: "advanced", muscleGroups: ["legs", "glutes", "back"], equipment: ["barbell"])
        ])
        
        // CORE (15 workouts)
        workouts.append(contentsOf: [
            Exercise(name: "Russian Twists", duration: 10, calories: 40, type: "strength", instructions: "Sit with knees bent. Lean back slightly. Rotate torso side to side. Keep core engaged.", sets: 3, reps: "20 each side", restTime: 45, difficulty: "beginner", muscleGroups: ["core", "obliques"], equipment: ["mat"]),
            Exercise(name: "Bicycle Crunches", duration: 10, calories: 45, type: "strength", instructions: "Lie on back. Bring opposite elbow to knee. Alternate sides. Keep core engaged.", sets: 3, reps: "20 each side", restTime: 45, difficulty: "beginner", muscleGroups: ["core", "obliques"], equipment: ["mat"]),
            Exercise(name: "Dead Bug", duration: 8, calories: 30, type: "strength", instructions: "Lie on back. Lower opposite arm and leg. Return. Alternate sides. Keep lower back pressed to floor.", sets: 3, reps: "10 each side", restTime: 30, difficulty: "beginner", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "Leg Raises", duration: 10, calories: 40, type: "strength", instructions: "Lie on back. Raise legs to 90 degrees. Lower with control. Keep lower back pressed down.", sets: 3, reps: "12-15", restTime: 45, difficulty: "intermediate", muscleGroups: ["core", "hip flexors"], equipment: ["mat"]),
            Exercise(name: "Side Plank", duration: 8, calories: 35, type: "strength", instructions: "Hold side plank. Keep body in straight line. Don't let hips sag. Hold for time.", sets: 3, reps: "30 seconds each side", restTime: 30, difficulty: "intermediate", muscleGroups: ["core", "obliques"], equipment: ["mat"]),
            Exercise(name: "Mountain Climbers", duration: 10, calories: 50, type: "cardio", instructions: "Start in plank. Alternate bringing knees to chest. Keep core engaged. Move quickly.", sets: nil, reps: "30 seconds", restTime: 30, difficulty: "intermediate", muscleGroups: ["core", "cardio"], equipment: ["none"]),
            Exercise(name: "Flutter Kicks", duration: 8, calories: 35, type: "strength", instructions: "Lie on back. Alternately kick legs. Keep lower back pressed down. Keep core engaged.", sets: 3, reps: "30 seconds", restTime: 30, difficulty: "beginner", muscleGroups: ["core", "hip flexors"], equipment: ["mat"]),
            Exercise(name: "Hollow Body Hold", duration: 8, calories: 30, type: "strength", instructions: "Lie on back. Raise shoulders and legs. Hold position. Keep core engaged. Breathe steadily.", sets: 3, reps: "30 seconds", restTime: 45, difficulty: "intermediate", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "Reverse Crunches", duration: 8, calories: 35, type: "strength", instructions: "Lie on back. Bring knees to chest. Lift hips slightly. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "V-Ups", duration: 10, calories: 45, type: "strength", instructions: "Lie on back. Simultaneously raise torso and legs. Touch toes if possible. Lower with control.", sets: 3, reps: "10-12", restTime: 60, difficulty: "advanced", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "Bird Dog", duration: 8, calories: 30, type: "strength", instructions: "Start on hands and knees. Extend opposite arm and leg. Hold, return. Alternate sides.", sets: 3, reps: "10 each side", restTime: 30, difficulty: "beginner", muscleGroups: ["core", "back"], equipment: ["mat"]),
            Exercise(name: "Crunches", duration: 10, calories: 40, type: "strength", instructions: "Lie on back, knees bent. Lift shoulders toward knees. Lower with control. Don't pull neck.", sets: 3, reps: "15-20", restTime: 45, difficulty: "beginner", muscleGroups: ["core"], equipment: ["mat"]),
            Exercise(name: "Superman", duration: 8, calories: 30, type: "strength", instructions: "Lie face down. Lift arms and legs simultaneously. Hold briefly. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["core", "back"], equipment: ["mat"]),
            Exercise(name: "Woodchoppers", duration: 10, calories: 45, type: "strength", instructions: "Hold weight with both hands. Rotate torso diagonally from high to low. Alternate sides.", sets: 3, reps: "12 each side", restTime: 45, difficulty: "intermediate", muscleGroups: ["core", "obliques"], equipment: ["dumbbell"])
        ])
        
        // FLEXIBILITY/YOGA (5 workouts)
        workouts.append(contentsOf: [
            Exercise(name: "Yoga Flow", duration: 30, calories: 120, type: "flexibility", instructions: "Flow through sun salutations. Focus on breath. Move mindfully. Hold poses as needed.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Stretching Routine", duration: 20, calories: 60, type: "flexibility", instructions: "Stretch major muscle groups. Hold each stretch 30 seconds. Don't bounce. Breathe deeply.", sets: nil, reps: "30 seconds per stretch", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Pilates Core", duration: 25, calories: 100, type: "strength", instructions: "Perform pilates exercises focusing on core. Move slowly and controlled. Focus on form.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["core", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Mobility Flow", duration: 15, calories: 50, type: "flexibility", instructions: "Move through joint mobility exercises. Focus on range of motion. Move slowly.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "flexibility"], equipment: ["none"]),
            Exercise(name: "Yin Yoga", duration: 45, calories: 80, type: "flexibility", instructions: "Hold passive stretches for 3-5 minutes each. Focus on relaxation. Breathe deeply.", sets: nil, reps: "3-5 minutes per pose", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "flexibility"], equipment: ["mat"])
        ])
        
        // Additional workouts to reach 100+ (40+ more workouts)
        workouts.append(contentsOf: [
            // More Cardio (10)
            Exercise(name: "Treadmill Incline Walk", duration: 30, calories: 200, type: "cardio", instructions: "Walk on treadmill at 5-8% incline. Maintain steady pace. Keep posture upright.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["legs", "cardio"], equipment: ["treadmill"]),
            Exercise(name: "Stationary Bike", duration: 30, calories: 250, type: "cardio", instructions: "Cycle at moderate resistance. Maintain steady pace. Adjust resistance as needed.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["legs", "cardio"], equipment: ["stationary bike"]),
            Exercise(name: "Mountain Biking", duration: 45, calories: 400, type: "cardio", instructions: "Ride on trails or paths. Vary terrain. Maintain control and balance.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "cardio"], equipment: ["mountain bike"]),
            Exercise(name: "Water Aerobics", duration: 30, calories: 180, type: "cardio", instructions: "Perform aerobic exercises in water. Use water resistance. Low impact on joints.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "cardio"], equipment: ["pool"]),
            Exercise(name: "Zumba", duration: 45, calories: 350, type: "cardio", instructions: "Follow dance fitness routine. Move to music. Have fun and stay active!", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Aerobics Class", duration: 45, calories: 320, type: "cardio", instructions: "Follow aerobics routine. Keep moving continuously. Follow instructor cues.", sets: nil, reps: "continuous", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "cardio"], equipment: ["none"]),
            Exercise(name: "Step Aerobics", duration: 30, calories: 280, type: "cardio", instructions: "Step up and down on platform. Follow routine. Keep core engaged.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "cardio"], equipment: ["step platform"]),
            Exercise(name: "Cross Country Skiing", duration: 45, calories: 450, type: "cardio", instructions: "Ski using cross country technique. Maintain rhythm. Full body workout.", sets: nil, reps: "continuous", restTime: nil, difficulty: "advanced", muscleGroups: ["full body", "cardio"], equipment: ["skis"]),
            Exercise(name: "Hiking", duration: 60, calories: 350, type: "cardio", instructions: "Hike on trails. Vary pace and terrain. Enjoy nature while exercising.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["legs", "cardio"], equipment: ["none"]),
            Exercise(name: "Tennis", duration: 45, calories: 380, type: "cardio", instructions: "Play tennis singles or doubles. Move quickly. Focus on form and strategy.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "cardio"], equipment: ["tennis racket"]),
            
            // More Strength (15)
            Exercise(name: "Barbell Squats", duration: 20, calories: 120, type: "strength", instructions: "Stand with feet shoulder-width. Lower with barbell on shoulders. Drive through heels to stand.", sets: 4, reps: "8-10", restTime: 90, difficulty: "advanced", muscleGroups: ["legs", "glutes"], equipment: ["barbell"]),
            Exercise(name: "Bench Press", duration: 20, calories: 100, type: "strength", instructions: "Lie on bench. Lower barbell to chest. Press up. Keep core engaged.", sets: 4, reps: "8-10", restTime: 90, difficulty: "advanced", muscleGroups: ["chest", "triceps"], equipment: ["barbell", "bench"]),
            Exercise(name: "Pull-ups", duration: 15, calories: 80, type: "strength", instructions: "Hang from bar. Pull body up until chin over bar. Lower with control.", sets: 3, reps: "as many as possible", restTime: 90, difficulty: "advanced", muscleGroups: ["back", "biceps"], equipment: ["pull-up bar"]),
            Exercise(name: "Dips", duration: 12, calories: 60, type: "strength", instructions: "Support body on parallel bars. Lower by bending arms. Push back up.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["triceps", "shoulders"], equipment: ["parallel bars"]),
            Exercise(name: "Leg Curls", duration: 15, calories: 70, type: "strength", instructions: "Curl weight with legs. Lower with control. Keep core engaged.", sets: 3, reps: "12-15", restTime: 60, difficulty: "intermediate", muscleGroups: ["hamstrings"], equipment: ["leg curl machine"]),
            Exercise(name: "Cable Crossovers", duration: 12, calories: 60, type: "strength", instructions: "Pull cables across body. Squeeze chest. Control the movement.", sets: 3, reps: "12-15", restTime: 60, difficulty: "intermediate", muscleGroups: ["chest"], equipment: ["cable machine"]),
            Exercise(name: "Face Pulls", duration: 10, calories: 40, type: "strength", instructions: "Pull cable to face level. Squeeze shoulder blades. Control the return.", sets: 3, reps: "15-20", restTime: 45, difficulty: "beginner", muscleGroups: ["shoulders", "back"], equipment: ["cable machine"]),
            Exercise(name: "Cable Rows", duration: 15, calories: 80, type: "strength", instructions: "Pull cable to lower chest. Squeeze shoulder blades. Lower with control.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["back", "biceps"], equipment: ["cable machine"]),
            Exercise(name: "Leg Extensions", duration: 12, calories: 60, type: "strength", instructions: "Extend legs with weight. Lower with control. Don't lock knees.", sets: 3, reps: "12-15", restTime: 60, difficulty: "beginner", muscleGroups: ["quadriceps"], equipment: ["leg extension machine"]),
            Exercise(name: "Cable Flyes", duration: 12, calories: 65, type: "strength", instructions: "Fly cables together. Squeeze chest. Control the movement.", sets: 3, reps: "10-12", restTime: 60, difficulty: "intermediate", muscleGroups: ["chest"], equipment: ["cable machine"]),
            Exercise(name: "Tricep Pushdowns", duration: 10, calories: 45, type: "strength", instructions: "Push cable down. Keep elbows still. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["triceps"], equipment: ["cable machine"]),
            Exercise(name: "Cable Curls", duration: 10, calories: 40, type: "strength", instructions: "Curl cable to shoulders. Keep elbows still. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["biceps"], equipment: ["cable machine"]),
            Exercise(name: "Cable Lateral Raises", duration: 10, calories: 35, type: "strength", instructions: "Raise cable to side. Keep slight bend in elbows. Lower with control.", sets: 3, reps: "12-15", restTime: 45, difficulty: "beginner", muscleGroups: ["shoulders"], equipment: ["cable machine"]),
            Exercise(name: "Cable Crunches", duration: 10, calories: 40, type: "strength", instructions: "Curl down with cable. Squeeze abs. Return with control.", sets: 3, reps: "15-20", restTime: 45, difficulty: "beginner", muscleGroups: ["core"], equipment: ["cable machine"]),
            Exercise(name: "Cable Woodchoppers", duration: 12, calories: 50, type: "strength", instructions: "Rotate cable diagonally. Engage core. Alternate sides.", sets: 3, reps: "12 each side", restTime: 45, difficulty: "intermediate", muscleGroups: ["core", "obliques"], equipment: ["cable machine"]),
            
            // More Core (10)
            Exercise(name: "Ab Wheel Rollout", duration: 10, calories: 50, type: "strength", instructions: "Roll wheel forward. Keep core engaged. Return to start.", sets: 3, reps: "10-12", restTime: 60, difficulty: "advanced", muscleGroups: ["core"], equipment: ["ab wheel"]),
            Exercise(name: "Hanging Leg Raises", duration: 12, calories: 60, type: "strength", instructions: "Hang from bar. Raise legs to 90 degrees. Lower with control.", sets: 3, reps: "10-12", restTime: 60, difficulty: "advanced", muscleGroups: ["core"], equipment: ["pull-up bar"]),
            Exercise(name: "Dragon Flag", duration: 10, calories: 55, type: "strength", instructions: "Lie on bench. Raise body to vertical. Lower with control. Advanced movement.", sets: 3, reps: "5-8", restTime: 90, difficulty: "advanced", muscleGroups: ["core"], equipment: ["bench"]),
            Exercise(name: "L-Sit Hold", duration: 8, calories: 40, type: "strength", instructions: "Support body on parallel bars. Raise legs to L position. Hold as long as possible.", sets: 3, reps: "hold for time", restTime: 60, difficulty: "advanced", muscleGroups: ["core"], equipment: ["parallel bars"]),
            Exercise(name: "Pallof Press", duration: 10, calories: 45, type: "strength", instructions: "Press cable away from body. Resist rotation. Hold briefly. Return.", sets: 3, reps: "12 each side", restTime: 45, difficulty: "intermediate", muscleGroups: ["core"], equipment: ["cable machine"]),
            Exercise(name: "Turkish Get-Up", duration: 15, calories: 70, type: "strength", instructions: "Complex movement from lying to standing with weight. Focus on form and control.", sets: 3, reps: "5 each side", restTime: 90, difficulty: "advanced", muscleGroups: ["full body", "core"], equipment: ["kettlebell"]),
            Exercise(name: "Farmer's Walk", duration: 10, calories: 60, type: "strength", instructions: "Carry heavy weights. Walk forward. Keep core engaged. Maintain posture.", sets: 3, reps: "30-50 meters", restTime: 60, difficulty: "intermediate", muscleGroups: ["core", "grip"], equipment: ["dumbbells"]),
            Exercise(name: "Suitcase Carry", duration: 10, calories: 50, type: "strength", instructions: "Carry weight on one side. Walk forward. Resist lateral flexion.", sets: 3, reps: "30 meters each side", restTime: 60, difficulty: "intermediate", muscleGroups: ["core", "obliques"], equipment: ["dumbbell"]),
            Exercise(name: "Plank to Down Dog", duration: 10, calories: 45, type: "strength", instructions: "Start in plank. Push hips up to down dog. Return to plank. Repeat.", sets: 3, reps: "10-12", restTime: 45, difficulty: "intermediate", muscleGroups: ["core", "shoulders"], equipment: ["mat"]),
            Exercise(name: "Side Plank with Rotation", duration: 10, calories: 50, type: "strength", instructions: "Hold side plank. Rotate torso. Return. Alternate sides.", sets: 3, reps: "10 each side", restTime: 45, difficulty: "intermediate", muscleGroups: ["core", "obliques"], equipment: ["mat"]),
            
            // More Flexibility/Yoga (5)
            Exercise(name: "Power Yoga", duration: 45, calories: 200, type: "flexibility", instructions: "Dynamic yoga flow. Build strength and flexibility. Move with breath.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Hot Yoga", duration: 60, calories: 300, type: "flexibility", instructions: "Yoga in heated room. Increased flexibility. Stay hydrated.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Vinyasa Flow", duration: 30, calories: 150, type: "flexibility", instructions: "Flow through yoga poses. Link movement with breath. Smooth transitions.", sets: nil, reps: "continuous", restTime: nil, difficulty: "intermediate", muscleGroups: ["full body", "flexibility"], equipment: ["mat"]),
            Exercise(name: "Restorative Yoga", duration: 45, calories: 60, type: "flexibility", instructions: "Gentle, supported poses. Focus on relaxation. Hold poses 5-10 minutes.", sets: nil, reps: "5-10 minutes per pose", restTime: nil, difficulty: "beginner", muscleGroups: ["full body", "flexibility"], equipment: ["mat", "props"]),
            Exercise(name: "Ashtanga Yoga", duration: 60, calories: 250, type: "flexibility", instructions: "Traditional yoga sequence. Challenging poses. Build strength and flexibility.", sets: nil, reps: "continuous", restTime: nil, difficulty: "advanced", muscleGroups: ["full body", "flexibility"], equipment: ["mat"])
        ])
        
        return workouts
    }
    
    // MARK: - Helper Structures
    private struct MealData {
        let name: String
        let category: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let ingredients: [String]
        let instructions: String
        let prepTime: Int
        let servings: Int
        
        func toMealItem() -> RecommendationMealItem {
            RecommendationMealItem(
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                ingredients: ingredients,
                instructions: instructions,
                prepTime: prepTime,
                servings: servings
            )
        }
        
        func toParsedMealItem() -> ParsedMealItem {
            ParsedMealItem(
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                sugar: 0,
                portionSize: "1 serving"
            )
        }
    }
    
    private let defaultMealItem = ParsedMealItem(
        name: "Mixed Meal",
        calories: 400,
        protein: 25,
        carbs: 45,
        fat: 12,
        sugar: 8,
        portionSize: "1 serving"
    )
}

// MARK: - Parsed Meal Item (for scanning fallback)
struct ParsedMealItem {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let portionSize: String
}

// MARK: - Seeded Random Number Generator for Daily Rotation
// Ensures the same seed produces the same sequence, so daily rotation is consistent
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator for deterministic randomness
        state = state &* 1103515245 &+ 12345
        return state
    }
}

// MARK: - Array Extension for Seeded Shuffling
extension Array {
    func shuffled(using generator: inout SeededRandomNumberGenerator) -> [Element] {
        var result = self
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = Int(generator.next() % UInt64(i + 1))
            result.swapAt(i, j)
        }
        return result
    }
}

