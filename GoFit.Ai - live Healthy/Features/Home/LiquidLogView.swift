import SwiftUI

struct LiquidLogView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var beverageType: String = "water"
    @State private var beverageName: String = ""
    @State private var amount: Double = 0.25 // Default 250ml
    @State private var calories: Double = 0
    @State private var sugar: Double = 0
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    let beverageTypes = [
        ("water", "Water", "drop.fill"),
        ("soda", "Soda", "bubbles.and.sparkles"),
        ("soft_drink", "Soft Drink", "cup.and.saucer.fill"),
        ("juice", "Juice", "leaf.fill"),
        ("coffee", "Coffee", "cup.fill"),
        ("tea", "Tea", "cup.and.saucer"),
        ("beer", "Beer", "mug.fill"),
        ("wine", "Wine", "wineglass.fill"),
        ("liquor", "Liquor", "wineglass"),
        ("other", "Other", "drop")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Beverage Type") {
                    Picker("Type", selection: $beverageType) {
                        ForEach(beverageTypes, id: \.0) { type, name, icon in
                            HStack {
                                Image(systemName: icon)
                                Text(name)
                            }
                            .tag(type)
                        }
                    }
                }
                
                if beverageType != "water" {
                    Section("Beverage Name") {
                        TextField("e.g., Coca Cola, Red Wine, Whiskey", text: $beverageName)
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Slider(value: $amount, in: 0.1...2.0, step: 0.05)
                        Text("\(String(format: "%.2f", amount))L")
                            .frame(width: 60)
                            .font(.headline)
                    }
                    
                    // Quick amount buttons
                    HStack(spacing: 12) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                            Button(action: {
                                amount = value
                            }) {
                                Text("\(Int(value * 1000))ml")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(amount == value ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(amount == value ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if beverageType != "water" {
                    Section("Nutrition (Auto-calculated)") {
                        HStack {
                            Text("Calories:")
                            Spacer()
                            Text("\(Int(calculateCalories()))")
                                .foregroundColor(Design.Colors.calories)
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("Sugar:")
                            Spacer()
                            Text("\(String(format: "%.1f", calculateSugar()))g")
                                .foregroundColor(Design.Colors.sugar)
                                .fontWeight(.semibold)
                        }
                        Text("Values are automatically calculated based on beverage type and amount")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
            .navigationTitle("Log Liquid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveLiquid()
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
                    .disabled(isSaving || amount <= 0)
                }
            }
            .alert("Liquid Logged!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveLiquid() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            // Use NetworkManager's request method for consistency and proper error handling
            struct WaterLogRequest: Codable {
                let amount: Double
                let beverageType: String
                let beverageName: String
                let calories: Double
                let sugar: Double
            }
            
            struct WaterLogResponse: Codable {
                let _id: String?
                let amount: Double
                let beverageType: String
            }
            
            let requestBody = WaterLogRequest(
                amount: amount,
                beverageType: beverageType,
                beverageName: beverageName,
                calories: calculateCalories(),
                sugar: calculateSugar()
            )
            
            let bodyData = try JSONEncoder().encode(requestBody)
            
            let _: WaterLogResponse = try await NetworkManager.shared.request(
                "health/water",
                method: "POST",
                body: bodyData
            )
            
            // Success - show alert and dismiss
            await MainActor.run {
                showSuccess = true
            }
        } catch {
            print("❌ Failed to log liquid: \(error)")
            await MainActor.run {
                if let nsError = error as NSError? {
                    let errorMessageText = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    errorMessage = "Failed to log liquid: \(errorMessageText)"
                } else {
                    errorMessage = "Failed to log liquid: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Calculate calories based on beverage type and amount
    private func calculateCalories() -> Double {
        if beverageType == "water" { return 0 }
        
        let caloriesPerLiter: [String: Double] = [
            "soda": 420,
            "soft_drink": 420,
            "juice": 450,
            "coffee": 2,
            "tea": 2,
            "beer": 430,
            "wine": 830,
            "liquor": 2310,
            "other": 0
        ]
        
        return Double(Int((caloriesPerLiter[beverageType] ?? 0) * amount))
    }
    
    // Calculate sugar based on beverage type and amount
    private func calculateSugar() -> Double {
        if beverageType == "water" { return 0 }
        
        let sugarPerLiter: [String: Double] = [
            "soda": 108,
            "soft_drink": 108,
            "juice": 100,
            "coffee": 0,
            "tea": 0,
            "beer": 0,
            "wine": 2,
            "liquor": 0,
            "other": 0
        ]
        
        return round((sugarPerLiter[beverageType] ?? 0) * amount * 10) / 10
    }
}

