import SwiftUI

struct ManualMealLogView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var mealType: String = "breakfast"
    @State private var items: [EditableParsedItem] = [EditableParsedItem(name: "", qtyText: "", calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0)]
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    var body: some View {
        NavigationView {
            Form {
                mealTypeSection
                foodItemsSection
                errorSection
            }
            .smoothListStyle()
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.lightTap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.shared.mediumTap()
                        Task { await saveMeal() }
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .modifier(LoadingOverlay(isLoading: isSaving))
        .alert("Meal Saved!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your meal has been logged successfully.")
        }
    }
    
    private var mealTypeSection: some View {
        Section("Meal Type") {
            Picker("Type", selection: $mealType) {
                ForEach(mealTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }
            .onChange(of: mealType) {
                HapticManager.shared.lightTap()
            }
        }
    }
    
    private var foodItemsSection: some View {
        Section("Food Items") {
            ForEach($items) { $item in
                foodItemView(item: $item)
            }
            .onDelete { indexSet in
                withAnimation(.easeInOut(duration: 0.2)) {
                    items.remove(atOffsets: indexSet)
                    if items.isEmpty {
                        items = [EditableParsedItem(name: "", qtyText: "", calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0)]
                    }
                }
                HapticManager.shared.lightTap()
            }
            
            Button(action: {
                HapticManager.shared.mediumTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    items.append(EditableParsedItem(name: "", qtyText: "", calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0))
                }
            }) {
                Label("Add Item", systemImage: "plus.circle")
            }
        }
    }
    
    private var errorSection: some View {
        Group {
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .transition(.move(edge: .top))
                }
            }
        }
    }
    
    private func foodItemView(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Food name", text: item.name)
                .font(.headline)
                .dismissKeyboardOnSwipe()
            
            TextField("Portion (e.g., 1 cup, 200g)", text: item.qtyText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .dismissKeyboardOnSwipe()
            
            itemNutritionGrid(item: item)
        }
        .padding(.vertical, 4)
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }
    
    private func itemNutritionGrid(item: Binding<EditableParsedItem>) -> some View {
        VStack(spacing: 8) {
            HStack {
                caloriesField(item: item)
                proteinField(item: item)
                carbsField(item: item)
            }
            
            HStack {
                fatField(item: item)
                sugarField(item: item)
            }
        }
    }
    
    private func caloriesField(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading) {
            Text("Calories")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", value: item.calories, format: .number)
                .keyboardType(.decimalPad)
        }
    }
    
    private func proteinField(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading) {
            Text("Protein (g)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", value: item.protein, format: .number)
                .keyboardType(.decimalPad)
        }
    }
    
    private func carbsField(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading) {
            Text("Carbs (g)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", value: item.carbs, format: .number)
                .keyboardType(.decimalPad)
        }
    }
    
    private func fatField(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading) {
            Text("Fat (g)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", value: item.fat, format: .number)
                .keyboardType(.decimalPad)
        }
    }
    
    private func sugarField(item: Binding<EditableParsedItem>) -> some View {
        VStack(alignment: .leading) {
            Text("Sugar (g)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", value: item.sugar, format: .number)
                .keyboardType(.decimalPad)
        }
    }
    
    private var isValid: Bool {
        !items.isEmpty && items.allSatisfy { !$0.name.isEmpty && $0.calories > 0 }
    }
    
    private func saveMeal() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        // Filter out empty items
        let validItems = items.filter { !$0.name.isEmpty }
        guard !validItems.isEmpty else {
            errorMessage = "Please add at least one food item"
            return
        }
        
        // 1️⃣ CALCULATE TOTALS
        let totalCals = validItems.reduce(0) { $0 + $1.calories }
        let totalProtein = validItems.reduce(0) { $0 + $1.protein }
        let totalCarbs = validItems.reduce(0) { $0 + $1.carbs }
        let totalFat = validItems.reduce(0) { $0 + $1.fat }
        let totalSugar = validItems.reduce(0) { $0 + $1.sugar }
        
        // 2️⃣ CREATE MEAL ENTRY FOR LOCAL CACHE
        let mealEntry = MealEntry(
            name: validItems.map { $0.name }.joined(separator: ", "),
            calories: totalCals,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            date: Date(),
            mealType: "manual"
        )
        
        // 3️⃣ SAVE TO LOCAL CACHE IMMEDIATELY (Offline-first)
        await MainActor.run {
            UserDataCache.shared.addMealEntry(mealEntry)
            AppLogger.shared.meal("💾 Saved manual meal to cache: \(mealEntry.name)")
        }
        
        // 4️⃣ ALSO ADD TO DAILY LOG FOR HISTORICAL TRACKING
        let mealItems = validItems.map { item in
            MealItem(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                sugar: item.sugar,
                portionSize: nil,
                quantity: item.qtyText.isEmpty ? nil : item.qtyText
            )
        }
        
        let loggedMeal = LoggedMeal(
            timestamp: Date(),
            mealType: .snack, // Could enhance to allow user selection
            items: mealItems,
            totalCalories: totalCals,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalSugar: totalSugar
        )
        
        await MainActor.run {
            LocalDailyLogStore.shared.addMeal(loggedMeal)
        }
        
        // 5️⃣ UPDATE UI IMMEDIATELY
        await MainActor.run {
            showSuccess = true
        }
        
        // 6️⃣ SYNC TO BACKEND IN BACKGROUND (Non-blocking)
        let userId = authVM.userId
        Task.detached(priority: .utility) {
            do {
                let dto = validItems.map { ParsedItemDTO(name: $0.name, qtyText: $0.qtyText, calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fat: $0.fat, sugar: $0.sugar) }
                _ = try await NetworkManager.shared.saveParsedMeal(userId: userId, items: dto)
                
                await MainActor.run {
                    AppLogger.shared.meal("✅ Synced manual meal to backend: \(mealEntry.name)")
                }
            } catch {
                await MainActor.run {
                    AppLogger.shared.logError(error, context: "Failed to sync manual meal to backend")
                    print("⚠️ Manual meal remains in local cache, will retry on next sync")
                }
            }
        }
    }
}

