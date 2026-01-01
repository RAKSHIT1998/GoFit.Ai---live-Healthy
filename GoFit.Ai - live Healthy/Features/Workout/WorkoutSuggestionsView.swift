import SwiftUI

// MARK: - Models
struct RecommendationResponse: Codable {
    let mealPlan: MealPlan
    let workoutPlan: WorkoutPlan
    let hydrationGoal: HydrationGoal
    let insights: [String]
}

struct MealPlan: Codable {
    let breakfast: [MealItem]
    let lunch: [MealItem]
    let dinner: [MealItem]
    let snacks: [MealItem]
}

struct MealItem: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let ingredients: [String]?
    let instructions: String?
    let prepTime: Int?
    let servings: Int?
}

struct WorkoutPlan: Codable {
    let exercises: [Exercise]
}

struct Exercise: Codable {
    let name: String
    let duration: Int
    let calories: Int
    let type: String
    let instructions: String?
    let sets: Int?
    let reps: String?
    let restTime: Int?
    let difficulty: String?
    let muscleGroups: [String]?
    let equipment: [String]?
}

struct HydrationGoal: Codable {
    let targetLiters: Double
}

// MARK: - Main View
struct WorkoutSuggestionsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var recommendation: RecommendationResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0 // 0: Workouts, 1: Meals
    @State private var expandedMeal: String?
    @State private var expandedExercise: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background for dark mode
                Design.Colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: Design.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating AI recommendations...")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle.fill",
                        title: "Oops!",
                        message: error,
                        action: {
                            Task { await loadRecommendations(forceRefresh: true) }
                        },
                        actionTitle: "Try Again"
                    )
                } else if let rec = recommendation {
                    ScrollView {
                        VStack(spacing: Design.Spacing.lg) {
                            // Tab Selector
                            tabSelector
                                .padding(.horizontal, Design.Spacing.md)
                                .padding(.top, Design.Spacing.md)
                            
                            // Content based on selected tab
                            if selectedTab == 0 {
                                workoutSection(rec.workoutPlan)
                            } else {
                                mealSection(rec.mealPlan)
                            }
                            
                            // Insights Card
                            if !rec.insights.isEmpty {
                                insightsCard(rec.insights)
                            }
                        }
                        .padding(.bottom, Design.Spacing.xl)
                    }
                    .refreshable {
                        isRefreshing = true
                        await loadRecommendations(forceRefresh: true)
                    }
                } else {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Recommendations",
                        message: "Tap refresh to generate AI-powered meal and workout recommendations",
                        action: {
                            Task { await loadRecommendations(forceRefresh: true) }
                        },
                        actionTitle: "Generate"
                    )
                }
            }
            .navigationTitle("AI Recommendations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await loadRecommendations(forceRefresh: true) }
                    }) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Design.Colors.primary)
                                .font(Design.Typography.headline)
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .task {
                await loadRecommendations()
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Workouts", icon: "figure.run", isSelected: selectedTab == 0) {
                withAnimation(Design.Animation.spring) {
                    selectedTab = 0
                }
            }
            
            tabButton(title: "Meals", icon: "fork.knife", isSelected: selectedTab == 1) {
                withAnimation(Design.Animation.spring) {
                    selectedTab = 1
                }
            }
        }
        .padding(Design.Spacing.xs)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func tabButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                Group {
                    if isSelected {
                        Design.Colors.primary
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(Design.Radius.small)
        }
    }
    
    // MARK: - Workout Section
    private func workoutSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.lg) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Design.Colors.primary)
                Text("AI-Generated Workouts")
                    .font(Design.Typography.title2)
            }
            
            if plan.exercises.isEmpty {
                emptyWorkoutState
            } else {
                ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, exercise in
                    workoutCard(exercise, index: index)
                }
            }
        }
    }
    
    private func workoutCard(_ exercise: Exercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            // Header
            HStack {
                // Exercise number badge
                ZStack {
                    Circle()
                        .fill(Design.Colors.primaryGradient)
                        .frame(width: 40, height: 40)
                    Text("\(index + 1)")
                        .font(Design.Typography.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(Design.Typography.headline)
                    
                    HStack(spacing: Design.Spacing.md) {
                        Label("\(exercise.duration) min", systemImage: "clock.fill")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(exercise.calories) kcal", systemImage: "flame.fill")
                            .font(Design.Typography.caption)
                            .foregroundColor(Design.Colors.calories)
                        
                        if let difficulty = exercise.difficulty {
                            Text(difficulty.capitalized)
                                .font(Design.Typography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(difficultyColor(difficulty).opacity(0.2))
                                .foregroundColor(difficultyColor(difficulty))
                                .cornerRadius(Design.Radius.small)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Exercise details
            HStack(spacing: Design.Spacing.md) {
                if let sets = exercise.sets {
                    detailBadge(icon: "repeat", text: "\(sets) sets")
                }
                
                if let reps = exercise.reps {
                    detailBadge(icon: "arrow.triangle.2.circlepath", text: reps)
                }
                
                if let rest = exercise.restTime {
                    detailBadge(icon: "timer", text: "\(rest)s rest")
                }
                
                if let type = exercise.type.capitalized as String? {
                    detailBadge(icon: "figure.walk", text: type)
                }
            }
            
            // Muscle groups
            if let muscleGroups = exercise.muscleGroups, !muscleGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Design.Spacing.sm) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group.capitalized)
                                .font(Design.Typography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Design.Colors.primary.opacity(0.1))
                                .foregroundColor(Design.Colors.primary)
                                .cornerRadius(Design.Radius.small)
                        }
                    }
                }
            }
            
            // Equipment
            if let equipment = exercise.equipment, !equipment.isEmpty {
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(equipment.joined(separator: ", "))
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Instructions
            if let instructions = exercise.instructions, !instructions.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedExercise == exercise.name },
                        set: { expandedExercise = $0 ? exercise.name : nil }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text(instructions)
                                .font(Design.Typography.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, Design.Spacing.sm)
                    },
                    label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(Design.Colors.primary)
                            Text("How to Perform")
                                .font(Design.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(Design.Colors.primary)
            }
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Meal Section
    private func mealSection(_ plan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.lg) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Design.Colors.primary)
                Text("AI Meal Recommendations")
                    .font(Design.Typography.title2)
            }
            
            mealCategory(title: "Breakfast", icon: "sunrise.fill", meals: plan.breakfast, color: .orange)
            mealCategory(title: "Lunch", icon: "sun.max.fill", meals: plan.lunch, color: .yellow)
            mealCategory(title: "Dinner", icon: "moon.fill", meals: plan.dinner, color: .blue)
            mealCategory(title: "Snacks", icon: "leaf.fill", meals: plan.snacks, color: .green)
        }
    }
    
    private func mealCategory(title: String, icon: String, meals: [MealItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            if !meals.isEmpty {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(Design.Typography.headline)
                }
                .padding(.horizontal, Design.Spacing.md)
                
                ForEach(meals, id: \.name) { meal in
                    mealCard(meal)
                }
            }
        }
    }
    
    private func mealCard(_ meal: MealItem) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(Design.Typography.headline)
                    
                    HStack(spacing: Design.Spacing.md) {
                        macroBadge(value: Int(meal.calories), unit: "kcal", color: Design.Colors.calories)
                        macroBadge(value: Int(meal.protein), unit: "g P", color: Design.Colors.protein)
                        macroBadge(value: Int(meal.carbs), unit: "g C", color: Design.Colors.carbs)
                        macroBadge(value: Int(meal.fat), unit: "g F", color: Design.Colors.fat)
                    }
                }
                
                Spacer()
            }
            
            // Prep info
            HStack(spacing: Design.Spacing.md) {
                if let prepTime = meal.prepTime {
                    Label("\(prepTime) min", systemImage: "clock.fill")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                if let servings = meal.servings {
                    Label("\(servings) serving\(servings > 1 ? "s" : "")", systemImage: "person.fill")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Ingredients
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedMeal == "\(meal.name)-ingredients" },
                        set: { expandedMeal = $0 ? "\(meal.name)-ingredients" : nil }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            ForEach(ingredients, id: \.self) { ingredient in
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(Design.Colors.primary)
                                    Text(ingredient)
                                        .font(Design.Typography.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, Design.Spacing.sm)
                    },
                    label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(Design.Colors.primary)
                            Text("Ingredients")
                                .font(Design.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(Design.Colors.primary)
            }
            
            // Instructions
            if let instructions = meal.instructions, !instructions.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedMeal == "\(meal.name)-instructions" },
                        set: { expandedMeal = $0 ? "\(meal.name)-instructions" : nil }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text(instructions)
                                .font(Design.Typography.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, Design.Spacing.sm)
                    },
                    label: {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(Design.Colors.primary)
                            Text("How to Make")
                                .font(Design.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(Design.Colors.primary)
            }
        }
        .padding(Design.Spacing.lg)
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.large)
        .shadow(color: Color.primary.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Insights Card
    private func insightsCard(_ insights: [String]) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Design.Colors.accent)
                Text("AI Insights")
                    .font(Design.Typography.headline)
            }
            
            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: Design.Spacing.sm) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundColor(Design.Colors.primary)
                        .padding(.top, 4)
                    Text(insight)
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Design.Spacing.lg)
        .background(Design.Colors.accent.opacity(0.1))
        .cornerRadius(Design.Radius.large)
        .shadow(color: Color.primary.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Helper Views
    private func detailBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(Design.Typography.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(Design.Radius.small)
    }
    
    private func macroBadge(value: Int, unit: String, color: Color) -> some View {
        Text("\(value) \(unit)")
            .font(Design.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(Design.Radius.small)
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return Design.Colors.primary
        }
    }
    
    // MARK: - Empty States
    private var emptyState: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Design.Colors.primary.opacity(0.5))
            Text("No recommendations yet")
                .font(Design.Typography.title2)
            Text("Tap refresh to generate AI-powered recommendations")
                .font(Design.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
        }
    }
    
    private var emptyWorkoutState: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No workouts generated yet")
                .font(Design.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.xl)
        .cardStyle()
    }
    
    // MARK: - Network
    @State private var isRefreshing = false
    
    private func loadRecommendations(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        defer { 
            isLoading = false
            isRefreshing = false
        }
        
        do {
            // Try to fetch from backend
            if !EnvironmentConfig.skipAuthentication {
                let endpoint: String
                let method: String
                
                if forceRefresh {
                    // Force regenerate new recommendations
                    endpoint = "recommendations/regenerate"
                    method = "POST"
                } else {
                    // Get today's recommendations (may be cached)
                    endpoint = "recommendations/daily"
                    method = "GET"
                }
                
                let response: RecommendationResponse = try await NetworkManager.shared.request(
                    endpoint,
                    method: method,
                    body: nil
                )
                await MainActor.run {
                    recommendation = response
                    errorMessage = nil
                }
            } else {
                // Mock data for dev mode
                await MainActor.run {
                    recommendation = mockRecommendation
                }
            }
        } catch {
            await MainActor.run {
                if let nsError = error as NSError? {
                    let errorMessageText = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    
                    // Check for specific error types
                    if errorMessageText.contains("GEMINI_API_KEY") || 
                       errorMessageText.contains("not configured") ||
                       errorMessageText.contains("AI recommendation service") {
                        errorMessage = "AI recommendations are not configured. Please set GEMINI_API_KEY in Render environment variables."
                    } else if errorMessageText.contains("timeout") {
                        errorMessage = "Request timed out. Please try again."
                    } else {
                        errorMessage = "Failed to load recommendations: \(errorMessageText)"
                    }
                } else {
                    errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
                }
                
                // Only use mock data if we have no recommendation at all
                if recommendation == nil {
                    recommendation = mockRecommendation
                }
            }
        }
    }
    
    // MARK: - Mock Data
    private var mockRecommendation: RecommendationResponse {
        RecommendationResponse(
            mealPlan: MealPlan(
                breakfast: [
                    MealItem(
                        name: "Protein-Packed Oatmeal Bowl",
                        calories: 350,
                        protein: 18,
                        carbs: 55,
                        fat: 8,
                        ingredients: [
                            "1 cup rolled oats",
                            "1 cup almond milk",
                            "1 scoop protein powder",
                            "1/2 banana, sliced",
                            "1 tbsp almond butter",
                            "1 tbsp chia seeds",
                            "1/2 cup blueberries"
                        ],
                        instructions: "1. Cook oats with almond milk over medium heat for 5 minutes. 2. Remove from heat and stir in protein powder until smooth. 3. Top with banana, almond butter, chia seeds, and blueberries. 4. Enjoy warm!",
                        prepTime: 10,
                        servings: 1
                    )
                ],
                lunch: [
                    MealItem(
                        name: "Mediterranean Quinoa Bowl",
                        calories: 450,
                        protein: 22,
                        carbs: 60,
                        fat: 15,
                        ingredients: [
                            "1 cup cooked quinoa",
                            "150g grilled chicken breast",
                            "1/2 cup cherry tomatoes",
                            "1/4 cup cucumber, diced",
                            "2 tbsp feta cheese",
                            "2 tbsp olive oil",
                            "1 tbsp lemon juice",
                            "Fresh herbs (parsley, mint)"
                        ],
                        instructions: "1. Season and grill chicken until cooked through (6-7 min per side). 2. Let rest, then slice. 3. Combine quinoa with tomatoes, cucumber, and feta. 4. Whisk olive oil and lemon juice for dressing. 5. Top quinoa bowl with chicken, drizzle dressing, and garnish with herbs.",
                        prepTime: 20,
                        servings: 1
                    )
                ],
                dinner: [
                    MealItem(
                        name: "Herb-Crusted Salmon with Roasted Vegetables",
                        calories: 520,
                        protein: 38,
                        carbs: 35,
                        fat: 22,
                        ingredients: [
                            "200g salmon fillet",
                            "1 cup mixed vegetables (broccoli, bell peppers, zucchini)",
                            "2 tbsp olive oil",
                            "1 tbsp fresh dill",
                            "1 tbsp fresh parsley",
                            "Lemon wedges",
                            "Garlic powder",
                            "Salt and pepper"
                        ],
                        instructions: "1. Preheat oven to 400°F. 2. Mix herbs, garlic powder, salt, and pepper. 3. Rub salmon with olive oil and herb mixture. 4. Toss vegetables with remaining olive oil and seasonings. 5. Place salmon and vegetables on baking sheet. 6. Bake for 15-18 minutes until salmon flakes easily. 7. Serve with lemon wedges.",
                        prepTime: 25,
                        servings: 1
                    )
                ],
                snacks: [
                    MealItem(
                        name: "Greek Yogurt Parfait",
                        calories: 180,
                        protein: 16,
                        carbs: 22,
                        fat: 4,
                        ingredients: [
                            "1 cup Greek yogurt",
                            "1/2 cup mixed berries",
                            "1 tbsp honey",
                            "2 tbsp granola"
                        ],
                        instructions: "1. Layer half the yogurt in a glass. 2. Add berries and drizzle with honey. 3. Top with remaining yogurt and granola. 4. Serve immediately.",
                        prepTime: 5,
                        servings: 1
                    )
                ]
            ),
            workoutPlan: WorkoutPlan(
                exercises: [
                    Exercise(
                        name: "Full Body HIIT Circuit",
                        duration: 25,
                        calories: 280,
                        type: "hiit",
                        instructions: "1. Warm-up: 5 minutes of light jogging in place and dynamic stretches. 2. Circuit (repeat 3 times): - Jump squats: 45 seconds, rest 15 seconds - Push-ups: 45 seconds, rest 15 seconds - Mountain climbers: 45 seconds, rest 15 seconds - Burpees: 45 seconds, rest 15 seconds - Plank hold: 45 seconds, rest 15 seconds. 3. Cool-down: 5 minutes of walking and static stretches. Focus on proper form over speed. Modify exercises as needed.",
                        sets: 3,
                        reps: "45 seconds on, 15 seconds off",
                        restTime: 15,
                        difficulty: "intermediate",
                        muscleGroups: ["full body", "core", "cardio"],
                        equipment: ["none"]
                    ),
                    Exercise(
                        name: "Upper Body Strength Training",
                        duration: 30,
                        calories: 200,
                        type: "strength",
                        instructions: "1. Warm-up: 5 minutes arm circles and light stretching. 2. Perform each exercise for 3 sets: - Push-ups: 10-12 reps, rest 60 seconds - Dumbbell rows: 10-12 reps each arm, rest 60 seconds - Shoulder presses: 10-12 reps, rest 60 seconds - Tricep dips: 10-12 reps, rest 60 seconds - Bicep curls: 10-12 reps, rest 60 seconds. 3. Focus on controlled movements and full range of motion. 4. Cool-down with 5 minutes of stretching.",
                        sets: 3,
                        reps: "10-12",
                        restTime: 60,
                        difficulty: "intermediate",
                        muscleGroups: ["chest", "back", "shoulders", "arms"],
                        equipment: ["dumbbells", "mat"]
                    ),
                    Exercise(
                        name: "Core Strengthening Flow",
                        duration: 15,
                        calories: 120,
                        type: "strength",
                        instructions: "1. Start with a 2-minute warm-up of cat-cow stretches. 2. Perform each exercise for 45 seconds, rest 15 seconds: - Plank hold - Russian twists - Dead bugs - Bicycle crunches - Leg raises - Side plank (each side). 3. Repeat the circuit once. 4. Finish with 2 minutes of gentle stretching. Keep your core engaged throughout and breathe steadily.",
                        sets: 2,
                        reps: "45 seconds",
                        restTime: 15,
                        difficulty: "beginner",
                        muscleGroups: ["core", "abs"],
                        equipment: ["mat"]
                    )
                ]
            ),
            hydrationGoal: HydrationGoal(targetLiters: 2.5),
            insights: [
                "Stay hydrated by drinking water before, during, and after your workouts",
                "Your meal plan is designed to support your fitness goals with balanced macros",
                "Remember to warm up before workouts and cool down afterward to prevent injury"
            ]
        )
    }
}
