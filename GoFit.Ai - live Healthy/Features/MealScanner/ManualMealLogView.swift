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
                Section("Meal Type") {
                    Picker("Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }
                
                Section("Food Items") {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Food name", text: $item.name)
                                .font(.headline)
                            
                            TextField("Portion (e.g., 1 cup, 200g)", text: $item.qtyText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Calories")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", value: $item.calories, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Protein (g)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", value: $item.protein, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Carbs (g)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", value: $item.carbs, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Fat (g)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", value: $item.fat, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Sugar (g)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", value: $item.sugar, format: .number)
                                        .keyboardType(.decimalPad)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                        if items.isEmpty {
                            items = [EditableParsedItem(name: "", qtyText: "", calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0)]
                        }
                    }
                    
                    Button(action: {
                        items.append(EditableParsedItem(name: "", qtyText: "", calories: 0, protein: 0, carbs: 0, fat: 0, sugar: 0))
                    }) {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Log Meal Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveMeal()
                        }
                    }
                    .disabled(isSaving || !isValid)
                    .bold()
                }
            }
            .alert("Meal Saved!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            }
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
        
        do {
            let dto = validItems.map { ParsedItemDTO(name: $0.name, qtyText: $0.qtyText, calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fat: $0.fat, sugar: $0.sugar) }
            _ = try await NetworkManager.shared.saveParsedMeal(userId: authVM.userId, items: dto)
            showSuccess = true
        } catch {
            errorMessage = "Failed to save meal: \(error.localizedDescription)"
        }
    }
}

