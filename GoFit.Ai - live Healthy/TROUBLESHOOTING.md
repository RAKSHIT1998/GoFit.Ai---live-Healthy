# Troubleshooting: Can't Run on Simulator

## Common Issues and Solutions

### 1. Build Errors
If you see build errors, try:
1. **Clean Build Folder**: `Cmd + Shift + K`
2. **Delete Derived Data**: 
   - Xcode → Preferences → Locations
   - Click arrow next to Derived Data path
   - Delete the folder for your project
3. **Restart Xcode**
4. **Rebuild**: `Cmd + B`

### 2. Missing Info.plist Permissions
The app needs these permissions. Check if they're in Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>GoFit.ai needs camera access to take photos of your meals.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>GoFit.ai needs photo library access to choose meal photos.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>GoFit.ai needs to save images for your meal logs.</string>

<key>NSHealthShareUsageDescription</key>
<string>GoFit.ai needs access to your health data to sync steps, heart rate, and calories.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>GoFit.ai needs to write weight and water intake data to Health.</string>
```

### 3. Missing Capabilities
In Xcode, go to **Signing & Capabilities** and ensure these are added:
- ✅ HealthKit
- ✅ In-App Purchase
- ✅ Camera (if not automatically added)

### 4. Code Signing Issues
1. Select your project in Xcode
2. Go to **Signing & Capabilities**
3. Select your **Team** (Apple Developer account)
4. Ensure **Automatically manage signing** is checked
5. Xcode will create provisioning profiles automatically

### 5. Simulator Issues
1. **Reset Simulator**: Device → Erase All Content and Settings
2. **Try Different Simulator**: iPhone 15, iPhone 14, etc.
3. **Check iOS Version**: Ensure simulator is running iOS 16+ (required for some features)

### 6. Missing Dependencies
Ensure all Swift files are added to the target:
1. Select a file in Xcode
2. Check **Target Membership** in File Inspector
3. Ensure "GoFit.Ai - live Healthy" is checked

### 7. SwiftData Model Issues
If you see errors about `Item`:
- The `Item` model is in `Models/Item.swift`
- Ensure it's added to the target
- The model is used for SwiftData persistence

### 8. Network Issues (Backend)
If the app crashes on network calls:
- The backend doesn't need to be running for the app to launch
- Network errors will be handled gracefully
- To test full functionality, start the backend server

### 9. Check Console for Errors
1. Run the app: `Cmd + R`
2. Open Console: `Cmd + Shift + Y`
3. Look for red error messages
4. Common errors:
   - Missing permissions
   - Network timeouts
   - Missing models

### 10. Verify App Entry Point
The app should start with `GoFitAiApp.swift` which shows `RootView()`.
- If you see a different screen, check `RootView.swift`
- Ensure `@main` is on `GoFitAiApp` struct

## Quick Fix Checklist

- [ ] Clean Build Folder (`Cmd + Shift + K`)
- [ ] Delete Derived Data
- [ ] Check Info.plist has all permissions
- [ ] Verify capabilities are added (HealthKit, IAP)
- [ ] Check code signing team is selected
- [ ] Ensure all Swift files are in target
- [ ] Try a different simulator
- [ ] Restart Xcode
- [ ] Check Console for specific error messages

## Still Not Working?

1. **Check Xcode Build Log**:
   - View → Navigators → Show Report Navigator
   - Look for red error messages
   - Share the specific error

2. **Verify Project Structure**:
   - All files should be in "GoFit.Ai - live Healthy" folder
   - No duplicate files
   - All files have correct target membership

3. **Check Minimum iOS Version**:
   - Project → General → Deployment Target
   - Should be iOS 16.0 or higher

4. **Verify Bundle Identifier**:
   - Should be unique (e.g., `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`)
   - No special characters that might cause issues

