# Fix: Build Errors - Duplicate Info.plist and Missing StoreKit File

## Problems Fixed

1. ✅ **Deleted "gofit" scheme** - The scheme was referencing a removed app extension and deleted StoreKit file
2. ✅ **Removed StoreKit file reference** - The file was causing Xcode crashes

## Remaining Issue: Duplicate Info.plist

The error indicates that Info.plist is being processed twice. This happens when:
- `GENERATE_INFOPLIST_FILE = YES` AND `INFOPLIST_FILE` is also set
- Info.plist is in Copy Bundle Resources (shouldn't be)

## Solution

### Step 1: Clean Build Folder

1. In Xcode: **Product → Clean Build Folder** (`Cmd + Shift + K`)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GoFit*
   ```
4. Reopen Xcode

### Step 2: Verify Build Settings

1. **Select the project** in Xcode navigator
2. **Select the "GoFit.Ai - live Healthy" target**
3. **Go to "Build Settings" tab**
4. **Search for "Info.plist"**

5. **Check these settings:**
   - `GENERATE_INFOPLIST_FILE` should be **YES**
   - `INFOPLIST_FILE` should be **"GoFit.Ai - live Healthy/Info.plist"**

6. **If both are set, you have two options:**

   **Option A: Use explicit Info.plist (Recommended)**
   - Set `GENERATE_INFOPLIST_FILE` to **NO**
   - Keep `INFOPLIST_FILE` = `"GoFit.Ai - live Healthy/Info.plist"`

   **Option B: Use generated Info.plist**
   - Set `GENERATE_INFOPLIST_FILE` to **YES**
   - Remove `INFOPLIST_FILE` (set to empty)
   - Move Info.plist keys to build settings (INFOPLIST_KEY_*)

### Step 3: Check Copy Bundle Resources

1. **Select the target**
2. **Go to "Build Phases" tab**
3. **Expand "Copy Bundle Resources"**
4. **If Info.plist is listed here, remove it:**
   - Select Info.plist
   - Click the **"-"** button

### Step 4: Verify Scheme

1. **Click the scheme selector** (top of Xcode)
2. **Make sure "GoFit.Ai - live Healthy" is selected** (not "gofit")
3. **Click "Manage Schemes..."**
4. **Verify only these schemes exist:**
   - ✅ GoFit.Ai - live Healthy
   - ✅ GoFit.Ai - live HealthyTests
   - ✅ GoFit.Ai - live HealthyUITests
   - ❌ gofit (should NOT exist - if it does, delete it)

### Step 5: Rebuild

1. **Product → Clean Build Folder** (`Cmd + Shift + K`)
2. **Product → Build** (`Cmd + B`)
3. **Check for errors**

## Recommended Configuration

For your project, use **Option A** (explicit Info.plist):

```
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = "GoFit.Ai - live Healthy/Info.plist"
```

This is the standard configuration and works best when you have a custom Info.plist file.

## Verification

After fixing:

1. ✅ No "gofit" scheme exists
2. ✅ No StoreKit file reference errors
3. ✅ Info.plist is not in Copy Bundle Resources
4. ✅ Only one Info.plist processing method is used
5. ✅ Build succeeds without duplicate file errors

## If Issues Persist

1. **Close Xcode completely**
2. **Delete Derived Data** (as shown above)
3. **Delete Xcode caches:**
   ```bash
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   ```
4. **Reopen Xcode**
5. **Clean and rebuild**

The duplicate Info.plist error should be resolved after these steps.
