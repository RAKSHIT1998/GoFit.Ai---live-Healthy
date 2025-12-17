# Skip Authentication (Development Mode)

This feature allows you to bypass authentication during development and testing.

## How to Enable/Disable

Edit `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`:

```swift
// ⚠️ DEVELOPMENT ONLY: Set to true to skip authentication
// ⚠️ NEVER enable this in production builds!
static let skipAuthentication: Bool = true  // Set to false to require authentication
```

## How It Works

When `skipAuthentication` is set to `true`:

1. **Automatic Skip on App Launch:**
   - The app automatically logs you in as a dev user
   - No authentication screen is shown
   - You can immediately access all features

2. **Manual Skip Button:**
   - If you reach the authentication screen, you'll see a "Skip Authentication (Dev Mode)" button
   - Tap it to bypass authentication

3. **Dev User Details:**
   - **Name:** "Dev User" (or your saved name)
   - **Email:** "dev@example.com" (or your saved email)
   - **User ID:** Auto-generated dev user ID
   - **Token:** Mock token (won't work with backend API calls)

## Important Notes

### ⚠️ Backend API Calls Will Fail

When authentication is skipped:
- The app uses a mock token (`dev-token-skip-auth`)
- **Backend API calls that require authentication will fail**
- This is expected behavior - you're bypassing authentication

### ✅ What Works

- All UI features
- Local data storage
- Offline functionality
- App navigation
- Onboarding flow

### ❌ What Won't Work

- Backend API calls (they require valid authentication)
- User registration/login
- Data syncing with backend
- Protected endpoints

## When to Use

- **Development:** Testing UI without backend
- **Design:** Working on app design without authentication setup
- **Demo:** Quick demos without backend connection
- **Testing:** Testing features that don't require backend

## When NOT to Use

- **Production builds:** Never enable in production!
- **Backend testing:** When you need to test API integration
- **Real user flows:** When testing actual authentication

## Disabling for Production

Before releasing to production:

1. Set `skipAuthentication = false` in `EnvironmentConfig.swift`
2. Test that authentication works correctly
3. Verify all backend API calls work with real authentication

## Troubleshooting

### App still shows login screen
- Make sure `skipAuthentication = true` in `EnvironmentConfig.swift`
- Clean build folder (Product → Clean Build Folder)
- Rebuild the app

### Backend calls fail
- This is expected when skipping authentication
- The mock token won't work with real backend
- To test backend, set `skipAuthentication = false` and use real authentication

### Want to test with real auth temporarily
- Set `skipAuthentication = false`
- Use the registration/login flow
- Or use the test user script: `npm run create-test-user` in backend directory

