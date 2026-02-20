import SwiftUI

// MARK: - Models
struct RecommendationResponse: Codable {
    let mealPlan: MealPlan
    let workoutPlan: WorkoutPlan
    let hydrationGoal: HydrationGoal
    let insights: [String]
}

struct MealPlan: Codable {
    let breakfast: [RecommendationMealItem]
    let lunch: [RecommendationMealItem]
    let dinner: [RecommendationMealItem]
    let snacks: [RecommendationMealItem]
}

struct CitationSource: Codable {
    let title: String
    let url: String
}

struct RecommendationMealItem: Codable, Identifiable {
    var id: String { name }
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let ingredients: [String]?
    let instructions: String?
    let prepTime: Int?
    let servings: Int?
    let sources: [CitationSource]?
}

struct WorkoutPlan: Codable {
    let exercises: [Exercise]
}

struct Exercise: Codable, Identifiable {
    var id: String { name }
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
    let gifUrl: String?
    let videoUrl: String?
    let sources: [CitationSource]?
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
    @State private var selectedTab = 0
    @State private var expandedMeal: String?
    @State private var expandedExercise: String?
    @State private var isUsingFallback = true
    @State private var isRefreshing = false
    @State private var currentRequestTask: Task<Void, Never>?
    @State private var selectedExerciseForDemo: Exercise?
    @State private var selectedMealForDemo: RecommendationMealItem?
    @StateObject private var gifGenerator = AIGifGeneratorService.shared
    @State private var showGifGenerationSheet = false
    @State private var showPrivacyDisclosure = false
    @AppStorage("hasSeenAIPrivacyDisclosure") private var hasSeenPrivacyDisclosure = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                if isLoading && recommendation == nil {
                    VStack(spacing: Design.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading recommendations...")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    .smoothFadeIn()
                } else if let rec = recommendation {
                    ScrollView {
                        VStack(spacing: Design.Spacing.lg) {
                            headerBanner
                                .padding(.horizontal, Design.Spacing.md)
                                .padding(.top, Design.Spacing.md)
                                .delayedAppear(0)
                            
                            tabSelector
                                .padding(.horizontal, Design.Spacing.md)
                                .delayedAppear(0.1)
                            
                            if selectedTab == 0 {
                                workoutSection(rec.workoutPlan)
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            } else {
                                mealSection(rec.mealPlan)
                                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                            }
                            
                            if !rec.insights.isEmpty {
                                insightsCard(rec.insights)
                                    .padding(.horizontal, Design.Spacing.md)
                                    .delayedAppear(0.2)
                            }
                        }
                        .padding(.bottom, Design.Spacing.xl)
                    }
                    .refreshable {
                        await refreshRecommendations()
                    }
                } else {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Recommendations",
                        message: "Tap refresh to load meal and workout recommendations",
                        action: {
                            Task { await loadRecommendations() }
                        },
                        actionTitle: "Load Recommendations"
                    )
                    .smoothFadeIn()
                }
            }
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.lightTap()
                            showGifGenerationSheet = true
                        }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(Design.Colors.primary)
                        }
                        .buttonStyle(SmoothButtonStyle())
                        
                        Button(action: {
                            HapticManager.shared.mediumTap()
                            Task { await refreshRecommendations() }
                        }) {
                            if isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Design.Colors.primary)
                            }
                        }
                        .buttonStyle(SmoothButtonStyle())
                        .disabled(isRefreshing || isLoading)
                    }
                }
            }
            .task {
                await loadRecommendations()
            }
            .sheet(item: $selectedExerciseForDemo) { exercise in
                ExerciseDemoView(exercise: exercise)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedMealForDemo) { meal in
                NavigationStack {
                    MealDemoView(meal: meal)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showGifGenerationSheet) {
                if let rec = recommendation {
                    GifGenerationView(exercises: rec.workoutPlan.exercises)
                }
            }
            .sheet(isPresented: $showPrivacyDisclosure) {
                PrivacyDisclosureView(
                    onAccept: {
                        showPrivacyDisclosure = false
                        hasSeenPrivacyDisclosure = true
                    },
                    onDecline: {
                        showPrivacyDisclosure = false
                    }
                )
            }
            .onAppear {
                if !hasSeenPrivacyDisclosure {
                    showPrivacyDisclosure = true
                }
            }
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        VStack(spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: isUsingFallback ? "book.fill" : "sparkles")
                    .foregroundColor(Design.Colors.primary)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isUsingFallback ? "Built-in Recipes & Workouts" : "AI Recommendations")
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                    if isUsingFallback {
                        Text("Rotates daily • Complete instructions included")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.primary.opacity(0.1))
        .cornerRadius(Design.Radius.medium)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Workouts", icon: "figure.run", isSelected: selectedTab == 0) {
                HapticManager.shared.lightTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                }
            }
            tabButton(title: "Meals", icon: "fork.knife", isSelected: selectedTab == 1) {
                HapticManager.shared.lightTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 1
                }
            }
        }
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.medium)
    }
    
    private func tabButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                Text(title)
            }
            .font(Design.Typography.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .background(isSelected ? Design.Colors.primary : Color.clear)
            .cornerRadius(Design.Radius.medium)
        }
    }
    
    // MARK: - Workout Section
    private func workoutSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.lg) {
            if plan.exercises.isEmpty {
                emptyWorkoutState
            } else {
                ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, exercise in
                    workoutCard(exercise, index: index)
                        .padding(.horizontal, Design.Spacing.md)
                }
            }
        }
    }
    
    private func workoutCard(_ exercise: Exercise, index: Int) -> some View {
        let visualService = RecommendationVisualService.shared
        
        return VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Design.Colors.primaryGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: visualService.getExerciseIcon(for: exercise.name))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exercise.name)
                            .font(Design.Typography.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Design.Colors.primary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
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
                
                detailBadge(icon: "figure.walk", text: exercise.type.capitalized)
            }
            
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
            
            if let sources = exercise.sources, !sources.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedExercise == "\(exercise.name)-sources" },
                        set: { expandedExercise = $0 ? "\(exercise.name)-sources" : nil }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: Design.Spacing.md) {
                            Text("This exercise recommendation is based on information from:")
                                .font(Design.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(sources, id: \.url) { source in
                                HStack(alignment: .top, spacing: Design.Spacing.sm) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Design.Colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.title)
                                            .font(Design.Typography.subheadline)
                                            .foregroundColor(Design.Colors.primary)
                                        
                                        if let url = URL(string: source.url) {
                                            Link(destination: url) {
                                                Text(source.url)
                                                    .font(Design.Typography.caption)
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, Design.Spacing.sm)
                    },
                    label: {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(Design.Colors.primary)
                            Text("Sources & Citations")
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
            mealCategory(title: "Breakfast", icon: "sunrise.fill", meals: plan.breakfast, color: .orange)
            mealCategory(title: "Lunch", icon: "sun.max.fill", meals: plan.lunch, color: .yellow)
            mealCategory(title: "Dinner", icon: "moon.fill", meals: plan.dinner, color: .blue)
            mealCategory(title: "Snacks", icon: "leaf.fill", meals: plan.snacks, color: .green)
        }
    }
    
    private func mealCategory(title: String, icon: String, meals: [RecommendationMealItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            if !meals.isEmpty {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, Design.Spacing.md)
                
                ForEach(meals, id: \.name) { meal in
                    mealCard(meal)
                        .padding(.horizontal, Design.Spacing.md)
                }
            }
        }
    }
    
    private func mealCard(_ meal: RecommendationMealItem) -> some View {
        let visualService = RecommendationVisualService.shared
        let mealColor = visualService.getMealColor(for: meal.name)
        let mealEmoji = visualService.getMealEmoji(for: meal.name)
        
        return VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color(mealColor).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(mealEmoji)
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: Design.Spacing.md) {
                        macroBadge(value: Int(meal.calories), unit: "kcal", color: Design.Colors.calories)
                        macroBadge(value: Int(meal.protein), unit: "g P", color: Design.Colors.protein)
                        macroBadge(value: Int(meal.carbs), unit: "g C", color: Design.Colors.carbs)
                        macroBadge(value: Int(meal.fat), unit: "g F", color: Design.Colors.fat)
                    }
                }
                
                Spacer()
            }
            
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
                                        .font(.system(size: Design.Scale.value(6, textStyle: .caption1)))
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
                            Image(systemName: "list.number")
                                .foregroundColor(Design.Colors.primary)
                            Text("How to Make")
                                .font(Design.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(Design.Colors.primary)
            }
            
            if let sources = meal.sources, !sources.isEmpty {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedMeal == "\(meal.name)-sources" },
                        set: { expandedMeal = $0 ? "\(meal.name)-sources" : nil }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: Design.Spacing.md) {
                            Text("This recommendation is based on information from:")
                                .font(Design.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(sources, id: \.url) { source in
                                HStack(alignment: .top, spacing: Design.Spacing.sm) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Design.Colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.title)
                                            .font(Design.Typography.subheadline)
                                            .foregroundColor(Design.Colors.primary)
                                        
                                        if let url = URL(string: source.url) {
                                            Link(destination: url) {
                                                Text(source.url)
                                                    .font(Design.Typography.caption)
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, Design.Spacing.sm)
                    },
                    label: {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(Design.Colors.primary)
                            Text("Sources & Citations")
                                .font(Design.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                )
                .tint(Design.Colors.primary)
            }
            
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: "play.circle.fill")
                Text("View Recipe Video")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Design.Spacing.md)
            .padding(.vertical, Design.Spacing.sm)
            .background(Design.Colors.primary.opacity(0.1))
            .foregroundColor(Design.Colors.primary)
            .cornerRadius(Design.Radius.medium)
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Helper Views
    private func detailBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(text)
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.small)
    }
    
    private func macroBadge(value: Int, unit: String, color: Color) -> some View {
        Text("\(value) \(unit)")
            .font(Design.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(Design.Radius.small)
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner":
            return .green
        case "intermediate":
            return .orange
        case "advanced":
            return .red
        default:
            return .gray
        }
    }
    
    private func insightsCard(_ insights: [String]) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Design.Colors.primary)
                Text("Insights")
                    .font(Design.Typography.headline)
                    .foregroundColor(.primary)
            }
            
            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: Design.Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: Design.Scale.value(6, textStyle: .caption1)))
                        .foregroundColor(Design.Colors.primary)
                        .padding(.top, 6)
                    Text(insight)
                        .font(Design.Typography.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Design.Spacing.lg)
        .cardStyle()
    }
    
    private var emptyWorkoutState: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: Design.Scale.value(40, textStyle: .title3)))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No workouts available")
                .font(Design.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.xl)
        .cardStyle()
        .padding(.horizontal, Design.Spacing.md)
    }
    
    // MARK: - Network Functions
    private func loadRecommendations() async {
        await loadBuiltInRecommendations()
        
        if !EnvironmentConfig.skipAuthentication {
            await tryLoadAIRecommendations()
        }
    }
    
    private func refreshRecommendations() async {
        currentRequestTask?.cancel()
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        await loadBuiltInRecommendations(forceNew: true)
        
        if !EnvironmentConfig.skipAuthentication {
            let task = Task {
                await tryLoadAIRecommendations(forceRefresh: true)
            }
            currentRequestTask = task
            await task.value
        }
    }
    
    private func loadBuiltInRecommendations(forceNew: Bool = false) async {
        let goal = auth.goal.isEmpty ? "maintain" : auth.goal
        let activityLevel = "moderate"
        let dietaryPreferences = auth.dietPrefs
        
        let fallbackMeals = FallbackDataService.shared.getRandomMeals(goal: goal, count: 4, useTimestamp: forceNew, dietaryPreferences: dietaryPreferences)
        let fallbackWorkouts = FallbackDataService.shared.getRandomWorkouts(activityLevel: activityLevel, count: 4, useTimestamp: forceNew)
        
        let fallbackRecommendation = RecommendationResponse(
            mealPlan: fallbackMeals,
            workoutPlan: fallbackWorkouts,
            hydrationGoal: HydrationGoal(targetLiters: 2.5),
            insights: [
                "✨ Daily rotating recipes and workouts",
                "🍽️ Complete ingredients and cooking instructions included",
                "💪 Detailed workout instructions with sets, reps, and rest times",
                "🔄 Content changes every day for variety"
            ]
        )
        
        await MainActor.run {
            recommendation = fallbackRecommendation
            isUsingFallback = true
            isLoading = false
            errorMessage = nil
        }
    }
    
    private func tryLoadAIRecommendations(forceRefresh: Bool = false) async {
        if !forceRefresh {
            isLoading = true
            do { isLoading = false }
        }
        
        do {
            let endpoint = forceRefresh ? "recommendations/regenerate" : "recommendations/daily"
            let method = forceRefresh ? "POST" : "GET"
            let bodyData: Data? = forceRefresh ? try? JSONSerialization.data(withJSONObject: ["forceNew": true, "timestamp": Date().timeIntervalSince1970]) : nil
            
            #if DEBUG
            if forceRefresh {
                print("🔄 Refreshing recommendations - requesting NEW meals and workouts from ChatGPT")
            }
            #endif
            
            let response: RecommendationResponse = try await NetworkManager.shared.request(
                endpoint,
                method: method,
                body: bodyData
            )
            
            let hasMeals = !response.mealPlan.breakfast.isEmpty || 
                          !response.mealPlan.lunch.isEmpty || 
                          !response.mealPlan.dinner.isEmpty || 
                          !response.mealPlan.snacks.isEmpty
            let hasWorkouts = !response.workoutPlan.exercises.isEmpty
            
            if !hasMeals && !hasWorkouts {
                #if DEBUG
                print("ℹ️ Received empty recommendations (AI unavailable), using built-in data")
                #endif
                if recommendation == nil {
                    await loadBuiltInRecommendations()
                } else {
                    await MainActor.run {
                        isUsingFallback = true
                    }
                }
                return
            }
            
            #if DEBUG
            print("🔄 Refresh: Received new AI recommendations")
            #endif
            
            await MainActor.run {
                recommendation = response
                isUsingFallback = false
                errorMessage = nil
                print("✅ AI recommendations loaded successfully")
            }
        } catch {
            let errorDescription: String
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled:
                    errorDescription = "Request was cancelled"
                    #if DEBUG
                    print("ℹ️ Recommendation request was cancelled (likely due to rapid refresh)")
                    #endif
                    return
                case .timedOut:
                    errorDescription = "Request timed out"
                case .notConnectedToInternet:
                    errorDescription = "No internet connection"
                default:
                    errorDescription = urlError.localizedDescription
                }
            } else if let nsError = error as NSError? {
                errorDescription = nsError.localizedDescription
            } else {
                errorDescription = error.localizedDescription
            }
            
            #if DEBUG
            print("⚠️ AI recommendations unavailable, using built-in data: \(errorDescription)")
            #endif
            
            if recommendation == nil {
                await loadBuiltInRecommendations()
            } else {
                await MainActor.run {
                    isUsingFallback = true
                }
            }
        }
    }
}
