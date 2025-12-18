import SwiftUI

struct MealHistoryView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var meals: [MealHistoryItem] = []
    @State private var loading = false
    @State private var selectedDate = Date()
    @Environment(\.dismiss) var dismiss
    
    struct MealHistoryItem: Identifiable {
        let id: String
        let date: Date
        let items: [MealItem]
        let totalCalories: Double
        let mealType: String
        
        struct MealItem {
            let name: String
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()
                
                if loading && meals.isEmpty {
                    VStack(spacing: Design.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading meals...")
                            .font(Design.Typography.body)
                            .foregroundColor(.secondary)
                    }
                } else if meals.isEmpty {
                    EmptyStateView(
                        icon: "fork.knife.circle",
                        title: "No Meals Yet",
                        message: "Start scanning your meals to see them here"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Design.Spacing.md) {
                            ForEach(meals) { meal in
                                MealHistoryCard(meal: meal)
                                    .padding(.horizontal, Design.Spacing.md)
                            }
                        }
                        .padding(.vertical, Design.Spacing.md)
                    }
                }
            }
            .navigationTitle("Meal History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Design.Colors.primary)
                    .font(Design.Typography.body)
                }
            }
            .task {
                await loadMeals()
            }
            .refreshable {
                await loadMeals()
            }
        }
    }
    
    // MARK: - Functions
    func loadMeals() async {
        loading = true
        defer { loading = false }
        
        do {
            struct MealResponse: Codable {
                let _id: String
                let timestamp: String
                let items: [ItemResponse]
                let totalCalories: Double?
                let mealType: String?
            }
            
            struct ItemResponse: Codable {
                let name: String
                let calories: Double?
                let protein: Double?
                let carbs: Double?
                let fat: Double?
            }
            
            let responses: [MealResponse] = try await NetworkManager.shared.request("meals/list", method: "GET", body: nil)
            
            meals = responses.map { response in
                MealHistoryItem(
                    id: response._id,
                    date: ISO8601DateFormatter().date(from: response.timestamp) ?? Date(),
                    items: response.items.map { item in
                        MealHistoryItem.MealItem(
                            name: item.name,
                            calories: item.calories ?? 0,
                            protein: item.protein ?? 0,
                            carbs: item.carbs ?? 0,
                            fat: item.fat ?? 0
                        )
                    },
                    totalCalories: response.totalCalories ?? 0,
                    mealType: response.mealType ?? "meal"
                )
            }
        } catch {
            print("Failed to load meals: \(error)")
        }
    }
}

// MARK: - Meal History Card
struct MealHistoryCard: View {
    let meal: MealHistoryView.MealHistoryItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(Design.Animation.spring) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                        Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                            .font(Design.Typography.headline)
                            .foregroundColor(.primary)
                        
                        Text(meal.mealType.capitalized)
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Design.Spacing.xs) {
                        Text("\(Int(meal.totalCalories))")
                            .font(Design.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Design.Colors.calories)
                        Text("kcal")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(Design.Typography.caption)
                }
                .padding(Design.Spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                Divider()
                    .padding(.horizontal, Design.Spacing.lg)
                
                VStack(spacing: Design.Spacing.md) {
                    ForEach(meal.items.indices, id: \.self) { index in
                        MealItemRow(item: meal.items[index])
                    }
                    
                    // Macros Summary
                    HStack(spacing: Design.Spacing.md) {
                        MacroBadge(label: "Protein", value: meal.items.reduce(0) { $0 + $1.protein }, color: Design.Colors.protein)
                        MacroBadge(label: "Carbs", value: meal.items.reduce(0) { $0 + $1.carbs }, color: Design.Colors.carbs)
                        MacroBadge(label: "Fat", value: meal.items.reduce(0) { $0 + $1.fat }, color: Design.Colors.fat)
                    }
                    .padding(.top, Design.Spacing.sm)
                }
                .padding(Design.Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Design.Colors.cardBackground)
        .cornerRadius(Design.Radius.large)
        .shadow(color: Color.primary.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Meal Item Row
struct MealItemRow: View {
    let item: MealHistoryView.MealHistoryItem.MealItem
    
    var body: some View {
        HStack {
            Circle()
                .fill(Design.Colors.primary.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(item.name)
                .font(Design.Typography.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(item.calories)) kcal")
                .font(Design.Typography.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Macro Badge
struct MacroBadge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))g")
                .font(Design.Typography.headline)
                .foregroundColor(color)
            Text(label)
                .font(Design.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(Design.Radius.small)
    }
}
