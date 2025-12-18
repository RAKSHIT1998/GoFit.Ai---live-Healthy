# HealthKit Setup Instructions

## Issue
The app is showing errors: "Missing com.apple.developer.healthkit entitlement"

## Solution

### 1. Enable HealthKit Capability in Xcode

1. Open your project in Xcode
2. Select your app target (GoFit.Ai - live Healthy)
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **HealthKit**
6. Make sure the HealthKit capability is enabled

### 2. Files Updated

✅ **Entitlements File** (`GoFit_Ai___live_Healthy.entitlements`)
- Added `com.apple.developer.healthkit` key set to `true`
- Added `com.apple.developer.healthkit.access` array

✅ **Info.plist**
- Added `NSHealthShareUsageDescription` - explains why app needs to read health data
- Added `NSHealthUpdateUsageDescription` - explains why app needs to write health data

✅ **HealthKitService.swift**
- Added better error handling for missing entitlements
- Improved authorization status checking

### 3. After Enabling HealthKit in Xcode

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Rebuild**: Product → Build (Cmd+B)
3. **Run**: Product → Run (Cmd+R)

### 4. Testing

After enabling HealthKit:
- The app should no longer show "Missing entitlement" errors
- When you tap to enable HealthKit sync, iOS will show the permission dialog
- The permission dialog will display the usage descriptions from Info.plist

### 5. Important Notes

- HealthKit only works on **physical devices**, not simulators
- You need a valid Apple Developer account to use HealthKit
- The app must be signed with a provisioning profile that includes HealthKit capability
- HealthKit data is private and requires explicit user permission

### 6. If Errors Persist

1. Check that your Apple Developer account has HealthKit enabled
2. Verify the provisioning profile includes HealthKit
3. Make sure you're testing on a physical device (not simulator)
4. Check Xcode console for detailed error messages

## Token Errors

The "Invalid token" errors are separate from HealthKit and indicate:
- The authentication token has expired
- The user needs to log in again
- The backend token validation is failing

To fix token errors:
1. Log out and log back in
2. Check that the backend JWT_SECRET is properly configured
3. Verify the token is being sent correctly in API requests

