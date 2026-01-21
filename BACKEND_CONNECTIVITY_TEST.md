# Backend Connectivity Test Guide

## Current Backend Configuration

**Backend URL:** `https://gofit-ai-live-healthy-1.onrender.com/api`

Configured in: `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`

## Quick Connectivity Test

### Method 1: Test from Terminal

```bash
# Test health endpoint (no auth required)
curl https://gofit-ai-live-healthy-1.onrender.com/health

# Expected response:
# {"status":"ok","timestamp":"..."}
```

### Method 2: Test from Browser

1. Open browser
2. Navigate to: `https://gofit-ai-live-healthy-1.onrender.com/health`
3. Should see: `{"status":"ok","timestamp":"..."}`

### Method 3: Test from iOS App

1. **Run the app** in Xcode
2. **Check Xcode console** for API requests
3. **Look for:**
   - `🌐 API Request: GET https://gofit-ai-live-healthy-1.onrender.com/api/...`
   - Success or error messages

## Comprehensive Backend Test

### Step 1: Health Check

```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

**Expected:** `{"status":"ok","timestamp":"..."}`

**If fails:**
- Backend may be sleeping (Render free tier)
- Wait 30-60 seconds for cold start
- Check Render dashboard for service status

### Step 2: Test Authentication Endpoints

```bash
# Test registration endpoint (should return validation error without data)
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{}'

# Expected: Validation error (this is good - endpoint is working)
```

### Step 3: Test from iOS App

1. **Launch the app**
2. **Try to sign up** with a test account
3. **Check console logs:**
   ```
   🌐 API Request: POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register
   ```

4. **If connection fails, you'll see:**
   - Network error messages
   - Timeout errors
   - Server unavailable errors

## Common Issues & Solutions

### Issue 1: Backend is Sleeping (Render Free Tier)

**Symptoms:**
- First request takes 30-60 seconds
- Subsequent requests are fast
- Timeout errors on first request

**Solution:**
- Wait for cold start (30-60 seconds)
- Or upgrade to paid Render plan for always-on
- Or use local backend for development

### Issue 2: Connection Timeout

**Symptoms:**
- Request fails after 60 seconds
- "Network request failed" error

**Solution:**
- Check internet connection
- Verify backend URL is correct
- Check Render service status
- Try again after waiting

### Issue 3: 503 Service Unavailable

**Symptoms:**
- Error: "Service temporarily unavailable"
- Cloudflare error page

**Solution:**
- Backend may be restarting
- Wait a few minutes and try again
- Check Render dashboard

### Issue 4: 401 Unauthorized

**Symptoms:**
- "Authentication required" error
- After login, requests still fail

**Solution:**
- Token may be expired
- Try logging in again
- Check token is being saved correctly

### Issue 5: CORS Errors (if testing from web)

**Symptoms:**
- CORS policy errors in browser console

**Solution:**
- This is normal - iOS app doesn't have CORS restrictions
- Only affects browser-based testing

## Testing Checklist

### Basic Connectivity
- [ ] Health endpoint responds
- [ ] Backend URL is correct in code
- [ ] No network errors in console

### Authentication
- [ ] Registration works
- [ ] Login works
- [ ] Token is saved
- [ ] `/auth/me` endpoint works after login

### API Endpoints
- [ ] Meal photo upload works
- [ ] Meal history loads
- [ ] Health sync works
- [ ] Recommendations load
- [ ] Subscription verification works

### Error Handling
- [ ] Network errors are handled gracefully
- [ ] User sees friendly error messages
- [ ] App doesn't crash on network failures

## Debugging Tips

### Enable Debug Logging

The app already has debug logging enabled. Check Xcode console for:
```
🌐 API Request: GET https://gofit-ai-live-healthy-1.onrender.com/api/...
```

### Check Network Manager

The `NetworkManager` class handles all API requests:
- Location: `Services/NetworkManager+Auth.swift`
- Base URL: Set in `EnvironmentConfig.swift`
- Timeout: 60 seconds for regular requests, 90 seconds for photo uploads

### Test Individual Endpoints

You can test endpoints directly using curl:

```bash
# Health check
curl https://gofit-ai-live-healthy-1.onrender.com/health

# Register (will fail without proper data, but tests endpoint)
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test"}'
```

## Local Backend Testing (Alternative)

If Render backend is unreliable, you can use local backend:

1. **Update EnvironmentConfig.swift:**
```swift
static var apiBaseURL: String {
    #if DEBUG
    // For simulator:
    return "http://localhost:3000/api"
    // For physical device, use your Mac's IP:
    // return "http://192.168.1.XXX:3000/api"
    #else
    return "https://gofit-ai-live-healthy-1.onrender.com/api"
    #endif
}
```

2. **Start local backend:**
```bash
cd backend
npm run dev
```

3. **Find your Mac's IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

4. **Update URL** with your Mac's IP for physical device testing

## Production Backend

For production, ensure:
- [ ] Backend is deployed and running
- [ ] URL is correct in `EnvironmentConfig.swift`
- [ ] SSL certificate is valid (HTTPS)
- [ ] Backend can handle production load
- [ ] Monitoring is set up

## Current Status

**Backend URL:** `https://gofit-ai-live-healthy-1.onrender.com/api`

**Next Steps:**
1. Test health endpoint from terminal/browser
2. Test from iOS app (sign up/login)
3. Verify all endpoints work
4. Monitor for errors in production

The backend connectivity should work automatically when the app runs. Check Xcode console for any connection issues!
