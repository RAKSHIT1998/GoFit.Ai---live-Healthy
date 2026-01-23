# New Bundle Identifier Setup Guide

## What Changed

The bundle identifier has been updated from:
- **Old:** `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`
- **New:** `com.rakshit.gofitai`

This change allows you to create a fresh App Store Connect app record without needing to restore the previously removed app.

## Updated Bundle Identifiers

- **Main App:** `com.rakshit.gofitai`
- **Unit Tests:** `com.rakshit.gofitaiTests`
- **UI Tests:** `com.rakshit.gofitaiUITests`

## Next Steps

### 1. Clean Build Folder
1. In Xcode: **Product → Clean Build Folder** (`Cmd + Shift + K`)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GoFit*
   ```

### 2. Verify Bundle Identifier in Xcode
1. Open the project in Xcode
2. Select the project in the navigator
3. Select the "GoFit.Ai - live Healthy" target
4. Go to **General** tab
5. Verify **Bundle Identifier** shows: `com.rakshit.gofitai`
6. If it doesn't match, select it and manually type: `com.rakshit.gofitai`

### 3. Update Signing & Capabilities
1. Go to **Signing & Capabilities** tab
2. Ensure **"Automatically manage signing"** is checked
3. Select your **Team** (Apple Developer account)
4. Xcode will automatically create new provisioning profiles for the new bundle identifier

### 4. Create New App in App Store Connect
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in the details:
   - **Platform:** iOS
   - **Name:** GoFit.AI (or your preferred name)
   - **Primary Language:** English (or your preferred)
   - **Bundle ID:** Select `com.rakshit.gofitai` from the dropdown
     - If it's not in the dropdown, you may need to register it first in [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
   - **SKU:** `gofitai-001` (or any unique identifier)
4. Click **"Create"**

### 5. Register Bundle Identifier (if needed)
If `com.rakshit.gofitai` doesn't appear in App Store Connect:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Click **"+"** to add a new identifier
3. Select **"App IDs"** → **"Continue"**
4. Select **"App"** → **"Continue"**
5. Fill in:
   - **Description:** GoFit.AI
   - **Bundle ID:** `com.rakshit.gofitai`
6. Select required capabilities:
   - ✅ HealthKit
   - ✅ In-App Purchase
   - ✅ Sign in with Apple
7. Click **"Continue"** → **"Register"**

### 6. Update StoreKit Configuration (if using)
If you're using a local StoreKit configuration file for testing, the product IDs remain the same:
- Monthly: `com.gofitai.premium.monthlyy`
- Yearly: `com.gofitai.premium.yearlyyy`

These product IDs are independent of the bundle identifier.

### 7. Build and Archive
1. In Xcode, select **"Any iOS Device"** or a connected device
2. **Product → Archive**
3. Once archived, click **"Distribute App"**
4. Select **"App Store Connect"** → **"Upload"**
5. Follow the prompts to upload to your new app record

## Important Notes

- ⚠️ **This is a new app record** - you'll need to set up all metadata, screenshots, and app information again in App Store Connect
- ⚠️ **Existing users** who had the old app installed will need to download the new app (it will appear as a separate app)
- ⚠️ **TestFlight** builds will need to be set up fresh for the new app
- ✅ **Product IDs** for subscriptions remain the same and don't need to be recreated
- ✅ **Backend API** and authentication remain unchanged

## Verification Checklist

- [ ] Bundle identifier updated in Xcode project settings
- [ ] Xcode signing shows the new bundle identifier
- [ ] Bundle identifier registered in Apple Developer Portal (if needed)
- [ ] New app created in App Store Connect with the new bundle identifier
- [ ] Archive builds successfully with the new bundle identifier
- [ ] Upload to App Store Connect succeeds

## Troubleshooting

### "Bundle identifier already exists"
- This means the bundle identifier is already registered. You can either:
  - Use a different bundle identifier (e.g., `com.rakshit.gofitai2`)
  - Or use the existing one if it's available

### "No provisioning profile found"
- Ensure "Automatically manage signing" is enabled
- Select your development team
- Xcode will create the provisioning profile automatically

### "Invalid bundle identifier"
- Bundle identifiers must:
  - Use reverse domain notation (e.g., `com.company.appname`)
  - Contain only alphanumeric characters, dots, and hyphens
  - Start and end with alphanumeric characters
  - Not contain spaces or special characters
