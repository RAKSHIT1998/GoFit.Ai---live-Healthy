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
                        Button("Close") { 
                            dismiss() 
                        }
                        .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .onAppear {
                // Load products when paywall appears
                purchases.loadProducts()
                
                // Check if this is a blocking paywall (trial expired)
                isBlocking = purchases.requiresSubscription
                
                // Animate features
                withAnimation(.spring().delay(0.1)) {
                    animateFeatures = true
                }
            }
            .onChange(of: purchases.requiresSubscription) { oldValue, newValue in
                isBlocking = newValue
            }
            .onChange(of: purchases.hasActiveSubscription) { oldValue, newValue in
                // When subscription becomes active, only dismiss if this was a blocking paywall
                // For non-blocking paywalls (after signup), let user dismiss manually
                if newValue && isBlocking {
                    // If this was a blocking paywall and subscription is now active, dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
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
                        .foregroundColor(.primary)
                    Text("Please check your internet connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        withAnimation(.spring()) {
                            selectedPlan = planType
                        }
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
                Task {
                    await purchase()
                }
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
            .disabled(loading || purchases.isLoading || purchases.products.isEmpty)

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
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

    private func purchase() async {
        loading = true
        error = nil

        do {
            try await purchases.purchase(productId: selectedPlan.id)
            // Purchase successful - update subscription status
            await purchases.checkTrialAndSubscriptionStatus()
            
            await MainActor.run {
                loading = false
                // Only auto-dismiss if this was a blocking paywall
                // For non-blocking paywalls (after signup), user can dismiss manually
                if isBlocking && (purchases.hasActiveSubscription || purchases.subscriptionStatus == .active) {
                    // Give user a moment to see success before dismissing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                }
            }
        } catch {
            await MainActor.run {
                loading = false
                if let purchaseError = error as? PurchaseError {
                    switch purchaseError {
                    case .userCancelled:
                        // Don't show error for user cancellation
                        break
                    default:
                        error = purchaseError.localizedDescription
                    }
                } else {
                    error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Design.Colors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Design.Typography.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(Design.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Design.Colors.cardBackground)
        .cornerRadius(12)
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -20)
        .onAppear {
            withAnimation(.spring().delay(delay)) {
                animate = true
            }
        }
    }
}
