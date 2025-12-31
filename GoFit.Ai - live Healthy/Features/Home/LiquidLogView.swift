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
                    Button("Save") {
                        Task {
                            await saveLiquid()
                        }
                    }
                    .disabled(isSaving || amount <= 0)
                    .bold()
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
            let url = NetworkManager.shared.baseURL.appendingPathComponent("health/water")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = AuthService.shared.readToken()?.accessToken {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let payload: [String: Any] = [
                "amount": amount,
                "beverageType": beverageType,
                "beverageName": beverageName,
                "calories": calculateCalories(),
                "sugar": calculateSugar()
            ]
            
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "LiquidLogError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to log liquid"])
            }
            
            showSuccess = true
        } catch {
            errorMessage = "Failed to log liquid: \(error.localizedDescription)"
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

