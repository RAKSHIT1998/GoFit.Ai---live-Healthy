# Quick Fix: Can't Run on Simulator

## Immediate Steps to Try

### Step 1: Clean Everything
1. In Xcode: **Product → Clean Build Folder** (`Cmd + Shift + K`)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GoFit*
   ```
4. Reopen Xcode

### Step 2: Check Build Settings
1. Select project in Xcode
2. Select target "GoFit.Ai - live Healthy"
3. Go to **Build Settings**
4. Search for "Info.plist"
5. Ensure `INFOPLIST_FILE` points to: `GoFit.Ai - live Healthy/Info.plist`

### Step 3: Verify Signing
1. Select target
2. Go to **Signing & Capabilities**
3. Check **"Automatically manage signing"**
4. Select your **Team** (Apple Developer account)
5. If you don't have a team, create a free Apple ID account

### Step 4: Check Capabilities
In **Signing & Capabilities**, ensure these are added:
- ✅ HealthKit
- ✅ In-App Purchase

### Step 5: Select Simulator
1. At the top of Xcode, click the device selector
2. Choose: **iPhone 15** or **iPhone 15 Pro** (iOS 17+)
3. If simulator isn't available: **Xcode → Settings → Platforms → Download iOS Simulator**

### Step 6: Build and Run
1. Press `Cmd + B` to build
2. Check for errors in the Issue Navigator (left sidebar)
3. If build succeeds, press `Cmd + R` to run

## Common Error Messages

### "No such module '___'"
- Solution: Clean build folder and rebuild

### "Code signing error"
- Solution: Select your team in Signing & Capabilities

### "Info.plist not found"
- Solution: Check Build Settings → INFOPLIST_FILE path

### "Missing required capabilities"
- Solution: Add HealthKit and In-App Purchase capabilities

### App crashes immediately
- Check Console for error messages
- Verify Info.plist permissions are added
- Check if backend is required (it's not for initial launch)

## Still Not Working?

**Share the specific error message** from:
1. Xcode's Issue Navigator (red errors)
2. Console output when you try to run
3. Build log (View → Navigators → Show Report Navigator)

This will help identify the exact issue!

