# Test User Credentials

## Quick Test Account

Use these credentials to login to the app:

**Email:** `testuser@gofit.ai`  
**Password:** `TestPass123!`

## Create This Account

Since the backend is deployed on Render, you can create this account using one of these methods:

### Method 1: Using curl (Terminal)

Run this command in your terminal:

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "testuser@gofit.ai",
    "password": "TestPass123!"
  }'
```

### Method 2: Using the iOS App

1. Open the app
2. Go to the registration screen
3. Enter:
   - **Name:** Test User
   - **Email:** testuser@gofit.ai
   - **Password:** TestPass123!
   - **Confirm Password:** TestPass123!
4. Tap "Create Account"

### Method 3: Using Postman or Similar Tool

1. Create a POST request to: `https://gofit-ai-live-healthy-1.onrender.com/api/auth/register`
2. Set header: `Content-Type: application/json`
3. Body (JSON):
```json
{
  "name": "Test User",
  "email": "testuser@gofit.ai",
  "password": "TestPass123!"
}
```

## Alternative Test Accounts

If `testuser@gofit.ai` is already taken, try these:

**Account 2:**
- Email: `demo@gofit.ai`
- Password: `DemoPass123!`

**Account 3:**
- Email: `test123@gofit.ai`
- Password: `Test123456!`

## After Creating the Account

Once the account is created, you can login in the app using:
- **Email:** `testuser@gofit.ai`
- **Password:** `TestPass123!`

## Troubleshooting

### "User already exists"
- The email is already registered
- Try one of the alternative accounts above
- Or use a different email

### Registration fails
- Check that the backend is running: `https://gofit-ai-live-healthy-1.onrender.com/health`
- Verify the API URL in `EnvironmentConfig.swift`
- Check Render deployment logs for errors

