import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {

    // MARK: - Published State
    @Published var hasActiveSubscription = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var products: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var currentSubscription: CurrentSubscriptionInfo?
    @Published var requiresSubscription = false // Blocks app access if trial expired and no subscription
    @Published var showPaywall = false // Controls paywall visibility
    @Published var trialDaysRemaining: Int? = nil

    // MARK: - Product IDs
    let monthlyID = "com.gofitai.premium.monthly"
    let yearlyID = "com.gofitai.premium.yearly"

    // MARK: - Tasks
    private var updateListenerTask: Task<Void, Error>?
    private var statusUpdateTask: Task<Void, Never>?

    // MARK: - Enums
    enum SubscriptionStatus {
        case unknown
        case free
        case trial
        case active
        case expired
        case cancelled
    }

    // MARK: - Models
    struct CurrentSubscriptionInfo {
        let productId: String
        let expirationDate: Date?
        let isInTrialPeriod: Bool
        let renewalInfo: Product.SubscriptionInfo.RenewalInfo?
    }

    // MARK: - UserDefaults Keys
    private let trialStartDateKey = "trialStartDate"
    
    // MARK: - Init
    init() {
        updateListenerTask = listenForTransactions()
        startStatusMonitoring()
        initializeTrialIfNeeded()
    }
    
    // MARK: - Trial Management
    private func initializeTrialIfNeeded() {
        // Only set trial start date if it hasn't been set yet
        if UserDefaults.standard.object(forKey: trialStartDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: trialStartDateKey)
            print("📅 Trial started: \(Date())")
        }
    }
    
    func getTrialStartDate() -> Date? {
        return UserDefaults.standard.object(forKey: trialStartDateKey) as? Date
    }
    
    func getTrialEndDate() -> Date? {
        guard let startDate = getTrialStartDate() else { return nil }
        return Calendar.current.date(byAdding: .day, value: 3, to: startDate)
    }
    
    func isTrialActive() -> Bool {
        guard let endDate = getTrialEndDate() else { return false }
        return Date() < endDate
    }
    
    func getTrialDaysRemaining() -> Int? {
        guard let endDate = getTrialEndDate() else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    func checkTrialAndSubscriptionStatus() async {
        // Update subscription status first (but don't call checkTrialAndSubscriptionStatus again to avoid recursion)
        await updateSubscriptionStatus()
        await checkSubscriptionStatus()
        
        // Check if user has active subscription (including trial from StoreKit)
        let hasSubscription = hasActiveSubscription || subscriptionStatus == .trial || subscriptionStatus == .active
        
        // Check if local 3-day trial is still active
        let localTrialActive = isTrialActive()
        
        // Calculate trial days remaining
        trialDaysRemaining = getTrialDaysRemaining()
        
        // If user has active subscription, they can access the app
        if hasSubscription {
            requiresSubscription = false
            showPaywall = false
            print("✅ User has active subscription - access granted")
            return
        }
        
        // If local trial is still active, allow access
        if localTrialActive {
            requiresSubscription = false
            showPaywall = false
            print("✅ Trial still active (\(trialDaysRemaining ?? 0) days remaining) - access granted")
            return
        }
        
        // Trial expired and no subscription - block access
        requiresSubscription = true
        showPaywall = true
        print("🚫 Trial expired and no subscription - blocking app access")
    }

    deinit {
        updateListenerTask?.cancel()
        statusUpdateTask?.cancel()
    }

    // MARK: - Product Loading
    func loadProducts() {
        Task {
            await requestProducts()
            await updateSubscriptionStatus()
        }
    }

    func requestProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [monthlyID, yearlyID])
            print("✅ Loaded \(products.count) products")
            
            if products.isEmpty {
                print("⚠️ No products found. Make sure products are configured in App Store Connect or StoreKit configuration file.")
                errorMessage = "Subscription products not available. Please check your App Store Connect configuration."
            }
        } catch {
            print("❌ Product load failed:", error)
            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase
    func purchase(productId: String) async throws {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw PurchaseError.productNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            await updateSubscriptionStatus()
            await verifyReceiptWithBackend(transaction: transaction)
            await transaction.finish()

            hasActiveSubscription = true
            
            // Recheck trial and subscription status after purchase
            await checkTrialAndSubscriptionStatus()

        case .userCancelled:
            throw PurchaseError.userCancelled

        case .pending:
            throw PurchaseError.pending

        @unknown default:
            throw PurchaseError.unknown
        }
    }

    // MARK: - Restore
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await updateSubscriptionStatus()
        await checkSubscriptionStatus()
    }

    // MARK: - Subscription Status
    func updateSubscriptionStatus() async {
        // If products haven't loaded yet, try to load them first
        if products.isEmpty {
            await requestProducts()
        }

        var highestStatus: SubscriptionStatus = .free
        var highestProduct: Product?
        var highestExpiration: Date?
        var isInTrial = false

        for product in products {
            guard let subscription = product.subscription else { continue }
            guard let statuses = try? await subscription.status else { continue }

            for status in statuses {
                switch status.state {
                case .subscribed:
                    if let transaction = try? checkVerified(status.transaction) {
                        let expiration = transaction.expirationDate ?? .distantFuture

                        if highestExpiration == nil || expiration > highestExpiration! {
                            highestStatus = .active
                            highestProduct = product
                            highestExpiration = expiration

                            // Check if in trial period - look at transaction purchase date vs current date
                            // If purchase was within last 3 days and has intro offer, likely in trial
                            // Note: transaction.purchaseDate is non-optional in StoreKit 2's Transaction type
                            // The compiler enforces this (verified by compilation error fix), so no optional binding is needed
                            // However, we're already inside a verified transaction block, so purchaseDate is guaranteed to exist
                            let purchaseDate = transaction.purchaseDate
                            
                            // Defensive check: Ensure purchaseDate is valid (though compiler guarantees it's non-optional)
                            // This is extra safety in case of any edge cases or future API changes
                            // If purchase date is in the future (shouldn't happen), skip trial check but continue processing
                            if purchaseDate <= Date() {
                                let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                                if daysSincePurchase < 3 && product.subscription?.introductoryOffer != nil {
                                    highestStatus = .trial
                                    isInTrial = true
                                }
                            } else {
                                print("⚠️ Warning: Transaction purchase date is in the future: \(purchaseDate), skipping trial check")
                            }
                        }
                    }

                case .inGracePeriod:
                    if highestStatus != .active && highestStatus != .trial {
                        highestStatus = .active
                    }

                case .inBillingRetryPeriod:
                    if highestStatus != .active && highestStatus != .trial {
                        highestStatus = .active
                    }

                case .expired:
                    if highestStatus == .free {
                        highestStatus = .expired
                    }

                case .revoked:
                    if highestStatus == .free {
                        highestStatus = .cancelled
                    }

                default:
                    break
                }
            }
        }

        subscriptionStatus = highestStatus
        hasActiveSubscription = (highestStatus == .active || highestStatus == .trial)

        if let product = highestProduct {
            currentSubscription = CurrentSubscriptionInfo(
                productId: product.id,
                expirationDate: highestExpiration,
                isInTrialPeriod: isInTrial,
                renewalInfo: nil
            )
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await self.verifyReceiptWithBackend(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed:", error)
                }
            }
        }
    }

    // MARK: - Periodic Status Check
    private func startStatusMonitoring() {
        statusUpdateTask = Task {
            while !Task.isCancelled {
                await updateSubscriptionStatus()
                await checkTrialAndSubscriptionStatus() // Also check trial status periodically
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every minute
            }
        }
    }

    // MARK: - Backend Verification
    private func verifyReceiptWithBackend(transaction: Transaction) async {
        do {
            print("🔄 Verifying subscription with backend...")
            let payload = transaction.jsonRepresentation.base64EncodedString()

            struct Request: Codable {
                let transactionData: String
                let productId: String
                let transactionId: UInt64
            }

            let body = Request(
                transactionData: payload,
                productId: transaction.productID,
                transactionId: transaction.id
            )

            let url = URL(string: "\(NetworkManager.shared.baseURL)/subscriptions/verify")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 30.0

            guard let token = AuthService.shared.readToken()?.accessToken else {
                print("❌ No auth token found for subscription verification")
                return
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            req.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from subscription verification")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Subscription verification failed with status \(httpResponse.statusCode): \(errorMessage)")
                return
            }
            
            print("✅ Subscription verified successfully with backend")
            
            // Decode response to get subscription status
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["subscriptionStatus"] as? String {
                print("📊 Subscription status: \(status)")
            }

        } catch {
            print("❌ Backend verification error: \(error.localizedDescription)")
        }
    }

    func checkSubscriptionStatus() async {
        do {
            print("🔄 Checking subscription status with backend...")
            let url = URL(string: "\(NetworkManager.shared.baseURL)/subscriptions/status")!
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.timeoutInterval = 30.0

            guard let token = AuthService.shared.readToken()?.accessToken else {
                print("❌ No auth token found for subscription status check")
                return
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from subscription status check")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Subscription status check failed with status \(httpResponse.statusCode): \(errorMessage)")
                return
            }

            struct Response: Codable {
                let hasActiveSubscription: Bool
                let subscription: SubscriptionInfo?
                let isInTrial: Bool?
                let trialDaysRemaining: Int?
            }
            
            struct SubscriptionInfo: Codable {
                let status: String
                let plan: String?
                let endDate: String?
            }

            let backendResponse = try JSONDecoder().decode(Response.self, from: data)
            hasActiveSubscription = backendResponse.hasActiveSubscription
            
            if let isInTrial = backendResponse.isInTrial, isInTrial {
                subscriptionStatus = .trial
            } else if backendResponse.hasActiveSubscription {
                subscriptionStatus = .active
            } else {
                subscriptionStatus = .expired
            }
            
            print("✅ Subscription status from backend: \(backendResponse.hasActiveSubscription ? "Active" : "Inactive")")
            if let daysRemaining = backendResponse.trialDaysRemaining {
                print("📊 Trial days remaining: \(daysRemaining)")
            }

        } catch {
            print("❌ Subscription status fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseError.unverified
        }
    }

    func getProduct(id: String) -> Product? {
        products.first { $0.id == id }
    }

    func formatPrice(for product: Product) -> String {
        product.displayPrice
    }

    func hasIntroOffer(for product: Product) -> Bool {
        product.subscription?.introductoryOffer != nil
    }
}

// MARK: - Errors
enum PurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unverified
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription not found."
        case .userCancelled:
            return "Purchase cancelled."
        case .pending:
            return "Purchase pending."
        case .unverified:
            return "Transaction verification failed."
        case .unknown:
            return "Unknown error occurred."
        }
    }
}
