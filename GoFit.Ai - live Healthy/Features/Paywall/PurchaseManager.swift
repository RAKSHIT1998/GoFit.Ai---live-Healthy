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
    @Published var backendCalculatedEndDate: Date? = nil // Backend's calculated renewal date (proper 1 month/year, not Sandbox-accelerated)

    // MARK: - Product IDs
    // NOTE: These must match exactly with App Store Connect Product IDs
    let monthlyID = "com.gofitai.premium.monthlyy"
    // NOTE: App Store Connect requires this ID (yearlyyy) for this account/subscription group.
    let yearlyID = "com.gofitai.premium.yearlyyy"

    // MARK: - Tasks
    private var updateListenerTask: Task<Void, Error>?
    private var statusUpdateTask: Task<Void, Never>?
    
    // MARK: - Caching
    private var lastStatusCheck: Date?
    private var statusCheckCache: (status: SubscriptionStatus, hasActive: Bool)?
    private let statusCacheTimeout: TimeInterval = 60 // Cache for 1 minute

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
        // Don't initialize trial here - only when user signs up or first uses the app
        // This prevents premature trial start for users who haven't signed up yet
    }
    
    // MARK: - Trial Management
    func initializeTrialForNewUser() {
        // This should be called when a new user signs up or first launches after signup
        // Only set trial start date if it hasn't been set yet and user is logged in
        guard UserDefaults.standard.object(forKey: trialStartDateKey) == nil else {
            print("📅 Trial already initialized")
            return
        }
        
        // Check if user is logged in before starting trial
        guard AuthService.shared.readToken() != nil else {
            print("⚠️ User not logged in - cannot start trial yet")
            return
        }
        
        UserDefaults.standard.set(Date(), forKey: trialStartDateKey)
        print("📅 Trial started for new user: \(Date())")
        
        // Immediately check trial and subscription status after initializing
        Task {
            await checkTrialAndSubscriptionStatus()
        }
    }
    
    private func initializeTrialIfNeeded() {
        // Only set trial start date if it hasn't been set yet AND user is logged in
        guard UserDefaults.standard.object(forKey: trialStartDateKey) == nil else {
            return
        }
        
        // Only initialize trial if user is logged in
        guard AuthService.shared.readToken() != nil else {
            return
        }
        
        UserDefaults.standard.set(Date(), forKey: trialStartDateKey)
        print("📅 Trial initialized: \(Date())")
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
    
    // Public method to check if user is in trial (for UI display)
    var isInTrial: Bool {
        return isTrialActive() || subscriptionStatus == .trial
    }
    
    func checkTrialAndSubscriptionStatus() async {
        // IMPORTANT: This method must NOT call updateSubscriptionStatus()/checkSubscriptionStatus().
        // RootView and other observers may call it on subscriptionStatus changes; if we trigger
        // more subscription updates from here it can create feedback loops and UI lag.
        // First, check if user is logged in - if not, don't check subscription
        guard AuthService.shared.readToken() != nil else {
            print("ℹ️ User not logged in - skipping subscription check")
            requiresSubscription = false
            showPaywall = false
            return
        }
        
        // Initialize trial if needed (only for logged-in users)
        initializeTrialIfNeeded()
        
        // Check if user has active subscription (including trial from StoreKit)
        // Premium active users or users in trial can access
        let hasSubscription = hasActiveSubscription || subscriptionStatus == .trial || subscriptionStatus == .active
        
        // Check if subscription is cancelled (user still has access until endDate)
        let isCancelled = subscriptionStatus == .cancelled
        
        // Check if local 3-day trial is still active (only if trial has been initialized)
        let localTrialActive = isTrialActive()
        
        // Calculate trial days remaining (use backend value if available, otherwise local)
        if trialDaysRemaining == nil {
            trialDaysRemaining = getTrialDaysRemaining()
        }
        
        // If user has active subscription (premium or trial), they can access the app
        if hasSubscription {
            requiresSubscription = false
            showPaywall = false
            if isCancelled {
                print("✅ User has cancelled subscription but still has access until expiration")
            } else {
                print("✅ User has active subscription - access granted")
            }
            return
        }
        
        // If local trial is still active, allow access
        if localTrialActive {
            requiresSubscription = false
            showPaywall = false
            print("✅ Trial still active (\(trialDaysRemaining ?? 0) days remaining) - access granted")
            return
        }
        
        // If trial hasn't been initialized yet (new user), allow access
        // The paywall will be shown after onboarding/signup separately
        if UserDefaults.standard.object(forKey: trialStartDateKey) == nil {
            requiresSubscription = false
            showPaywall = false
            print("ℹ️ Trial not yet initialized - allowing access (paywall shown separately)")
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
            // Avoid re-requesting products repeatedly (this can be expensive and cause UI hitching)
            if products.isEmpty {
                await requestProducts()
            }
            await updateSubscriptionStatus()
        }
    }

    func requestProducts() async {
        // Only fetch products for logged-in users (paywall is shown post-login/trial anyway).
        // This avoids StoreKit/network work during app launch before auth, which can feel laggy.
        guard AuthService.shared.readToken() != nil else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [monthlyID, yearlyID])
            print("✅ Loaded \(products.count) products")
            if !products.isEmpty {
                errorMessage = nil
            }
            
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
        defer { 
            isLoading = false 
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update subscription status first
                await updateSubscriptionStatus()
                
                // Verify with backend (non-blocking - don't wait if it fails)
                Task {
                    await verifyReceiptWithBackend(transaction: transaction)
                }
                
                // Finish transaction immediately to prevent hanging
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
        } catch {
            // Ensure loading is cleared even if error occurs
            isLoading = false
            throw error
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
                            // If status.state == .subscribed, the subscription is ACTIVE (even if in trial period)
                            // The trial period is just a promotional period - the subscription itself is active
                            highestStatus = .active
                            highestProduct = product
                            highestExpiration = expiration

                            // Check if in trial period for informational purposes (but status is still .active)
                            // Look at transaction purchase date vs current date
                            // If purchase was within last 3 days and has intro offer, likely in trial
                            let purchaseDate = transaction.purchaseDate
                            
                            if purchaseDate <= Date() {
                                let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
                                // Check if there's an introductory offer and we're still within trial period
                                if daysSincePurchase < 3 && product.subscription?.introductoryOffer != nil {
                                    isInTrial = true
                                    // Note: Status remains .active because subscription is active (just in trial period)
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
        // Active subscription includes both .active and .trial statuses
        // But we prioritize .active for paid subscriptions
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
                // Don’t do StoreKit/backend work if user is not logged in.
                // This significantly reduces background work and improves perceived performance.
                if AuthService.shared.readToken() != nil {
                    // Sync with backend to keep subscription status up to date
                    await syncSubscriptionStatusWithBackend()
                    // Only check StoreKit status locally (no backend call)
                    await updateSubscriptionStatus()
                    // Recompute access gating locally (no backend calls)
                    await checkTrialAndSubscriptionStatus()
                }
                // Check backend subscription status every 5 minutes
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
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
            req.timeoutInterval = 10.0 // Reduced timeout to 10 seconds to prevent hanging

            guard let token = AuthService.shared.readToken()?.accessToken else {
                print("❌ No auth token found for subscription verification")
                return
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            req.httpBody = try JSONEncoder().encode(body)
            
            // Make request with timeout (already set to 10 seconds in req.timeoutInterval)
            // Catch timeout errors to prevent hanging
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
            
            // Decode response to get subscription status and calculated endDate
            struct VerifyResponse: Codable {
                let success: Bool
                let subscriptionStatus: String?
                let plan: String?
                let expiresDate: String? // StoreKit's expiresDate (Sandbox-accelerated)
                let endDate: String? // Backend's calculated endDate (proper 1 month/year renewal)
                let subscriptionDaysRemaining: Int?
            }
            
            if let verifyResponse = try? JSONDecoder().decode(VerifyResponse.self, from: data) {
                print("📊 Subscription status: \(verifyResponse.subscriptionStatus ?? "unknown")")
                
                // Parse and store backend's calculated endDate (proper renewal date, not Sandbox-accelerated)
                // Prefer endDate (calculated) over expiresDate (StoreKit/Sandbox)
                let dateStr = verifyResponse.endDate ?? verifyResponse.expiresDate
                if let dateStr = dateStr {
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let endDate = isoFormatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr) {
                        await MainActor.run {
                            backendCalculatedEndDate = endDate
                            print("📅 Backend calculated renewal date: \(endDate)")
                        }
                    }
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = json["subscriptionStatus"] as? String {
                print("📊 Subscription status: \(status)")
            }

        } catch {
            print("❌ Backend verification error: \(error.localizedDescription)")
        }
    }

    func checkSubscriptionStatus() async {
        // Check cache first to avoid excessive backend calls
        if let cached = statusCheckCache,
           let lastCheck = lastStatusCheck,
           Date().timeIntervalSince(lastCheck) < statusCacheTimeout {
            // Use cached status if available and fresh
            await MainActor.run {
                subscriptionStatus = cached.status
                hasActiveSubscription = cached.hasActive
            }
            return
        }
        
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
            
            // Handle rate limiting (429) with retry
            if httpResponse.statusCode == 429 {
                print("⚠️ Rate limited (429) - will retry later")
                // Don't update cache on rate limit, will retry next time
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Subscription status check failed with status \(httpResponse.statusCode): \(errorMessage)")
                return
            }

            struct Response: Codable {
                let hasActiveSubscription: Bool
                let isPremiumActive: Bool?
                let isInTrial: Bool?
                let isCancelled: Bool?
                let isExpired: Bool?
                let subscription: SubscriptionInfo?
                let trialDaysRemaining: Int?
                let subscriptionDaysRemaining: Int?
                let daysRemaining: Int?
                let statusDetails: StatusDetails?
            }
            
            struct SubscriptionInfo: Codable {
                let status: String
                let plan: String?
                let startDate: String?
                let endDate: String?
                let trialEndDate: String?
                let appleTransactionId: String?
                let appleOriginalTransactionId: String?
            }
            
            struct StatusDetails: Codable {
                let isPremium: Bool?
                let isTrial: Bool?
                let isCancelled: Bool?
                let isExpired: Bool?
                let canAccessPremium: Bool?
            }

            let backendResponse = try JSONDecoder().decode(Response.self, from: data)
            
            // Determine subscription status from backend response
            let newStatus: SubscriptionStatus
            if let isCancelled = backendResponse.isCancelled, isCancelled {
                newStatus = .cancelled
            } else if let isExpired = backendResponse.isExpired, isExpired {
                newStatus = .expired
            } else if let isInTrial = backendResponse.isInTrial, isInTrial {
                newStatus = .trial
            } else if let isPremiumActive = backendResponse.isPremiumActive, isPremiumActive {
                newStatus = .active
            } else if backendResponse.hasActiveSubscription {
                newStatus = .active
            } else {
                newStatus = .free
            }
            
            // Update trial days remaining from backend.
            //
            // Bugfix:
            // Backend can return `trialDaysRemaining: 0` (non-nil) for paid subscribers while also
            // returning `daysRemaining: X` or `subscriptionDaysRemaining: X`. Using `??` would treat
            // 0 as a "real" trial value and overwrite local/real trial info with 0.
            //
            // Only write `trialDaysRemaining` when the backend says the user is actually in trial.
            let backendTrialDays: Int? = {
                if backendResponse.isInTrial == true {
                    return backendResponse.trialDaysRemaining ?? backendResponse.daysRemaining
                }
                return nil
            }()
            
            // Parse backend's endDate (calculated properly, not Sandbox-accelerated)
            var backendEndDate: Date? = nil
            if let endDateStr = backendResponse.subscription?.endDate {
                // MongoDB/Mongoose serializes dates as ISO8601 strings
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                backendEndDate = isoFormatter.date(from: endDateStr) ?? ISO8601DateFormatter().date(from: endDateStr)
            }
            
            await MainActor.run {
                hasActiveSubscription = backendResponse.hasActiveSubscription
                subscriptionStatus = newStatus
                
                // Update trial days remaining only if backend indicates trial
                if let days = backendTrialDays {
                    trialDaysRemaining = days
                }
                
                // Store backend's calculated endDate separately (proper renewal date, not Sandbox-accelerated)
                // This will be used in ProfileView to show the correct renewal date
                if let backendEndDate = backendEndDate, (newStatus == .active || newStatus == .trial) {
                    backendCalculatedEndDate = backendEndDate
                    
                    // Also update currentSubscription with backend's date (but StoreKit's updateSubscriptionStatus might overwrite it)
                    let productId = currentSubscription?.productId ?? (backendResponse.subscription?.plan == "yearly" ? yearlyID : monthlyID)
                    let isInTrial = currentSubscription?.isInTrialPeriod ?? (newStatus == .trial)
                    
                    currentSubscription = CurrentSubscriptionInfo(
                        productId: productId,
                        expirationDate: backendEndDate,
                        isInTrialPeriod: isInTrial,
                        renewalInfo: currentSubscription?.renewalInfo
                    )
                }
                
                // Update cache
                statusCheckCache = (status: newStatus, hasActive: backendResponse.hasActiveSubscription)
                lastStatusCheck = Date()
            }
            
            print("✅ Subscription status from backend:")
            print("   - Status: \(newStatus)")
            print("   - Has Active: \(backendResponse.hasActiveSubscription)")
            print("   - Is Premium: \(backendResponse.isPremiumActive ?? false)")
            print("   - Is Cancelled: \(backendResponse.isCancelled ?? false)")
            if let days = backendTrialDays {
                print("   - Trial Days Remaining: \(days)")
            }
            if let subDays = backendResponse.subscriptionDaysRemaining {
                print("   - Subscription Days Remaining: \(subDays)")
            }

        } catch {
            // Don't log cancellation errors as they're expected
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("❌ Subscription status fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Backend Sync
    private func syncSubscriptionStatusWithBackend() async {
        do {
            guard let token = AuthService.shared.readToken()?.accessToken else {
                return
            }
            
            let url = NetworkManager.shared.baseURL.appendingPathComponent("subscriptions/sync")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 10.0
            
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            struct SyncResponse: Codable {
                let success: Bool
                let subscription: SubscriptionInfo?
                let statusChanged: Bool
            }
            
            struct SubscriptionInfo: Codable {
                let status: String
                let plan: String?
                let endDate: String?
                let trialEndDate: String?
            }
            
            let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
            
            if syncResponse.statusChanged {
                print("🔄 Subscription status changed on backend - refreshing...")
                // Refresh subscription status after sync
                await checkSubscriptionStatus()
            }
        } catch {
            // Silently fail - this is a background sync
            print("⚠️ Background subscription sync failed: \(error.localizedDescription)")
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
