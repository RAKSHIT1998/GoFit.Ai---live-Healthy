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
        NavigationStack {
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
                    .frame(maxWidth: 600) // Limit width on iPad for better layout
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
                // Show both monthly and yearly plans with subscription details
                ForEach(purchases.products, id: \.id) { product in
                    let planType: PlanType = product.id == PlanType.monthly.id ? .monthly : .yearly
                    let isSelected = selectedPlan == planType
                    
                    VStack(spacing: Design.Spacing.sm) {
                        PlanCard(
                            product: product,
                            type: planType,
                            isSelected: isSelected
                        ) {
                            withAnimation(.spring()) {
                                selectedPlan = planType
                            }
                        }
                        
                        // Display subscription details for selected plan (Apple requirement)
                        if isSelected {
                            subscriptionDetailsView(product: product, planType: planType)
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

    // MARK: - Terms & Subscription Info
    private var terms: some View {
        VStack(spacing: Design.Spacing.md) {
            // Required Subscription Information (Apple Guidelines 3.1.2)
            if let product = purchases.getProduct(id: selectedPlan.id) {
                VStack(spacing: Design.Spacing.sm) {
                    // Subscription Title
                    Text("GoFit.Ai Premium")
                        .font(Design.Typography.headline)
                        .foregroundColor(.primary)
                    
                    // Subscription Length
                    Text("Auto-renewable subscription")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Subscription Period
                    Text("\(selectedPlan.periodText.capitalized) subscription")
                        .font(Design.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Price Information
                    VStack(spacing: 4) {
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
                        
                        // Price per unit if applicable
                        if selectedPlan == .yearly {
                            let monthlyPrice = product.price / 12.0
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .currency
                            formatter.locale = Locale.current
                            if let monthlyPriceString = formatter.string(from: NSDecimalNumber(decimal: monthlyPrice)) {
                                Text("\(monthlyPriceString) per month")
                                    .font(Design.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, Design.Spacing.sm)
                    
                    Text("Cancel anytime in Settings")
                        .font(Design.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(Design.Spacing.md)
                .background(Design.Colors.cardBackground)
                .cornerRadius(Design.Radius.medium)
            }
            
            // Required Links (Apple Guidelines 3.1.2)
            VStack(spacing: Design.Spacing.sm) {
                // Terms of Use (EULA) Link
                Link(destination: URL(string: "https://gofit.ai/terms")!) {
                    HStack {
                        Text("Terms of Use")
                            .font(Design.Typography.caption)
                            .foregroundColor(Design.Colors.primary)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(Design.Colors.primary)
                    }
                }
                
                // Privacy Policy Link
                Link(destination: URL(string: "https://gofit.ai/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .font(Design.Typography.caption)
                            .foregroundColor(Design.Colors.primary)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(Design.Colors.primary)
                    }
                }
            }
            .padding(.vertical, Design.Spacing.sm)
            
            // Restore Purchases
            Button("Restore Purchases") {
                Task { 
                    do {
                        try await purchases.restorePurchases()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .font(Design.Typography.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.top, Design.Spacing.sm)
    }

    // MARK: - Subscription Details (Required by Apple)
    private func subscriptionDetailsView(product: Product, planType: PlanType) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            // Title
            Text("Subscription Details")
                .font(Design.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Subscription length
            HStack {
                Text("Length:")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                Text("\(planType.periodText.capitalized)")
                    .font(Design.Typography.caption)
                    .foregroundColor(.primary)
            }
            
            // Price
            HStack {
                Text("Price:")
                    .font(Design.Typography.caption)
                    .foregroundColor(.secondary)
                Text("\(product.displayPrice) per \(planType.periodText)")
                    .font(Design.Typography.caption)
                    .foregroundColor(.primary)
            }
            
            // Price per unit (for yearly)
            if planType == .yearly {
                let monthlyPrice = product.price / 12.0
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = Locale.current
                if let monthlyPriceString = formatter.string(from: NSDecimalNumber(decimal: monthlyPrice)) {
                    HStack {
                        Text("Price per month:")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(monthlyPriceString)
                            .font(Design.Typography.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Spacing.sm)
        .background(Design.Colors.secondaryBackground)
        .cornerRadius(Design.Radius.small)
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
        } catch let purchaseError {
            await MainActor.run {
                loading = false
                if let purchaseError = purchaseError as? PurchaseError {
                    switch purchaseError {
                    case .userCancelled:
                        // Don't show error for user cancellation
                        break
                    default:
                        self.error = purchaseError.localizedDescription
                    }
                } else {
                    self.error = purchaseError.localizedDescription
                }
            }
        }
    }
}
