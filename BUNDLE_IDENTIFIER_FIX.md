# Fix: Bundle Identifier Error

## Problem
**Error:** "The requested application com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy is not installed. Provide a valid bundle identifier."

This error typically occurs when:
1. The app hasn't been built/installed on the device/simulator
2. There are stale references to removed targets/extensions
3. Derived data is corrupted
4. Xcode schemes are misconfigured

## Solution

### Step 1: Clean Build Folder and Derived Data

1. **In Xcode:**
   - Go to **Product → Clean Build Folder** (`Cmd + Shift + K`)
   - Wait for it to complete

2. **Delete Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GoFit*
   ```

3. **Close and Reopen Xcode**

### Step 2: Verify Bundle Identifier

1. **Open your project in Xcode**
2. **Select the project** in the navigator (top item)
3. **Select the "GoFit.Ai - live Healthy" target**
4. **Go to "General" tab**
5. **Check "Bundle Identifier":**
   - Should be: `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`
   - If it's different, update it to match

6. **Go to "Build Settings" tab**
7. **Search for "PRODUCT_BUNDLE_IDENTIFIER"**
8. **Verify it's set to:** `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`

### Step 3: Check Schemes

1. **Click the scheme selector** (next to the device selector at the top)
2. **Click "Manage Schemes..."**
3. **Verify you have:**
   - ✅ `GoFit.Ai - live Healthy` (should be checked/shared)
   - ❌ `gofit` (should NOT exist - if it does, delete it)

4. **If "gofit" scheme exists:**
   - Select it
   - Click the **"-"** button to delete it
   - Click **"OK"**

### Step 4: Verify Signing & Capabilities

1. **Select the target "GoFit.Ai - live Healthy"**
2. **Go to "Signing & Capabilities" tab**
3. **Verify:**
   - ✅ **"Automatically manage signing"** is checked
   - ✅ **Team** is selected (48TGY734WW)
   - ✅ **Bundle Identifier** matches: `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`

### Step 5: Select Correct Device/Simulator

1. **Click the device selector** at the top of Xcode
2. **Select:**
   - A physical device (if connected), OR
   - An iOS Simulator (e.g., "iPhone 15 Pro" or "iPhone 16")

3. **Make sure it's NOT set to "Any iOS Device"** when trying to run

### Step 6: Build and Run

1. **Build the project:**
   - Press `Cmd + B` to build
   - Wait for build to complete
   - Check for any errors in the Issue Navigator

2. **Run the app:**
   - Press `Cmd + R` to run
   - The app should install on the selected device/simulator

### Step 7: If Still Getting Error

If you're still getting the error after the above steps:

1. **Check if the app is actually installed:**
   - On Simulator: Check the home screen for the app icon
   - On Device: Check if the app appears in your apps

2. **Uninstall the app** (if it exists):
   - On Simulator: Long-press the app icon → Delete App
   - On Device: Long-press the app icon → Remove App

3. **Rebuild and reinstall:**
   - Clean build folder again
   - Build and run fresh

4. **Check Console for errors:**
   - In Xcode: **View → Debug Area → Activate Console**
   - Look for any error messages when trying to run

## What Was Fixed

✅ **Removed stale "gofit" scheme reference** from `xcschememanagement.plist`

The removed "gofit" app extension was still referenced in the scheme management file, which could cause Xcode to try to build/run a non-existent target.

## Verification

After following these steps, you should be able to:
- ✅ Build the project without errors
- ✅ Run the app on simulator/device
- ✅ See the app install and launch successfully

## Common Issues

### Issue: "No such module"
- **Solution:** Clean build folder and rebuild

### Issue: Code signing errors
- **Solution:** Check Signing & Capabilities → Team is selected

### Issue: App builds but doesn't install
- **Solution:** 
  1. Uninstall any existing version
  2. Clean build folder
  3. Rebuild and run

### Issue: Simulator won't launch
- **Solution:**
  1. Xcode → Settings → Platforms
  2. Download/update iOS Simulator
  3. Try a different simulator device

## Next Steps

Once the app builds and runs successfully:
1. Test the main features
2. Verify authentication works
3. Check that HealthKit permissions are requested
4. Test in-app purchases (if applicable)

If you continue to have issues, share:
- The exact error message
- What step you're on when it fails
- Console output (if available)
