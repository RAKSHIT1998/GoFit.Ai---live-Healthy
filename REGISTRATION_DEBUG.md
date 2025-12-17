# Registration Error Debugging Guide

If you're seeing "Registration failed" errors, follow these steps to identify and fix the issue.

## Step 1: Check Backend Status

First, verify your backend is running and accessible:

```bash
# Test if backend is reachable
curl https://gofit-ai-live-healthy.onrender.com/health

# Should return: {"status":"ok","timestamp":"..."}
```

If this fails, your backend is not running or not accessible.

## Step 2: Check Render Deployment Logs

1. Go to your Render dashboard
2. Click on your backend service
3. Go to "Logs" tab
4. Try to register an account from the app
5. Look for error messages in the logs

Common errors you might see:

### MongoDB Connection Error
```
❌ MongoDB connection error: authentication failed
```
**Fix:** 
- Check `MONGODB_URI` in Render environment variables
- Verify MongoDB credentials are correct
- Ensure IP whitelist includes `0.0.0.0/0` for Render

### JWT_SECRET Missing
```
Error: JWT_SECRET not configured
```
**Fix:**
- Add `JWT_SECRET` to Render environment variables
- Use a strong random string (minimum 32 characters)

### Validation Error
```
Registration error: ValidationError: ...
```
**Fix:**
- Check the specific validation error message
- Ensure all required fields are being sent from the app

## Step 3: Test Registration Endpoint Directly

Test the registration endpoint with curl:

```bash
curl -X POST https://gofit-ai-live-healthy.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

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

**Common error responses:**

1. **400 Bad Request:**
```json
{
  "message": "Name, email, and password are required"
}
```
→ Check that the app is sending all required fields

2. **400 Bad Request:**
```json
{
  "message": "User already exists"
}
```
→ Try with a different email address

3. **500 Internal Server Error:**
```json
{
  "message": "Registration failed",
  "error": "..."
}
```
→ Check the `error` field for details. Common causes:
   - MongoDB connection issue
   - JWT_SECRET not configured
   - Validation error in User model

## Step 4: Check iOS App Logs

The app now logs detailed error messages. To see them:

1. Open Xcode
2. Run the app on a device or simulator
3. Open the Console (View → Debug Area → Activate Console)
4. Try to register an account
5. Look for error messages starting with `❌ Registration error:`

The logs will show:
- HTTP status code
- Error message from backend
- Full response body (if available)

## Step 5: Verify Environment Variables on Render

Make sure these are set in Render:

1. **MONGODB_URI** - Your MongoDB Atlas connection string
2. **JWT_SECRET** - A strong random string (min 32 chars)
3. **JWT_EXPIRES_IN** - Optional (defaults to "7d")
4. **PORT** - Optional (defaults to 3000)

To check:
1. Go to Render dashboard
2. Select your backend service
3. Go to "Environment" tab
4. Verify all required variables are set

## Step 6: Common Issues and Fixes

### Issue: "Cannot reach server"
**Cause:** Backend URL is incorrect or backend is down
**Fix:** 
- Verify `EnvironmentConfig.swift` has correct URL
- Check Render dashboard to ensure service is running

### Issue: "User already exists"
**Cause:** Email is already registered
**Fix:** Use a different email or delete the user from MongoDB

### Issue: "Registration failed" (generic)
**Cause:** Backend error not properly surfaced
**Fix:**
- Check Render logs for actual error
- Verify MongoDB connection
- Check JWT_SECRET is set
- Look at iOS console logs for detailed error

### Issue: "Failed to decode server response"
**Cause:** Backend returned unexpected response format
**Fix:**
- Check backend logs
- Verify backend is returning `{ accessToken: "...", user: {...} }`
- Check if there's a CORS issue

## Step 7: Test with Different Credentials

Try registering with:
- Different email address
- Stronger password (8+ characters)
- Valid name field

## Still Having Issues?

If you've checked all the above and still can't register:

1. **Share the exact error message** from:
   - iOS app (shown in red text)
   - Xcode console logs
   - Render deployment logs

2. **Test the backend directly** using curl (see Step 3)

3. **Check MongoDB Atlas:**
   - Verify cluster is running
   - Check connection string is correct
   - Ensure IP whitelist includes `0.0.0.0/0`

4. **Verify Render service status:**
   - Service should show "Live" status
   - No recent deployment failures
   - Environment variables are all set

