# Apple In-App Purchase Credentials

This document contains your Apple In-App Purchase credentials. **Keep this secure and never commit to git!**

## Credentials

- **In-App Purchase Key ID**: `2WR55LJR4K`
- **App Store Connect API Key ID**: `AM9B5Z682V`
- **Shared Secret**: `0c401df645b84cbd949f34a68d706ff9`
- **Bundle ID**: `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`

## Where to Configure

### Backend (.env file)

Add these to your `backend/.env` file:

```env
# Apple In-App Purchase
APPLE_SHARED_SECRET=0c401df645b84cbd949f34a68d706ff9
APPLE_APP_STORE_CONNECT_API_KEY_ID=AM9B5Z682V
APPLE_IN_APP_PURCHASE_KEY_ID=2WR55LJR4K
APPLE_BUNDLE_ID=com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy
```

### Production (Render/Heroku/etc.)

Add these as environment variables in your hosting platform:

1. **Render Dashboard**:
   - Go to your service → Environment
   - Add each variable:
     - `APPLE_SHARED_SECRET` = `0c401df645b84cbd949f34a68d706ff9`
     - `APPLE_APP_STORE_CONNECT_API_KEY_ID` = `AM9B5Z682V`
     - `APPLE_IN_APP_PURCHASE_KEY_ID` = `2WR55LJR4K`
     - `APPLE_BUNDLE_ID` = `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`

2. **Heroku**:
   ```bash
   heroku config:set APPLE_SHARED_SECRET=0c401df645b84cbd949f34a68d706ff9
   heroku config:set APPLE_APP_STORE_CONNECT_API_KEY_ID=AM9B5Z682V
   heroku config:set APPLE_IN_APP_PURCHASE_KEY_ID=2WR55LJR4K
   heroku config:set APPLE_BUNDLE_ID=com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy
   ```

## What Each Credential Is For

### Shared Secret (`APPLE_SHARED_SECRET`)
- **Purpose**: Used for receipt validation with Apple's App Store server
- **Where to get**: App Store Connect → Users and Access → Keys → In-App Purchase → Shared Secret
- **Used in**: Backend receipt validation endpoints

### App Store Connect API Key ID (`APPLE_APP_STORE_CONNECT_API_KEY_ID`)
- **Purpose**: Used for App Store Connect API authentication (server-to-server notifications)
- **Where to get**: App Store Connect → Users and Access → Keys → App Store Connect API
- **Used in**: Server-to-server notification handling (if implemented)

### In-App Purchase Key ID (`APPLE_IN_APP_PURCHASE_KEY_ID`)
- **Purpose**: Identifier for your in-app purchase key
- **Where to get**: App Store Connect → Users and Access → Keys → In-App Purchase
- **Used in**: Key management and identification

### Bundle ID (`APPLE_BUNDLE_ID`)
- **Purpose**: Your app's unique identifier
- **Current value**: `com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy`
- **Must match**: The bundle identifier in Xcode project settings

## Security Notes

⚠️ **IMPORTANT**: 
- Never commit these credentials to git
- The `.env` file is already in `.gitignore`
- Keep this document secure
- Rotate credentials if compromised
- Use different credentials for development and production

## Verification

After setting up, verify the credentials are loaded:

1. Check backend logs on startup - should show:
   ```
   ✅ APPLE_SHARED_SECRET is configured
   ```

2. Test subscription purchase flow
3. Verify receipt validation works

## Troubleshooting

If subscription verification fails:
1. Verify `APPLE_SHARED_SECRET` is set correctly (no extra spaces)
2. Ensure `APPLE_BUNDLE_ID` matches your Xcode bundle identifier
3. Check App Store Connect to ensure products are approved
4. Verify sandbox testing accounts are set up correctly
