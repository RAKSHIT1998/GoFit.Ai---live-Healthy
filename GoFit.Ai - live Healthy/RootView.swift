import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var healthKit = HealthKitService.shared
    
    var body: some View {
        Group {
            if !auth.didFinishOnboarding {
                OnboardingScreens()
                    .environmentObject(auth)
            } else if !auth.isLoggedIn {
                AuthView()
                    .environmentObject(auth)
                    .environmentObject(purchases)
            } else {
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(purchases)
            }
        }
        .onAppear {
            purchases.loadProducts()
            
            // Check subscription status on app launch
            Task {
                await purchases.updateSubscriptionStatus()
                await purchases.checkSubscriptionStatus()
            }
            
            // Sync HealthKit if authorized and logged in
            if auth.isLoggedIn && healthKit.isAuthorized {
                Task {
                    do {
                        try await healthKit.syncToBackend()
                        print("✅ HealthKit synced on app launch")
                    } catch {
                        print("⚠️ HealthKit sync on launch failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onChange(of: auth.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                // When user logs in, sync HealthKit and check subscription
                Task {
                    // Check subscription status
                    await purchases.updateSubscriptionStatus()
                    await purchases.checkSubscriptionStatus()
                    
                    // Sync HealthKit if authorized
                    if healthKit.isAuthorized {
                        do {
                            try await healthKit.syncToBackend()
                            print("✅ HealthKit synced after login")
                        } catch {
                            print("⚠️ HealthKit sync after login failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}
