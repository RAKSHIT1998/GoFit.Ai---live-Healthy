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

    // MARK: - Init
    init() {
        updateListenerTask = listenForTransactions()
        startStatusMonitoring()
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

    // MARK: - Subscription Status (FIXED)
    func updateSubscriptionStatus() async {

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

                            if product.subscription?.introductoryOffer != nil,
                               expiration > Date() {
                                highestStatus = .trial
                                isInTrial = true
                            }
                        }
                    }

                case .inGracePeriod:
                    highestStatus = .active

                case .inBillingRetryPeriod:
                    highestStatus = .active

                case .expired:
                    highestStatus = .expired

                case .revoked:
                    highestStatus = .cancelled

                default:
                    highestStatus = .unknown
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
                try? await Task.sleep(nanoseconds: 60_000_000_000)
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
