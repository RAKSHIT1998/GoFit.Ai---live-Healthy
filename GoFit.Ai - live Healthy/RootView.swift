import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var healthKit = HealthKitService.shared
    
    @State private var hasCheckedSubscriptionAfterLogin = false
    
    var body: some View {
        Group {
            if !auth.didFinishOnboarding {
                OnboardingScreens()
                    .environmentObject(auth)
                    .environmentObject(purchases)
            } else if !auth.isLoggedIn {
                AuthView()
                    .environmentObject(auth)
                    .environmentObject(purchases)
            } else {
                // User is logged in - show main app or blocking paywall
                // Only show blocking paywall if:
                // 1. User is logged in (not a new signup showing onboarding paywall)
                // 2. Subscription is required (trial expired and no subscription)
                // 3. We've already checked subscription status (avoid showing immediately after login)
                if hasCheckedSubscriptionAfterLogin && purchases.requiresSubscription {
                    // Blocking paywall for existing users whose trial expired
                    PaywallView()
                        .environmentObject(purchases)
                        .interactiveDismissDisabled()
                } else {
                    MainTabView()
                        .environmentObject(auth)
                        .environmentObject(purchases)
                }
            }
        }
        .onAppear {
            purchases.loadProducts()
            
            // Check subscription and trial status on app launch
            if auth.isLoggedIn {
                Task {
                    await purchases.updateSubscriptionStatus()
                    await purchases.checkSubscriptionStatus()
                    await purchases.checkTrialAndSubscriptionStatus()
                    await MainActor.run {
                        hasCheckedSubscriptionAfterLogin = true
                    }
                }
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
                // When user logs in/signs up, initialize trial and check subscription
                // Reset the flag to prevent premature paywall display
                hasCheckedSubscriptionAfterLogin = false
                
                Task {
                    // Give paywall time to show after signup if needed
                    // Only check subscription status after a delay
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    await purchases.updateSubscriptionStatus()
                    await purchases.checkSubscriptionStatus()
                    await purchases.checkTrialAndSubscriptionStatus()
                    
                    await MainActor.run {
                        hasCheckedSubscriptionAfterLogin = true
                    }
                    
                    healthKit.checkAuthorizationStatus()
                    if healthKit.isAuthorized {
                        healthKit.startPeriodicSync()
                        await healthKit.readTodayData()
                        try? await healthKit.syncToBackend()
                    }
                }
            } else {
                // When user logs out, stop HealthKit sync and reset flag
                hasCheckedSubscriptionAfterLogin = false
                healthKit.stopPeriodicSync()
            }
        }
        .onChange(of: purchases.subscriptionStatus) { oldValue, newValue in
            // Bugfix: When subscription status changes (e.g., after purchase), immediately
            // update requiresSubscription/showPaywall to dismiss blocking paywall.
            // This is safe because checkTrialAndSubscriptionStatus() no longer calls
            // updateSubscriptionStatus()/checkSubscriptionStatus(), so no infinite loop.
            if auth.isLoggedIn && oldValue != newValue {
                Task {
                    await purchases.checkTrialAndSubscriptionStatus()
                }
            }
        }
    }
}
