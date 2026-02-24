# AdMob Quick Setup Guide

## 🚀 Quick Start (5 Steps)

### 1. Add Google Mobile Ads SDK

**Via Swift Package Manager (Easiest)**:
```
1. Xcode → File → Add Package Dependencies
2. Paste: https://github.com/googleads/swift-package-manager-google-mobile-ads.git
3. Version: 11.0.0 or later
4. Click "Add Package"
```

### 2. Get Your AdMob IDs

1. Go to: https://admob.google.com/
2. Create new app → Select iOS → Name: "GoFit.Ai"
3. Note your **App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
4. Create **App Open Ad** unit
5. Note **Ad Unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`

### 3. Update Info.plist

Open `GoFit.Ai - live Healthy/Info.plist` and add:

```xml
<!-- Right after the opening <dict> tag -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>

<key>NSUserTrackingUsageDescription</key>
<string>This allows us to show you personalized ads based on your interests.</string>

<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2fnua5tdw4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ydx93a7ass.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5a6flpkh64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>p78axxw29g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ludvb6z3bs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cp8zw746q7.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>c6k4g5qg8m.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>s39g8k73mm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>3qy4746246.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>f38h382jlk.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>hs6bdukanm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v4nckwkbmz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>wzmmz9fp6w.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>yclnxrl5pm.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>t38b2kh725.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>7ug5zh24hu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>gta9lk7p23.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>vutu7akeur.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>y5ghdn5j9k.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n6fk4nfna4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>n38lu8286q.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>47vhws6wlr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>kbd757ywx3.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>9t245vhmpl.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>eh6m2bh4zr.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>a2p9lx4jpn.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>22mmun2rn5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4468km3ulz.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2u9pt9hc89.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>8s468mfl3y.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>klf5c3l5u5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ppxm28t8ap.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>av6w8kgt66.skadnetwork</string>
    </dict>
</array>
```

### 4. Update Ad Unit IDs in Code

Open `Services/AdManager.swift` and replace:

```swift
// Find line ~21 (in #else section)
#else
private let appOpenAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY" // YOUR APP OPEN AD ID HERE
private let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ" // YOUR INTERSTITIAL AD ID HERE
#endif
```

### 5. Test It!

**Debug Mode (Test Ads)**:
```
1. Build and Run (Cmd+R)
2. Sign up / Login
3. You should see test ads
```

**Production Mode**:
```
1. Switch to Release build configuration
2. Build on real device
3. Verify real ads display
```

---

## 🎯 What's Already Done

✅ AdManager service created  
✅ Subscription screen with "Skip and use with ads" button  
✅ Feature gating (3 recommendations for free, 15 for premium)  
✅ App open ads on every launch  
✅ Ad-free experience for premium users  

## 🔍 Quick Test Commands

```bash
# Clean build
cd "/Users/rakshitbargotra/Documents/GoFit.Ai - live Healthy"
rm -rf ~/Library/Developer/Xcode/DerivedData

# Open project
open "GoFit.Ai - live Healthy.xcodeproj"
```

## ⚠️ Important Notes

1. **Test IDs**: Already configured for development
2. **Production IDs**: Must be replaced before App Store submission
3. **Info.plist**: MUST add GADApplicationIdentifier
4. **SDK**: MUST install Google Mobile Ads SDK via SPM

## 📞 Need Help?

- SDK not found? → Re-add Swift Package
- Ads not showing? → Check console logs
- Build errors? → Clean build folder

---

**Total Setup Time**: ~15 minutes  
**Difficulty**: Easy (mostly copy-paste)
