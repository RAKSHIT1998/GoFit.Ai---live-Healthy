//
//  OnboardingSubscriptionView.swift
//  GoFit.Ai - live Healthy
//
//  Created for onboarding paywall with skip option
//

import SwiftUI
import StoreKit

struct OnboardingSubscriptionView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @Binding var shouldSkipWithAds: Bool
    
    @State private var selectedPlan: PlanType = .yearly
    @State private var loading = false
    @State private var error: String?
    @State private var animateFeatures = false
    
    enum PlanType {
        case monthly
        case yearly
        
        var id: String {
            switch self {
            case .monthly: return "com.gofitai.premium.monthlyy"
            case .yearly: return "com.gofitai.premium.yearlyyy"
            }
        }
        
        var periodText: String {
            switch self {
            case .monthly: return "month"
            case .yearly: return "year"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Design.Colors.primary.opacity(0.15),
                    Design.Colors.primary.opacity(0.05),
                    Design.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    Spacer().frame(height: 20)
                    
                    header
                    features
                    plans
                    subscribeButton
                    skipButton
                    terms
                }
                .padding(.horizontal, Design.Spacing.lg)
                .padding(.bottom, Design.Spacing.xl)
            }
        }
        .onAppear {
            purchases.loadProducts()
            withAnimation(.spring().delay(0.1)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding(24)
                .background(Design.Colors.primaryGradient)
                .clipShape(Circle())
                .shadow(color: Design.Colors.primary.opacity(0.3), radius: 20, y: 10)
            
            Text("Unlock Premium")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                        .foregroundColor(Design.Colors.primary)
                    Text("3-Day Free Trial")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Design.Colors.primary)
                }
                
                Text("Then unlock all premium features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features
    private var features: some View {
        VStack(spacing: 14) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Scans",
                description: "Scan unlimited meals with AI",
                delay: 0.1
            )
            
            FeatureRow(
                icon: "sparkles",
                title: "More Recommendations",
                description: "10+ daily personalized plans",
                delay: 0.2
            )
            
            FeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                description: "Deep insights & tracking",
                delay: 0.3
            )
            
            FeatureRow(
                icon: "rectangle.slash",
                title: "Ad-Free Experience",
                description: "Enjoy without interruptions",
                delay: 0.4
            )
            
            FeatureRow(
                icon: "applewatch",
                title: "Apple Watch Sync",
                description: "Full HealthKit integration",
                delay: 0.5
            )
        }
        .padding()
        .background(Design.Colors.cardBackground)
        .cornerRadius(20)
        .opacity(animateFeatures ? 1 : 0)
        .offset(y: animateFeatures ? 0 : 20)
    }
    
    // MARK: - Plans
    private var plans: some View {
        VStack(spacing: 16) {
            if purchases.isLoading {
                ProgressView("Loading plans…")
                    .padding()
            } else if purchases.products.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Products not available")
                        .font(.headline)
                    Text("Please check your connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                let relevantProducts = purchases.products
                    .filter { $0.id == PlanType.monthly.id || $0.id == PlanType.yearly.id }
                    .sorted { lhs, rhs in
                        if lhs.id == PlanType.yearly.id { return true }
                        if rhs.id == PlanType.yearly.id { return false }
                        return lhs.id < rhs.id
                    }
                
                if !relevantProducts.isEmpty {
                    ForEach(relevantProducts, id: \.id) { product in
                        let planType: PlanType = product.id == PlanType.monthly.id ? .monthly : .yearly
                        let isSelected = selectedPlan == planType
                        
                        OnboardingPlanCard(
                            product: product,
                            type: planType,
                            isSelected: isSelected
                        ) {
                            selectedPlan = planType
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button(action: {
            Task {
                await purchaseSubscription()
            }
        }) {
            HStack {
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "crown.fill")
                    Text("Start Free Trial")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Design.Colors.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Design.Colors.primary.opacity(0.3), radius: 15, y: 5)
        }
        .disabled(loading || purchases.products.isEmpty)
        .opacity((loading || purchases.products.isEmpty) ? 0.6 : 1)
    }
    
    // MARK: - Skip Button
    private var skipButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                shouldSkipWithAds = true
                dismiss()
            }) {
                HStack {
                    Image(systemName: "rectangle.stack.badge.play.fill")
                        .font(.subheadline)
                    Text("Skip and use with ads")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Design.Colors.cardBackground)
                .foregroundColor(.secondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            
            Text("Limited features • Ads included")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Terms
    private var terms: some View {
        VStack(spacing: 8) {
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Text("Cancel anytime. No commitment.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Purchase Logic
    private func purchaseSubscription() async {
        guard !loading else { return }
        loading = true
        error = nil
        
        guard let product = purchases.products.first(where: { $0.id == selectedPlan.id }) else {
            error = "Product not found"
            loading = false
            return
        }
        
        do {
            try await purchases.purchase(productId: product.id)
            // Purchase successful - dismiss the view
            dismiss()
        } catch {
            self.error = "Purchase failed: \(error.localizedDescription)"
        }
        
        loading = false
    }
}

// MARK: - Plan Card for Onboarding
struct OnboardingPlanCard: View {
    let product: Product
    let type: OnboardingSubscriptionView.PlanType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(type == .yearly ? "Yearly" : "Monthly")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if type == .yearly {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Design.Colors.primary)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if type == .yearly, let _ = product.subscription {
                        let monthlyPrice = (product.price as NSDecimalNumber).doubleValue / 12
                        Text("Only \(String(format: "$%.2f", monthlyPrice))/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("3-day free trial, then \(product.displayPrice)/\(type.periodText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Design.Colors.primary : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Design.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Design.Colors.primary : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingSubscriptionView(shouldSkipWithAds: .constant(false))
        .environmentObject(PurchaseManager())
}
