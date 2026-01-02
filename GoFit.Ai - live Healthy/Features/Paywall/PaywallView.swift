import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedPlan: PlanType = .monthly
    @State private var loading = false
    @State private var error: String?
    @State private var animateFeatures = false
    @State private var isBlocking = false // True when trial expired and blocking access
    
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
                // Only show close button if not blocking (trial not expired)
                if !isBlocking {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") { dismiss() }
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .onAppear {
                purchases.loadProducts()
                // Check if this is a blocking paywall (trial expired)
                isBlocking = purchases.requiresSubscription
                withAnimation(.spring().delay(0.1)) {
                    animateFeatures = true
                }
            }
            .onChange(of: purchases.requiresSubscription) { oldValue, newValue in
                isBlocking = newValue
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: isBlocking ? "lock.fill" : "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding()
                .background(Design.Colors.primaryGradient)
                .clipShape(Circle())

            Text(isBlocking ? "Subscription Required" : "Start Your Journey")
                .font(Design.Typography.largeTitle)

            VStack(spacing: 8) {
                if isBlocking {
                    Text("Your 3-day free trial has ended")
                        .font(Design.Typography.title3)
                        .foregroundColor(.primary)
                    
                    Text("Subscribe to continue using all premium features")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.title3)
                            .foregroundColor(Design.Colors.primary)
                        Text("3-Day Free Trial")
                            .font(Design.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Design.Colors.primary)
                    }
                    
                    Text("Then continue with premium features")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            }
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

    // MARK: - Plans
    private var plans: some View {
        VStack(spacing: 16) {
            if purchases.isLoading {
                ProgressView("Loading plans…")
                    .padding()
                    .foregroundColor(.white)
            } else if purchases.products.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Products not available")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Please check your internet connection")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            } else {
                // Show both monthly and yearly plans
                ForEach(purchases.products, id: \.id) { product in
                    let planType: PlanType = product.id == PlanType.monthly.id ? .monthly : .yearly
                    let isSelected = selectedPlan == planType
                    
                    PlanCard(
                        product: product,
                        type: planType,
                        isSelected: isSelected
                    ) {
                        selectedPlan = planType
                    }
                }
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
                VStack(spacing: 8) {
                    // Prominent 3-day free trial badge
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.title3)
                            .foregroundColor(Design.Colors.primary)
                        Text("3-Day Free Trial")
                            .font(Design.Typography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Design.Colors.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Design.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                    
                    Text("Then \(product.displayPrice)/\(selectedPlan.periodText)")
                        .font(Design.Typography.subheadline)
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
                // Purchase successful - update subscription status
                await purchases.checkTrialAndSubscriptionStatus()
                
                await MainActor.run {
                    loading = false
                    // If purchase was successful and subscription is now active, dismiss paywall
                    if purchases.hasActiveSubscription || purchases.subscriptionStatus == .active {
                        if isBlocking {
                            // If this was a blocking paywall, dismiss it now
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    loading = false
                }
            }
        }
    }
}
