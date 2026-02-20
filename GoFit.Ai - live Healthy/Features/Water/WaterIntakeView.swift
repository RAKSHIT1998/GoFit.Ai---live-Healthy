import SwiftUI

/// Quick water intake logging view
struct WaterIntakeView: View {
    @StateObject private var waterManager = WaterIntakeManager.shared
    @State private var showCustomInput = false
    @State private var customAmount = "0.5"
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with goal progress
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Water Intake")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("\(Int(waterManager.waterIntakePercentage))% of daily goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(waterManager.formattedIntake)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .transition(.scale)
                        
                        Text("Goal: \(String(format: "%.1f L", waterManager.waterGoal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Progress bar with smooth animation
                SmoothProgressView(
                    progress: waterManager.waterIntakePercentage / 100,
                    height: 8
                )
            }
            
            // Quick log buttons
            VStack(spacing: 12) {
                Text("Quick Log")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 10) {
                    // Row 1: Small, Medium, Large
                    HStack(spacing: 10) {
                        QuickLogButton(
                            preset: .small,
                            action: {
                                HapticManager.shared.lightTap()
                                waterManager.logWaterPreset(amount: .small)
                            }
                        )
                        
                        QuickLogButton(
                            preset: .medium,
                            action: {
                                HapticManager.shared.lightTap()
                                waterManager.logWaterPreset(amount: .medium)
                            }
                        )
                        
                        QuickLogButton(
                            preset: .large,
                            action: {
                                HapticManager.shared.lightTap()
                                waterManager.logWaterPreset(amount: .large)
                            }
                        )
                    }
                    
                    // Row 2: Bottle, Custom
                    HStack(spacing: 10) {
                        QuickLogButton(
                            preset: .bottle,
                            action: {
                                HapticManager.shared.lightTap()
                                waterManager.logWaterPreset(amount: .bottle)
                            }
                        )
                        
                        Button(action: {
                            HapticManager.shared.mediumTap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCustomInput = true
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                Text("Custom")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.blue)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        }
                        .buttonStyle(SmoothButtonStyle())
                    }
                }
            }
            
            // Today's intake history with staggered animations
            if !waterManager.intakeLogs.isEmpty {
                VStack(spacing: 10) {
                    Text("Today's Intake")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(waterManager.intakeLogs.reversed().enumerated()), id: \.element.id) { index, log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.formattedVolume)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(log.formattedTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "drop.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .transition(.moveAndFade)
                            .delayedAppear(Double(index) * 0.05)
                        }
                    }
                }
            }
            
            // Goal status with animation
            if waterManager.isGoalMet {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Daily water goal achieved!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .transition(.moveAndFade)
            } else if waterManager.waterRemaining > 0 {
                HStack {
                    Image(systemName: "drop.circle")
                        .foregroundColor(.blue)
                    Text("You need \(String(format: "%.1f", waterManager.waterRemaining))L more")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showCustomInput) {
            CustomWaterInputView(
                isPresented: $showCustomInput,
                customAmount: $customAmount,
                onSave: { amount in
                    if let liters = Double(amount) {
                        waterManager.logWater(liters)
                    }
                    showCustomInput = false
                }
            )
        }
    }
}

/// Individual quick log button
struct QuickLogButton: View {
    let preset: WaterPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .lineLimit(1)
                Text(preset.rawValue.split(separator: "(").first?.trimmingCharacters(in: .whitespaces) ?? "")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(.blue)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
            )
        }
    }
}

/// Custom water amount input view
struct CustomWaterInputView: View {
    @Binding var isPresented: Bool
    @Binding var customAmount: String
    let onSave: (String) -> Void
    
    @State private var unit = "liters" // "liters" or "milliliters"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Enter Amount") {
                    VStack(spacing: 12) {
                        TextField("Amount", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("Unit", selection: $unit) {
                            Text("Liters (L)").tag("liters")
                            Text("Milliliters (ml)").tag("milliliters")
                        }
                    }
                }
                
                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Text("Log Water")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Log Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func save() {
        var liters = Double(customAmount) ?? 0
        if unit == "milliliters" {
            liters = liters / 1000
        }
        
        if liters > 0 {
            onSave(String(liters))
        }
    }
}

#Preview {
    WaterIntakeView()
}
