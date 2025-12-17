# Debug Signup/Login Issues - Step by Step

Follow these steps to identify why signup/login is failing.

## Step 1: Check Xcode Console Logs

When you try to signup/login, the app logs detailed information. **Look for these specific log messages:**

### Expected Logs for Signup:
```
🔵 Registration request URL: https://gofit-ai-live-healthy-1.onrender.com/api/auth/register
🔵 Base URL: https://gofit-ai-live-healthy-1.onrender.com/api
🔵 Request body: {"name":"...","email":"...","password":"***"}
🔵 Response status code: 201
```

### Error Logs to Look For:
```
❌ Network error during registration: [error description]
❌ URLError code: [code number]
❌ Registration error: [error message] (Status: [status code])
Response: [response body]
```

**ACTION:** Copy and paste ALL log messages that start with 🔵 or ❌ when you try to signup.

## Step 2: Check What Error Message Shows in the App

When registration fails, what exact error message appears in the app UI?

Common messages:
- "Registration failed"
- "Cannot reach server"
- "Network error: ..."
- "User already exists"
- "Password must be at least 8 characters"
- Something else? (Please share the exact text)

## Step 3: Test Backend Health Endpoint

Open this URL in your browser:
```
https://gofit-ai-live-healthy-1.onrender.com/health
```

**Expected:** Should show `{"status":"ok","timestamp":"..."}`

**If it fails:**
- Backend is not running
- Check Render dashboard to see if service is "Live"

## Step 4: Test Registration Endpoint Directly

Try this in your terminal (replace email/password with test values):

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test123@example.com",
    "password": "TestPass123!"
  }'
```

**Expected Success Response:**
```json
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "...",
    "name": "Test User",
    "email": "test123@example.com",
    "goals": "maintain"
  }
}
```

**If you get an error, share the exact error message.**

## Step 5: Check Render Deployment Logs

1. Go to https://dashboard.render.com
2. Click on your backend service
3. Go to "Logs" tab
4. Try to signup from the app
5. Look for error messages in the logs

**Common errors in logs:**

### MongoDB Connection Error:
```
❌ MongoDB connection error: authentication failed
```
**Fix:** Check `MONGODB_URI` in Render environment variables

### JWT_SECRET Missing:
```
Error: JWT_SECRET not configured
```
**Fix:** Add `JWT_SECRET` to Render environment variables (min 32 chars)

### Validation Error:
```
Registration error: ValidationError: ...
```
**Fix:** Check the specific validation error

## Step 6: Verify Environment Variables on Render

Go to Render dashboard → Your service → Environment tab

**Required variables:**
- ✅ `MONGODB_URI` - MongoDB connection string
- ✅ `JWT_SECRET` - Strong random string (min 32 characters)
- ⚠️ `JWT_EXPIRES_IN` - Optional (defaults to "7d")
- ⚠️ `ALLOWED_ORIGINS` - Optional (defaults to "*")

## Step 7: Check iOS App Configuration

Verify `EnvironmentConfig.swift` has the correct URL:

```swift
private static let renderBackendURL = "https://gofit-ai-live-healthy-1.onrender.com/api"
```

**Make sure:**
- URL matches your Render backend URL exactly
- No typos
- Includes `/api` at the end

## Step 8: Network Connectivity Issues

### If using iOS Simulator:
- Should work fine with external URLs like Render

### If using Physical Device:
- Make sure device has internet connection
- Try on different network (WiFi vs cellular)
- Check if corporate firewall is blocking

## Step 9: Common Issues and Quick Fixes

### Issue: "Cannot reach server"
**Possible causes:**
- Backend URL is incorrect
- Backend is not running
- Network connectivity issue

**Fix:**
1. Verify backend URL in `EnvironmentConfig.swift`
2. Check backend is running: https://gofit-ai-live-healthy-1.onrender.com/health
3. Check internet connection

### Issue: "Registration failed" (generic)
**Possible causes:**
- Backend error not properly surfaced
- Network timeout
- CORS issue

**Fix:**
1. Check Xcode console for detailed error (look for `❌ Registration error:`)
2. Check Render logs
3. Test endpoint directly with curl

### Issue: "User already exists"
**Fix:** Use a different email address

### Issue: "Password must be at least 8 characters"
**Fix:** Ensure password is 8+ characters

## Step 10: Share Debug Information

To help debug, please share:

1. **Xcode Console Logs** - All messages starting with 🔵 or ❌
2. **Error message in app UI** - Exact text shown to user
3. **Render Logs** - Any errors from backend logs
4. **curl test result** - Output from Step 4
5. **Backend health check** - Does https://gofit-ai-live-healthy-1.onrender.com/health work?

## Quick Test: Try Login Instead

If signup is failing, try logging in with an account you know exists:

1. Create account via curl (Step 4) or through another method
2. Try logging in with those credentials in the app
3. Check if login works but signup doesn't (helps narrow down the issue)

---

**Most Important:** Share the Xcode console logs (🔵 and ❌ messages) - they contain the exact error information needed to fix this!

