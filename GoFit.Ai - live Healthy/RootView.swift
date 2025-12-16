import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var purchases = PurchaseManager()
    
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
        }
    }
}
