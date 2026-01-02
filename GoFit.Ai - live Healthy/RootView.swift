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
            } else if purchases.requiresSubscription {
                // Trial expired and no subscription - show paywall
                PaywallView()
                    .environmentObject(purchases)
                    .interactiveDismissDisabled() // Prevent dismissing paywall
            } else {
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(purchases)
            }
        }
        .onAppear {
            purchases.loadProducts()
            
            // Check subscription and trial status on app launch
            Task {
                await purchases.updateSubscriptionStatus()
                await purchases.checkSubscriptionStatus()
                await purchases.checkTrialAndSubscriptionStatus()
            }
            
            // Check HealthKit authorization and sync if logged in
            if auth.isLoggedIn {
                healthKit.checkAuthorizationStatus()
                if healthKit.isAuthorized {
                    healthKit.startPeriodicSync()
                    Task {
                        await healthKit.readTodayData()
                        try? await healthKit.syncToBackend()
                    }
                }
            }
        }
        .onChange(of: auth.isLoggedIn) { oldValue, newValue in
            if newValue {
                // When user logs in, check subscription and HealthKit
                Task {
                    await purchases.updateSubscriptionStatus()
                    await purchases.checkSubscriptionStatus()
                    await purchases.checkTrialAndSubscriptionStatus()
                    
                    healthKit.checkAuthorizationStatus()
                    if healthKit.isAuthorized {
                        healthKit.startPeriodicSync()
                        await healthKit.readTodayData()
                        try? await healthKit.syncToBackend()
                    }
                }
            } else {
                // When user logs out, stop HealthKit sync
                healthKit.stopPeriodicSync()
            }
        }
        .onChange(of: purchases.hasActiveSubscription) { oldValue, newValue in
            // When subscription becomes active, recheck trial status
            if newValue {
                Task {
                    await purchases.checkTrialAndSubscriptionStatus()
                }
            }
        }
        .onChange(of: purchases.subscriptionStatus) { oldValue, newValue in
            // When subscription status changes, recheck trial status
            Task {
                await purchases.checkTrialAndSubscriptionStatus()
            }
        }
    }
}
