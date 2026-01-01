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
            // Debug: Log current state
            print("📱 RootView appeared - didFinishOnboarding: \(auth.didFinishOnboarding), isLoggedIn: \(auth.isLoggedIn)")
        }
        .onAppear {
            purchases.loadProducts()
            
            // Check subscription status on app launch
            Task {
                await purchases.updateSubscriptionStatus()
                await purchases.checkSubscriptionStatus()
            }
            
            // Sync HealthKit if authorized and logged in
            if auth.isLoggedIn {
                // Refresh authorization status first
                healthKit.checkAuthorizationStatus()
                
                if healthKit.isAuthorized {
                    // Start periodic sync when user is logged in
                    healthKit.startPeriodicSync()
                    
                    Task {
                        do {
                            try await healthKit.syncToBackend()
                            print("✅ HealthKit synced on app launch")
                        } catch {
                            print("⚠️ HealthKit sync on launch failed: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // Stop periodic sync when user is not logged in
                healthKit.stopPeriodicSync()
            }
        }
        .onChange(of: auth.isLoggedIn) { oldValue, newValue in
            if newValue {
                // When user logs in, sync HealthKit and check subscription
                Task {
                    // Check subscription status
                    await purchases.updateSubscriptionStatus()
                    await purchases.checkSubscriptionStatus()
                    
                    // Refresh authorization status and sync HealthKit if authorized
                    healthKit.checkAuthorizationStatus()
                    
                    if healthKit.isAuthorized {
                        // Start periodic sync when user logs in
                        healthKit.startPeriodicSync()
                        
                        do {
                            try await healthKit.syncToBackend()
                            print("✅ HealthKit synced after login")
                        } catch {
                            print("⚠️ HealthKit sync after login failed: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // When user logs out, stop periodic sync
                healthKit.stopPeriodicSync()
                print("🛑 Stopped HealthKit periodic sync - user logged out")
            }
        }
    }
}
