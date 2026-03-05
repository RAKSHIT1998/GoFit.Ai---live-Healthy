//
//  AdManager.swift
//  GoFit.Ai - live Healthy
//
//  Created by AdMob Integration
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    // MARK: - Published State
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var adLoadError: String?
    
    // MARK: - Ad Unit IDs
    // Production Ad Unit IDs from AdMob console
    private let appOpenAdUnitID = "ca-app-pub-5156494121502262/7631513040" // Production App Open Ad
    private let interstitialAdUnitID = "ca-app-pub-5156494121502262/7631513040" // Production Interstitial Ad
    
    // MARK: - Ad Objects
    private var appOpenAd: AppOpenAd?
    private var interstitialAd: InterstitialAd?
    
    // MARK: - Ad Display Tracking
    private var lastAdShownTime: Date?
    private let minimumAdInterval: TimeInterval = 0 // Show every time (as per requirement)
    private var isLoadingAd = false
    private var shouldShowWhenLoaded = false
    
    // MARK: - Subscription State
    var hasActiveSubscription: Bool {
        // Check if user has active subscription (no ads for subscribers)
        // This will be set by PurchaseManager
        return PurchaseManager.shared?.isPremiumActive ?? false
    }
    
    // Reference to PurchaseManager
    private weak var purchaseManager: PurchaseManager?
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    // MARK: - Setup
    func initialize() {
        #if targetEnvironment(simulator)
        print("ℹ️ Running on Simulator - AdMob presentation disabled")
        return
        #endif

        // Production mode - no test device configuration needed
        
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start { [weak self] (status: InitializationStatus) in
            print("✅ AdMob SDK initialized successfully")
            print("📊 Adapter statuses:")
            for (adapterName, status) in status.adapterStatusesByClassName {
                print("  - \(adapterName): \(status.state.rawValue)")
            }
            
            // Pre-load app open ad
            Task { @MainActor in
                await self?.loadAppOpenAd()
            }
        }
    }
    
    func setPurchaseManager(_ manager: PurchaseManager) {
        self.purchaseManager = manager
    }
    
    // MARK: - App Open Ad
    func loadAppOpenAd() async {
        #if targetEnvironment(simulator)
        return
        #endif

        guard !hasActiveSubscription else {
            print("ℹ️ User has subscription - skipping ad load")
            return
        }
        
        guard !isLoadingAd else {
            print("⚠️ Already loading an ad")
            return
        }
        
        isLoadingAd = true
        adLoadError = nil
        
        do {
            appOpenAd = try await AppOpenAd.load(
                with: appOpenAdUnitID,
                request: Request()
            )
            appOpenAd?.fullScreenContentDelegate = self
            isAdLoaded = true
            print("✅ App open ad loaded successfully")
            if shouldShowWhenLoaded && UIApplication.shared.applicationState == .active {
                shouldShowWhenLoaded = false
                showAppOpenAd()
            }
        } catch {
            print("❌ Failed to load app open ad: \(error.localizedDescription)")
            adLoadError = error.localizedDescription
            isAdLoaded = false
        }
        
        isLoadingAd = false
    }
    
    func showAppOpenAd() {
        #if targetEnvironment(simulator)
        print("ℹ️ Simulator run - skipping app open ad presentation")
        return
        #endif

        // Don't show ads for subscribers
        guard !hasActiveSubscription else {
            print("ℹ️ User has subscription - skipping ad display")
            return
        }
        
        // Check if enough time has passed since last ad
        if let lastShown = lastAdShownTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastShown)
            if timeSinceLastAd < minimumAdInterval {
                print("⏱️ Not enough time passed since last ad (\(timeSinceLastAd)s)")
                return
            }
        }
        
        guard let ad = appOpenAd else {
            print("⚠️ App open ad not ready, will retry when loaded")
            // Try to load ad and show as soon as it becomes ready
            shouldShowWhenLoaded = true
            Task {
                print("🔄 Attempting to load app open ad...")
                await loadAppOpenAd()
            }
            return
        }
        
        guard let rootViewController = topViewController() else {
            print("❌ No root view controller available - cannot present ad")
            return
        }
        
        isShowingAd = true
        ad.present(from: rootViewController)
        lastAdShownTime = Date()
        print("✅ App open ad is now presenting")
        
        // Pre-load next ad for future display
        Task {
            await loadAppOpenAd()
        }
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
    
    // MARK: - Interstitial Ad
    func loadInterstitialAd() async {
        guard !hasActiveSubscription else {
            print("ℹ️ User has subscription - skipping interstitial ad load")
            return
        }
        
        guard !isLoadingAd else {
            print("⚠️ Already loading an ad")
            return
        }
        
        isLoadingAd = true
        
        do {
            interstitialAd = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: Request()
            )
            interstitialAd?.fullScreenContentDelegate = self
            print("✅ Interstitial ad loaded successfully")
        } catch {
            print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
        }
        
        isLoadingAd = false
    }
    
    func showInterstitialAd() {
        guard !hasActiveSubscription else {
            print("ℹ️ User has subscription - skipping interstitial ad display")
            return
        }
        
        guard let ad = interstitialAd else {
            print("⚠️ Interstitial ad not ready")
            Task {
                await loadInterstitialAd()
            }
            return
        }
        
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            print("❌ No root view controller found")
            return
        }
        
        ad.present(from: rootViewController)
        print("📺 Showing interstitial ad")
    }
    
    // MARK: - Helper Methods
    func shouldShowAd() -> Bool {
        // Check if user has subscription
        if hasActiveSubscription {
            return false
        }
        
        // Check minimum interval
        if let lastShown = lastAdShownTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastShown)
            return timeSinceLastAd >= minimumAdInterval
        }
        
        return true
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("❌ Ad failed to present: \(error.localizedDescription)")
            self.isShowingAd = false
            self.adLoadError = error.localizedDescription
            
            // Load a new ad
            if ad is AppOpenAd {
                print("🔄 Reloading app open ad...")
                await self.loadAppOpenAd()
            } else if ad is InterstitialAd {
                print("🔄 Reloading interstitial ad...")
                await self.loadInterstitialAd()
            }
        }
    }
    
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("📺 Ad will present")
            self.isShowingAd = true
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("✅ Ad dismissed by user")
            self.isShowingAd = false
            
            // Load a new ad for next time
            if ad is AppOpenAd {
                print("🔄 Preloading next app open ad...")
                await self.loadAppOpenAd()
            } else if ad is InterstitialAd {
                print("🔄 Preloading next interstitial ad...")
                await self.loadInterstitialAd()
            }
        }
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
