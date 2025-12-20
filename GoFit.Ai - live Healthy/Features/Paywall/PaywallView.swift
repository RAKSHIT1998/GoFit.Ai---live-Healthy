import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedPlan: PlanType = .monthly
    @State private var loading = false
    @State private var error: String?
    @State private var animateFeatures = false
    
    enum PlanType {
        case monthly
        case yearly
        
        var id: String {
            switch self {
            case .monthly: return "com.gofitai.premium.monthly"
            case .yearly: return "com.gofitai.premium.yearly"
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
        NavigationView {
            ZStack {
                // Adaptive background for dark mode
                Design.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Design.Spacing.xl) {
                        header
                        features
                        plans
                        ctaButton
                        terms
                    }
                    .padding(.bottom, Design.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Design.Colors.primary)
                }
            }
            .onAppear {
                purchases.loadProducts()
                withAnimation(.spring().delay(0.1)) {
                    animateFeatures = true
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding()
                .background(Design.Colors.primaryGradient)
                .clipShape(Circle())

            Text("Unlock Premium")
                .font(Design.Typography.largeTitle)

            Text("AI-powered nutrition & fitness tracking")
                .font(Design.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }

    // MARK: - Features
    private var features: some View {
        VStack(spacing: 12) {
            FeatureRow(icon: "camera.fill", title: "Unlimited AI Scans", description: "Scan meals instantly", delay: 0.1)
            FeatureRow(icon: "sparkles", title: "Smart AI Coach", description: "Daily meal & workout plans", delay: 0.2)
            FeatureRow(icon: "chart.bar.fill", title: "Advanced Insights", description: "Track progress easily", delay: 0.3)
            FeatureRow(icon: "applewatch", title: "Apple Watch Sync", description: "HealthKit integration", delay: 0.4)
        }
        .opacity(animateFeatures ? 1 : 0)
    }

    // MARK: - Plans (Monthly only)
    private var plans: some View {
        VStack(spacing: 16) {

            if let monthly = purchases.products.first(
                where: { $0.id == PlanType.monthly.id }
            ) {
                PlanCard(
                    product: monthly,
                    type: .monthly,
                    isSelected: true
                ) {
                    selectedPlan = .monthly
                }
            } else {
                ProgressView("Loading plan…")
            }
        }
        .padding(.horizontal)
    }


    // MARK: - CTA
    private var ctaButton: some View {
        VStack(spacing: 12) {
            Button {
                purchase()
            } label: {
                HStack {
                    if loading {
                        ProgressView().tint(.white)
                    } else {
                        VStack(spacing: 4) {
                            Text("Start 3-Day Free Trial")
                                .font(Design.Typography.headline)
                            if let product = purchases.getProduct(id: selectedPlan.id) {
                                Text("Then \(product.displayPrice)/\(selectedPlan.periodText)")
                                    .font(Design.Typography.caption2)
                                    .opacity(0.9)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Design.Colors.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(loading || purchases.isLoading)

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Terms
    private var terms: some View {
        VStack(spacing: 8) {
            if let product = purchases.getProduct(id: selectedPlan.id) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.caption2)
                            .foregroundColor(Design.Colors.primary)
                        Text("3-day free trial")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Design.Colors.primary)
                    }
                    
                    Text("Then \(product.displayPrice)/\(selectedPlan.periodText)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Cancel anytime in Settings")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button("Restore Purchases") {
                Task { 
                    do {
                        try await purchases.restorePurchases()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.top, Design.Spacing.sm)
    }

    private func purchase() {
        loading = true
        error = nil

        Task {
            do {
                try await purchases.purchase(productId: selectedPlan.id)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
