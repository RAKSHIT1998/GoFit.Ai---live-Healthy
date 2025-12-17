# Quick Fix Guide - Getting Into the App

## Problem Fixed

The app was stuck and you couldn't get inside because:
1. **Onboarding wasn't being skipped** when authentication was skipped
2. **State wasn't being properly initialized** with default values
3. **No way to bypass onboarding** manually

## What's Fixed

✅ **Automatic Skip**: When `skipAuthentication = true`, the app now:
- Automatically sets `didFinishOnboarding = true`
- Creates a demo user profile
- Sets default values (name, weight, height, goal)
- Saves state immediately
- Takes you straight to the main app

✅ **Skip Button**: Added a "Skip" button on onboarding screen (dev mode only)

✅ **Better State Management**: 
- Default values are set if not present
- State loading is more robust
- Won't get stuck on empty values

## How to Use

### Option 1: Automatic (Recommended)
1. Make sure `skipAuthentication = true` in `EnvironmentConfig.swift`
2. Run the app
3. **You should go straight to the main app** - no onboarding, no login!

### Option 2: Manual Skip
1. If you see onboarding screen, tap **"Skip"** button (top right)
2. You'll go straight to the app

### Option 3: Reset Everything
If you want to start fresh:
```swift
// In your code or debug console
auth.resetAppState()
```

## Current Settings

- **Skip Authentication**: ✅ Enabled (`skipAuthentication = true`)
- **Demo User**: Automatically created
- **Onboarding**: Automatically skipped

## Demo User Profile

When skipping authentication, you get:
- **Name**: "Dev User" (or your saved name)
- **Email**: "dev@example.com" (or your saved email)
- **Weight**: 70 kg
- **Height**: 170 cm
- **Goal**: "maintain"
- **User ID**: Auto-generated dev user ID

## Troubleshooting

### Still stuck on onboarding?
1. Check `EnvironmentConfig.swift` - make sure `skipAuthentication = true`
2. Clean build folder: Product → Clean Build Folder
3. Delete app from device/simulator
4. Rebuild and run

### Still stuck on login screen?
1. The skip authentication should work automatically
2. If not, check console logs for errors
3. Try tapping "Skip Authentication (Dev Mode)" button if visible

### Want to test real authentication?
1. Set `skipAuthentication = false` in `EnvironmentConfig.swift`
2. Rebuild app
3. Use registration/login flow

### Reset app state programmatically
Add this to your code temporarily:
```swift
// In RootView or wherever you have access to auth
.onAppear {
    if EnvironmentConfig.skipAuthentication {
        auth.resetAppState() // Clear everything
        // Then skip auth will recreate demo user
    }
}
```

## Files Changed

1. **AuthViewModel.swift**:
   - Sets `didFinishOnboarding = true` when skipping auth
   - Initializes default values
   - Better state loading
   - Added `resetAppState()` method

2. **OnboardingScreens.swift**:
   - Added "Skip" button (dev mode only)
   - Skips permissions screen when skip auth is enabled
   - Better onboarding completion

3. **LocalState**:
   - Added default values to prevent decoding failures

## Next Steps

Once you're in the app:
1. ✅ You should see the main tab view
2. ✅ All features should work (UI only, backend calls will fail)
3. ✅ You can navigate around and test the interface

**Note**: Backend API calls will fail because we're using a mock token. This is expected when skipping authentication.

