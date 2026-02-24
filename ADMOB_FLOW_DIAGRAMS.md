# AdMob Implementation Flow Diagram

## 🎬 User Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     NEW USER JOURNEY                             │
└─────────────────────────────────────────────────────────────────┘

1. App Launch
   │
   ├─→ Onboarding Steps (11 screens)
   │   ├─ Welcome
   │   ├─ Name
   │   ├─ Weight/Height
   │   ├─ Goal
   │   ├─ Target Weight
   │   ├─ Activity Level
   │   ├─ Dietary Preferences
   │   ├─ Allergies
   │   ├─ Workout Preferences
   │   ├─ Cuisines
   │   └─ Lifestyle
   │
   ├─→ Permissions Screen
   │   └─ HealthKit & Notifications
   │
   ├─→ Signup Screen
   │   └─ Create Account
   │
   ├─→ 🆕 SUBSCRIPTION SCREEN
   │   ├─ Show Premium Features
   │   ├─ 3-Day Free Trial Offer
   │   │
   │   └─ User Choice:
   │       ├─→ [Start Free Trial] → Premium User
   │       └─→ [Skip & Use With Ads] → Free User
   │
   └─→ Main App


┌─────────────────────────────────────────────────────────────────┐
│                  RETURNING FREE USER JOURNEY                     │
└─────────────────────────────────────────────────────────────────┘

1. App Launch
   │
   ├─→ 📺 FULL-SCREEN APP OPEN AD
   │   └─ User watches/closes ad
   │
   ├─→ Main App
   │   ├─ Dashboard (3 recommendations) ⚠️ LIMITED
   │   ├─ Meal Scanner (unlimited)
   │   ├─ Workouts (3 per day) ⚠️ LIMITED
   │   └─ Settings
   │
   └─→ Can upgrade to Premium anytime


┌─────────────────────────────────────────────────────────────────┐
│                RETURNING PREMIUM USER JOURNEY                    │
└─────────────────────────────────────────────────────────────────┘

1. App Launch
   │
   ├─→ ✨ NO ADS (Direct to app)
   │
   └─→ Main App
       ├─ Dashboard (15 recommendations) ✅ PREMIUM
       ├─ Meal Scanner (unlimited)
       ├─ Workouts (15 per day) ✅ PREMIUM
       ├─ Advanced Analytics ✅ PREMIUM
       └─ Settings


┌─────────────────────────────────────────────────────────────────┐
│                      TECHNICAL FLOW                              │
└─────────────────────────────────────────────────────────────────┘

App Launch
   │
   ├─→ GofitAIApp.swift
   │   └─ Initialize AdManager
   │
   ├─→ RootView.swift
   │   ├─ Check Login Status
   │   ├─ Connect AdManager ↔ PurchaseManager
   │   │
   │   └─ If Logged In:
   │       ├─ Check Subscription Status
   │       │
   │       └─ If NOT Subscribed:
   │           └─ AdManager.showAppOpenAd()
   │
   └─→ Main App Flow


┌─────────────────────────────────────────────────────────────────┐
│                  AD DISPLAY LOGIC                                │
└─────────────────────────────────────────────────────────────────┘

AdManager.showAppOpenAd()
   │
   ├─ Check: Is user subscribed?
   │  ├─ YES → Skip ad display
   │  └─ NO → Continue
   │
   ├─ Check: Is ad loaded?
   │  ├─ NO → Load ad for next time
   │  └─ YES → Continue
   │
   ├─ Display full-screen ad
   │
   └─ On Ad Close:
       ├─ User continues to app
       └─ Preload next ad


┌─────────────────────────────────────────────────────────────────┐
│               FEATURE GATING LOGIC                               │
└─────────────────────────────────────────────────────────────────┘

FeatureGateService.maxRecommendations
   │
   ├─ Check PurchaseManager.hasActiveSubscription
   │
   ├─ If Subscribed:
   │  └─ Return 15 recommendations
   │
   └─ If Free:
      └─ Return 3 recommendations


┌─────────────────────────────────────────────────────────────────┐
│            SUBSCRIPTION STATE MANAGEMENT                         │
└─────────────────────────────────────────────────────────────────┘

PurchaseManager
   │
   ├─ Monitor StoreKit transactions
   ├─ Check subscription status
   ├─ Update hasActiveSubscription
   │
   └─ Notify:
       ├─→ AdManager (show/hide ads)
       ├─→ FeatureGateService (adjust limits)
       └─→ UI Components (update displays)


┌─────────────────────────────────────────────────────────────────┐
│                FILE INTERACTION DIAGRAM                          │
└─────────────────────────────────────────────────────────────────┘

