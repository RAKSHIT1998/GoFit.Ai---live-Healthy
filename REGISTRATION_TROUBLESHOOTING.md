# Registration Troubleshooting Guide

If registration is failing, follow these steps to identify and fix the issue.

## Step 1: Check Xcode Console Logs

When you try to register, the app now logs detailed information. Look for:

### Successful Request Logs:
```
🔵 Registration request URL: https://gofit-ai-live-healthy-1.onrender.com/api/auth/register
🔵 Base URL: https://gofit-ai-live-healthy-1.onrender.com/api
🔵 Request body: {"name":"...","email":"...","password":"***"}
🔵 Response status code: 201
```

### Error Logs:
```
❌ Registration error: [error message] (Status: [status code])
Response: [response body]
```

## Step 2: Common Error Messages and Fixes

### "Cannot reach server" or "Network error"
**Possible causes:**
- Backend is not running
- Incorrect API URL
- Network connectivity issue
- CORS issue

**Fixes:**
1. Verify backend is running: `https://gofit-ai-live-healthy-1.onrender.com/health`
2. Check `EnvironmentConfig.swift` has correct URL
3. Check internet connection
4. Verify CORS settings on backend

### "Registration failed with status code 400"
**Possible causes:**
- Missing required fields (name, email, password)
- Password too short (< 8 characters)
- Invalid email format
- User already exists

**Fixes:**
1. Check that all fields are filled
2. Ensure password is at least 8 characters
3. Verify email format is valid
4. Try a different email address

### "Registration failed with status code 500"
**Possible causes:**
- MongoDB connection issue
- JWT_SECRET not configured
- Backend validation error

**Fixes:**
1. Check Render deployment logs
2. Verify `MONGODB_URI` is set in Render environment variables
3. Verify `JWT_SECRET` is set in Render environment variables
4. Check the error message in the response body

### "Failed to decode server response"
**Possible causes:**
- Backend returned unexpected response format
- Response is not valid JSON

**Fixes:**
1. Check the response body in logs
2. Verify backend is returning `{ accessToken: "...", user: {...} }`
3. Check backend logs for errors

## Step 3: Test Backend Directly

Test the registration endpoint using curl:

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "TestPass123!"
  }' \
  -v
```

The `-v` flag shows detailed request/response information.

**Expected success response:**
```json
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "...",
    "name": "Test User",
    "email": "test@example.com",
    "goals": "maintain"
  }
}
```

## Step 4: Check Render Environment Variables

Verify these are set in Render dashboard:

1. **MONGODB_URI** - Your MongoDB Atlas connection string
2. **JWT_SECRET** - Strong random string (minimum 32 characters)
3. **JWT_EXPIRES_IN** - Optional (defaults to "7d")
4. **ALLOWED_ORIGINS** - Optional (defaults to "*" for all origins)

To check:
1. Go to Render dashboard
2. Select your backend service
3. Go to "Environment" tab
4. Verify all required variables are set

## Step 5: Check Render Deployment Logs

1. Go to Render dashboard
2. Select your backend service
3. Go to "Logs" tab
4. Try to register from the app
5. Look for error messages

Common log errors:

### MongoDB Connection Error:
```
❌ MongoDB connection error: authentication failed
```
**Fix:** Check MongoDB credentials and IP whitelist

### JWT_SECRET Missing:
```
Error: JWT_SECRET not configured
```
**Fix:** Add JWT_SECRET to Render environment variables

### Validation Error:
```
Registration error: ValidationError: ...
```
**Fix:** Check the specific validation error message

## Step 6: Verify API URL Configuration

Check `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`:

```swift
private static let renderBackendURL = "https://gofit-ai-live-healthy-1.onrender.com/api"
```

Make sure:
- URL matches your Render backend URL
- No trailing slashes (except `/api`)
- URL is accessible (test in browser)

## Step 7: Network Debugging

If you see network errors, check:

1. **iOS Simulator vs Physical Device:**
   - Simulator can access `localhost` and external URLs
   - Physical device needs external URL (like Render)

2. **Firewall/Security:**
   - Ensure your network allows HTTPS connections
   - Check if corporate firewall is blocking requests

3. **SSL Certificate:**
   - Render uses valid SSL certificates
   - If you see certificate errors, check device date/time

## Still Having Issues?

If you've checked all the above:

1. **Share the exact error message** from:
   - Xcode console (look for `❌ Registration error:`)
   - The error shown in the app UI

2. **Test the backend directly** using curl (see Step 3)

3. **Check Render service status:**
   - Service should show "Live" status
   - No recent deployment failures
   - Environment variables are all set

4. **Verify MongoDB Atlas:**
   - Cluster is running
   - Connection string is correct
   - IP whitelist includes `0.0.0.0/0` (for Render)

