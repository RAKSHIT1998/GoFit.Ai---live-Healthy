//
//  FeatureGateService.swift
//  GoFit.Ai - live Healthy
//
//  Created for feature gating between free and premium users
//

import Foundation

@MainActor
class FeatureGateService: ObservableObject {
    static let shared = FeatureGateService()
    
    @Published var isPremiumUser: Bool = false
    
    // MARK: - Feature Limits
    // Free users get limited features
    let freeUserRecommendationsLimit = 3 // Limited to 3 recommendations per day
    let premiumUserRecommendationsLimit = 15 // Premium gets 10+ recommendations
    
    // MARK: - PurchaseManager Reference
    private var purchaseManager: PurchaseManager?
    
    private init() {}
    
    func setPurchaseManager(_ manager: PurchaseManager) {
        self.purchaseManager = manager
        updatePremiumStatus()
    }
    
    func updatePremiumStatus() {
        guard let manager = purchaseManager else { return }
        isPremiumUser = manager.isPremiumActive
        print("💎 Premium status updated: \(isPremiumUser ? "Premium" : "Free")")
    }
    
    // MARK: - Feature Access Checks
    
    /// Check if user can access unlimited meal scans
    var canAccessUnlimitedScans: Bool {
        return isPremiumUser
    }
    
    /// Get the maximum number of recommendations for current user
    var maxRecommendations: Int {
        return isPremiumUser ? premiumUserRecommendationsLimit : freeUserRecommendationsLimit
    }
    
    /// Check if user has ad-free experience
    var isAdFree: Bool {
        return isPremiumUser
    }
    
    /// Check if user can access advanced analytics
    var canAccessAdvancedAnalytics: Bool {
        return isPremiumUser
    }
    
    /// Check if user can access full HealthKit integration
    var canAccessFullHealthKit: Bool {
        return isPremiumUser
    }
    
    /// Check if user can create custom workout plans
    var canCreateCustomWorkouts: Bool {
        return isPremiumUser
    }
    
    // MARK: - Helper Methods
    
    /// Get a user-friendly message about premium features
    func getPremiumFeatureMessage(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedScans:
            return "Upgrade to Premium for unlimited meal scans"
        case .moreRecommendations:
            return "Get 10+ daily recommendations with Premium"
        case .adFree:
            return "Remove all ads with Premium subscription"
        case .advancedAnalytics:
            return "Unlock advanced insights with Premium"
        case .fullHealthKit:
            return "Get full Apple Watch sync with Premium"
        case .customWorkouts:
            return "Create custom workout plans with Premium"
        }
    }
    
    enum PremiumFeature {
        case unlimitedScans
        case moreRecommendations
        case adFree
        case advancedAnalytics
        case fullHealthKit
        case customWorkouts
    }
}
