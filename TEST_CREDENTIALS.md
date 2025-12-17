# Test User Credentials

## ⚠️ Security Notice

**Never commit test credentials to version control!** This file should only contain instructions, not actual credentials.

## Creating Test Accounts

### Method 1: Using the Script (Recommended)

The safest way to create test accounts is using the provided script, which generates random credentials:

```bash
cd backend
npm run create-test-user
```

The script will:
- Generate random, unique credentials
- Create the user in the database
- Display the credentials (save them securely, not in git!)

### Method 2: Using the iOS App

1. Open the app
2. Go to the registration screen
3. Enter your desired test credentials
4. Tap "Create Account"

**Note:** Use unique credentials that are not committed to version control.

### Method 3: Using the API Endpoint

You can create a test user via the registration endpoint:

```bash
curl -X POST <YOUR_BACKEND_URL>/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Your Test Name",
    "email": "your-test-email@example.com",
    "password": "YourSecurePassword123!"
  }'
```

**Important:**
- Replace `<YOUR_BACKEND_URL>` with your actual backend URL
- Use unique credentials that are not documented anywhere
- Never commit these credentials to git

## Storing Credentials Securely

If you need to share test credentials with your team:

1. **Use a password manager** (1Password, LastPass, etc.)
2. **Use environment variables** (not committed to git)
3. **Use a secure team communication channel** (not in Slack/email)
4. **Rotate credentials regularly**

## Troubleshooting

### "User already exists"
- The email is already registered
- Use a different email address
- Or delete the existing user from the database

### Registration fails
- Check that the backend is running
- Verify the API URL in `EnvironmentConfig.swift`
- Check deployment logs for errors

## Best Practices

1. ✅ **DO:** Use the script to generate random credentials
2. ✅ **DO:** Store credentials in a password manager
3. ✅ **DO:** Use unique credentials for each environment (dev/staging/prod)
4. ❌ **DON'T:** Commit credentials to version control
5. ❌ **DON'T:** Share credentials in public channels
6. ❌ **DON'T:** Reuse production credentials for testing
