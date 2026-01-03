import SwiftUI

struct EditableParsedItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var qtyText: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var sugar: Double // Added sugar field
}

struct EditParsedItemsView: View {
    @Binding var items: [EditableParsedItem]
    var onSave: (_ finalItems: [EditableParsedItem]) async -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            List {
                ForEach($items) { $it in
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Item name", text: $it.name)
                            .font(.headline)
                        HStack {
                            TextField("Qty (e.g. 1 cup)", text: $it.qtyText)
                                .textFieldStyle(.roundedBorder)
                            TextField("kcal", value: $it.calories, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 90)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            TextField("Protein g", value: $it.protein, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                            TextField("Carbs g", value: $it.carbs, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                            TextField("Fat g", value: $it.fat, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                            TextField("Sugar g", value: $it.sugar, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete { indexSet in items.remove(atOffsets: indexSet) }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Parsed Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveMeal()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(isSaving || items.isEmpty)
                }
            }
            .disabled(isSaving)
            
            // Loading overlay
            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Saving meal...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(24)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
            }
        }
        .alert("Meal Saved!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your meal has been logged successfully.")
        }
    }
    
    private func saveMeal() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            await onSave(items)
            // Show success and dismiss after a brief delay
            await MainActor.run {
                showSuccess = true
            }
            // Dismiss after showing success
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save meal: \(error.localizedDescription)"
            }
        }
    }
}