GofitAIApp.swift
   │
   ├─→ Creates AdManager @StateObject
   └─→ Creates WebSocketService @StateObject
       │
       └─→ RootView.swift
           │
           ├─→ Creates PurchaseManager @StateObject
           ├─→ Receives AdManager @EnvironmentObject
           │   │
           │   ├─→ Connects: AdManager ↔ PurchaseManager
           │   └─→ Shows ads on launch (if free user)
           │
           └─→ Routes to:
               │
               ├─→ OnboardingScreens.swift
               │   │
               │   └─→ OnboardingSubscriptionView.swift
               │       ├─ Shows subscription options
               │       ├─ "Skip and use with ads" button
               │       └─ Completes onboarding
               │
               └─→ MainTabView
                   │
                   └─→ WorkoutSuggestionsView.swift
                       │
                       └─→ FeatureGateService
                           ├─ Limits recommendations
                           └─ Shows upgrade prompt


┌─────────────────────────────────────────────────────────────────┐
│                  KEY SERVICES OVERVIEW                           │
└─────────────────────────────────────────────────────────────────┘

1. AdManager (Services/AdManager.swift)
   ├─ Initializes Google Mobile Ads SDK
   ├─ Loads app open ads
   ├─ Loads interstitial ads
   ├─ Checks subscription before showing
   └─ Handles ad lifecycle events

2. FeatureGateService (Services/FeatureGateService.swift)
   ├─ Tracks premium status
   ├─ Defines feature limits
   ├─ Controls recommendation count
   └─ Provides upgrade messaging

3. PurchaseManager (Features/Paywall/PurchaseManager.swift)
   ├─ Manages StoreKit subscriptions
   ├─ Tracks subscription status
   ├─ Handles purchase flow
   └─ Notifies other services of changes


┌─────────────────────────────────────────────────────────────────┐
│              SUBSCRIPTION SCREEN COMPONENTS                      │
└─────────────────────────────────────────────────────────────────┘

OnboardingSubscriptionView
   │
   ├─→ Header
   │   ├─ Crown icon
   │   └─ "3-Day Free Trial" badge
   │
   ├─→ Premium Features List
   │   ├─ ♾️ Unlimited Scans
   │   ├─ ✨ More Recommendations (10+)
   │   ├─ 📊 Advanced Analytics
   │   ├─ 🚫 Ad-Free Experience
   │   └─ ⌚ Apple Watch Sync
   │
   ├─→ Plan Selection
   │   ├─ Yearly (BEST VALUE badge)
   │   └─ Monthly
   │
   ├─→ Action Buttons
   │   ├─ [Start Free Trial] (Primary)
   │   └─ [Skip and use with ads] (Secondary)
   │
   └─→ Terms & Privacy Links


┌─────────────────────────────────────────────────────────────────┐
│                   AD TYPES IMPLEMENTED                           │
└─────────────────────────────────────────────────────────────────┘

1. App Open Ads ✅
   ├─ Format: Full-screen
   ├─ Timing: Every app launch
   ├─ Target: Non-subscribers only
   └─ Status: ACTIVE

2. Interstitial Ads ✅
   ├─ Format: Full-screen
   ├─ Timing: On-demand (future use)
   ├─ Target: Non-subscribers only
   └─ Status: CODE READY (not triggered yet)

3. Future Possibilities:
   ├─ Banner Ads (bottom of screen)
   ├─ Native Ads (in content feed)
   └─ Rewarded Video Ads (extra features)
```

## 📊 Feature Comparison Matrix

```
┌──────────────────────┬─────────────────┬──────────────────┐
│ Feature              │ Free (with Ads) │ Premium (No Ads) │
├──────────────────────┼─────────────────┼──────────────────┤
│ Daily Recommend.     │        3        │        15        │
│ Meal Scans           │    Unlimited    │    Unlimited     │
│ Full-Screen Ads      │       Yes       │        No        │
│ Apple Watch Sync     │      Basic      │       Full       │
│ Advanced Analytics   │       No        │       Yes        │
│ Custom Workouts      │       No        │       Yes        │
│ Price                │      $0/mo      │   $9.99/mo or    │
│                      │                 │   $89.99/yr      │
└──────────────────────┴─────────────────┴──────────────────┘
```

## 🎯 Revenue Model

```
User Journey → Revenue Impact

Free User Path:
├─ Downloads app: $0
├─ Completes onboarding: $0
├─ Skips subscription: $0
├─ Uses with ads: Ad Revenue 💰
└─ May upgrade later: Subscription Revenue 💰💰💰

Premium User Path:
├─ Downloads app: $0
├─ Completes onboarding: $0
├─ Starts free trial: $0
├─ Trial ends: Subscription Revenue 💰💰💰
└─ Renews subscription: Recurring Revenue 💰💰💰
```

---

**Implementation Status**: ✅ COMPLETE  
**Testing Status**: ⚠️ REQUIRES ADMOB SETUP  
**Production Ready**: ⚠️ UPDATE AD UNIT IDS FIRST
