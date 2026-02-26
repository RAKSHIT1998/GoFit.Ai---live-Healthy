# 🐛 AdMob Debugging Guide

## ✅ Fixed Issues

### 1. **Better Error Logging**
- AdManager now logs adapter status details during initialization
- Shows detailed error messages when ads fail to load/present
- Tracks ad loading state with clear messages

### 2. **Test Ad Configuration**
- Test ad request configuration added to initialize()
- Keywords set to "test" for development
- Comment provided for adding test device ID

### 3. **Ad Preloading**
- App open ad preloaded immediately after SDK initialization
- Next ad preloaded automatically after each dismissal
- Reduces display latency

## 🔍 Debugging Steps

### Step 1: Check Console Logs
After app launch, look for:
```
✅ AdMob SDK initialized successfully
📊 Adapter statuses:
  - com.google.ads.adapter.GoogleAdapter: Initialized (3)
```

### Step 2: Verify Ad Loading
Look for:
```
✅ App open ad loaded successfully
```
OR
```
❌ Failed to load app open ad: [error message]
```

### Step 3: Check Subscription Status
Free users should show:
```
✅ App open ad is now presenting
```

Premium users should show:
```
ℹ️ User has subscription - skipping ad load
ℹ️ User has subscription - skipping ad display
```

### Step 4: Check Ad Presentation
Look for:
```
📺 Ad will present
✅ Ad dismissed by user
🔄 Preloading next app open ad...
```

## 🧪 Testing Test Ads

### Using Google Test Device IDs

1. **Get your device ID** from first ad request:
   - Look in Xcode console when app tries to load ad
   - Google provides test device ID in error messages

2. **Add to AdManager.swift**:
   ```swift
   #if DEBUG
   var requestConfiguration = GADMobileAds.sharedInstance().requestConfiguration
   requestConfiguration.testDeviceIdentifiers = [
       "YOUR_DEVICE_ID_HERE",  // iPhone
       "YOUR_IPAD_DEVICE_ID"   // iPad
   ]
   GADMobileAds.sharedInstance().requestConfiguration = requestConfiguration
   #endif
   ```

3. **Test ad unit IDs** (already configured):
   - App Open: `ca-app-pub-3940256099942544/5575463023`
   - Interstitial: `ca-app-pub-3940256099942544/4411468910`

## ❌ Common Issues & Fixes

### Issue: "Module 'GoogleMobileAds' not found"
**Fix**: Install SDK via Package Manager:
```
Xcode → File → Add Package Dependencies
URL: https://github.com/googleads/swift-package-manager-google-mobile-ads.git
Version: 11.0.0+
```

### Issue: Ads Not Showing
**Checklist**:
- [ ] Is internet connected?
- [ ] Is user logged in and NOT premium?
- [ ] Did app initialize AdManager? (check GofitAIApp.swift)
- [ ] Is there a root view controller? (check console)
- [ ] Check console for specific error message

### Issue: "No root view controller found"
**Fix**: Ensure ad is shown after UI is fully loaded:
- Ads are already delayed in RootView (0.5 second delay)
- Don't call `showAppOpenAd()` until after `onAppear`

### Issue: Ads Show for Premium Users
**Fix**: Check PurchaseManager connection:
1. Verify `adManager.setPurchaseManager()` is called
2. Check `hasActiveSubscription` returns correct value
3. Restart app after purchase to update subscription status

### Issue: "Adapter status: Adapterstatuscode(0)"
**Meaning**: Adapter not initialized yet (normal)
- Give SDK 1-2 seconds to fully initialize
- Second ad load should show status "Initialized"

## 📊 AdMob Dashboard Monitoring

After you set up production Ad Unit IDs:

1. **Go to**: https://admob.google.com/
2. **Check**: 
   - Ad requests
   - Impressions (actual ads shown)
   - Click-through rate (CTR)
   - Revenue

3. **Troubleshoot Low Metrics**:
   - No requests = Ad units not loading
   - Requests but no impressions = Ad loading failing
   - Low CTR = Unexpected (should be fine)

## 🚀 Production Checklist

Before submitting to App Store:

- [ ] Replaced test Ad Unit IDs with production IDs
- [ ] Updated `GADApplicationIdentifier` in Info.plist
- [ ] Added `NSUserTrackingUsageDescription` in Info.plist
- [ ] Tested on real device (not simulator)
- [ ] Verified free user sees ads
- [ ] Verified premium user doesn't see ads
- [ ] Checked Privacy Policy mentions ads

## 📝 Quick Reference

### Code Locations
- **AdManager**: `Services/AdManager.swift`
- **Initialization**: `GofitAIApp.swift` (line 37)
- **Show Ads**: `RootView.swift` (line 51)
- **Config**: `Info.plist` (GADApplicationIdentifier)

### Key Methods
```swift
adManager.initialize()         // Initialize SDK
adManager.showAppOpenAd()      // Show app open ad
adManager.loadInterstitialAd() // Preload interstitial
adManager.showInterstitialAd() // Show interstitial
```

### Debug Flags
```swift
#if DEBUG
  // Test ad unit IDs are active
#else
  // Production ad unit IDs will be used
#endif
```

---

**Last Updated**: February 26, 2026  
**Status**: 🟢 Ready for Testing
