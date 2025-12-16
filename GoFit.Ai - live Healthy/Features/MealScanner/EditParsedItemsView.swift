import SwiftUI

struct EditableParsedItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var qtyText: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

struct EditParsedItemsView: View {
    @Binding var items: [EditableParsedItem]
    var onSave: (_ finalItems: [EditableParsedItem]) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
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
                            .frame(width: 90)
                            .textFieldStyle(.roundedBorder)
                        TextField("Carbs g", value: $it.carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 90)
                            .textFieldStyle(.roundedBorder)
                        TextField("Fat g", value: $it.fat, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 90)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 6)
            }
            .onDelete { indexSet in items.remove(atOffsets: indexSet) }
        }
        .navigationTitle("Edit Parsed Items")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(items)
                    dismiss()
                }
                .bold()
            }
        }
    }
}
