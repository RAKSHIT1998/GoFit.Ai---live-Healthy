# Sign in with Apple Setup Guide

This guide explains how to set up and use Sign in with Apple in the GoFit.Ai app.

## Overview

Sign in with Apple allows users to authenticate using their Apple ID, providing a secure and privacy-focused authentication method.

## iOS Setup

### 1. Enable Sign in with Apple Capability

1. Open your project in Xcode
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple**

### 2. Configure App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID
4. Enable **Sign in with Apple** capability
5. Save and regenerate your provisioning profiles if needed

### 3. Test on Device

Sign in with Apple requires a physical device or simulator with iOS 13+:
- **Physical Device**: Works with real Apple ID
- **Simulator**: Works with simulator's Apple ID (limited functionality)

## How It Works

### Frontend (iOS)

1. **User taps "Continue with Apple" button**
2. **AppleSignInService** handles the authentication flow:
   - Generates a secure nonce
   - Requests authorization from Apple
   - Receives Apple ID token and user info
3. **AuthService** sends the token to backend
4. **Backend** verifies and creates/updates user account
5. **User is logged in** with JWT token

### Backend

1. Receives Apple ID token and user identifier
2. Checks if user exists by Apple ID
3. If user exists: Returns JWT token
4. If new user: Creates account with Apple ID
5. If email exists: Links Apple ID to existing account

## Features

### ✅ What's Implemented

- **Sign in with Apple button** in AuthView
- **Secure token handling** with nonce verification
- **User account creation** for new Apple users
- **Account linking** for existing email accounts
- **Backend API endpoint** (`POST /api/auth/apple`)
- **User model support** for Apple ID

### 🔒 Security Features

- **Nonce verification** prevents replay attacks
- **Secure token storage** in iOS Keychain
- **JWT token generation** for session management
- **Apple ID uniqueness** enforced in database

## User Flow

### New User
1. User taps "Continue with Apple"
2. Authenticates with Apple ID
3. Grants permission for name and email
4. Backend creates new account
5. User is logged in

### Existing User (Apple ID)
1. User taps "Continue with Apple"
2. Authenticates with Apple ID
3. Backend finds existing account
4. User is logged in

### Existing User (Email Account)
1. User taps "Continue with Apple"
2. Authenticates with Apple ID
3. Backend finds account by email
4. Links Apple ID to existing account
5. User is logged in

## Backend API

### Endpoint: `POST /api/auth/apple`

**Request Body:**
```json
{
  "idToken": "apple_id_token_here",
  "userIdentifier": "apple_user_identifier",
  "email": "user@example.com",  // Optional
  "name": "John Doe"              // Optional
}
```

**Response (Success):**
```json
{
  "accessToken": "jwt_token_here",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "user@example.com",
    "goals": "maintain"
  }
}
```

**Response (Error):**
```json
{
  "message": "Error message here",
  "error": "Detailed error"
}
```

## Database Schema

The User model now includes:
- `appleId`: Unique identifier from Apple (sparse index)
- `passwordHash`: Optional (not required for Apple users)

## Testing

### Test on Simulator
1. Run app on iOS Simulator (iOS 13+)
2. Tap "Continue with Apple"
3. Use simulator's Apple ID credentials

### Test on Device
1. Run app on physical device
2. Tap "Continue with Apple"
3. Use your real Apple ID credentials

### Test Account Linking
1. Create account with email/password
2. Sign out
3. Sign in with Apple using same email
4. Account should be linked automatically

## Troubleshooting

### "Sign in with Apple" button not showing
- Check that capability is enabled in Xcode
- Verify App ID has Sign in with Apple enabled
- Ensure you're testing on iOS 13+ device/simulator

### "Invalid state" error
- This usually means the nonce wasn't properly set
- Check that `AppleSignInService` is properly initialized

### Backend errors
- Verify JWT_SECRET is set in environment variables
- Check MongoDB connection
- Review server logs for detailed error messages

### Account linking issues
- Ensure email addresses match exactly (case-insensitive)
- Check for duplicate Apple IDs in database
- Verify user model validation rules

## Production Considerations

### Token Verification

Currently, the backend trusts the Apple ID token from the client. For production:

1. **Verify tokens with Apple**:
   - Use Apple's public keys: `https://appleid.apple.com/auth/keys`
   - Verify JWT signature
   - Check token expiration
   - Validate audience and issuer

2. **Implement token verification**:
   ```javascript
   // Example (needs apple-auth library)
   const appleAuth = require('apple-auth');
   const config = {
     client_id: process.env.APPLE_CLIENT_ID,
     team_id: process.env.APPLE_TEAM_ID,
     key_id: process.env.APPLE_KEY_ID,
     redirect_uri: process.env.APPLE_REDIRECT_URI
   };
   
   const response = await appleAuth.verifyIdToken(idToken, config);
   ```

### Privacy

- Apple may provide a private relay email
- Handle cases where email is not provided
- Respect user's privacy choices

## Future Enhancements

- [ ] Full token verification with Apple's servers
- [ ] Support for Apple ID credential state checking
- [ ] Handle credential revocation
- [ ] Support for sign out with Apple
- [ ] Account unlinking functionality

## Resources

- [Apple Sign in with Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [AuthenticationServices Framework](https://developer.apple.com/documentation/authenticationservices)
- [Apple ID Token Verification](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user)

