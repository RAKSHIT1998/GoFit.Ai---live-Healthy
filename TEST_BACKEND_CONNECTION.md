# Test Backend Connection

## ✅ Configuration Status

Your app is now configured to use:
**`https://gofit-ai-live-healthy-1.onrender.com/api`**

All services are using this URL:
- ✅ `NetworkManager` → Uses `EnvironmentConfig.apiBaseURL`
- ✅ `AuthService` → Uses `EnvironmentConfig.apiBaseURL`
- ✅ All API calls will go to your Render backend

## 🧪 How to Test

### 1. Test Backend Health (Browser/curl)

Open in browser or run:
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

**Expected response:**
```json
{"status":"ok","timestamp":"2025-12-16T..."}
```

### 2. Test in iOS App

1. **Clean and Rebuild:**
   - In Xcode: `Shift + Cmd + K` (Clean)
   - Then: `Cmd + B` (Build)
   - Then: `Cmd + R` (Run)

2. **Try Creating an Account:**
   - Open the app
   - Fill in the registration form
   - Tap "Create Account"
   - Should connect successfully (no "server not found" error)

3. **Check Xcode Console:**
   - Look for network requests
   - Should see successful API calls
   - No connection errors

## 🔍 Verify Connection

### What to Look For:

**✅ Success Indicators:**
- Account creation works
- Login works
- No "server not found" errors
- No "hostname not found" errors
- API responses in Xcode console

**❌ If Still Getting Errors:**

1. **"Hostname not found"**
   - Double-check the URL in `EnvironmentConfig.swift`
   - Make sure it's `https://` not `http://`
   - Verify service name is correct

2. **"Connection timeout"**
   - Render service might be sleeping (free tier)
   - Wait 30 seconds and try again
   - Or visit the health endpoint to wake it up

3. **"SSL/TLS error"**
   - Make sure using `https://`
   - Check Render service is running

## 📱 Current API Endpoints

Your app will call these endpoints on your Render backend:

- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Login
- `POST /api/photo/analyze` - Analyze meal photo
- `POST /api/meals/save` - Save meal
- `GET /api/meals/history` - Get meal history
- `POST /api/health/sync` - Sync HealthKit data
- `POST /api/subscriptions/verify` - Verify subscription
- And more...

## 🎯 Quick Test Checklist

- [ ] Backend health endpoint works (`/health`)
- [ ] App builds without errors
- [ ] Can create account in app
- [ ] No network errors in Xcode console
- [ ] API calls show in Render logs

## 🚀 Next Steps

Once connection is verified:
1. Test all features (meal scanning, health sync, etc.)
2. Monitor Render logs for any errors
3. Test subscription flow
4. Verify all API endpoints work

---

**Your app should now be connected to your Render backend!** 🎉

If you're still seeing errors, check:
1. Render dashboard - is service "Live"?
2. Xcode console - what's the exact error?
3. Network tab - are requests being made?

