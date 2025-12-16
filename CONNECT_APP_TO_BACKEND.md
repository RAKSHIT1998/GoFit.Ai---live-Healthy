# Connect iOS App to Backend

## The Error
"A server with the specified hostname could not be found" means the app can't reach the backend server.

## Solution Options

### Option 1: Use Your Render Deployment (Recommended)

If you've deployed to Render, update the app to use your Render URL:

1. **Get your Render service URL:**
   - Go to Render Dashboard → Your Service
   - Copy the URL (e.g., `https://gofit-ai-backend.onrender.com`)

2. **Update `EnvironmentConfig.swift`:**
   ```swift
   private static let renderBackendURL = "https://your-service-name.onrender.com/api"
   ```
   Replace `your-service-name` with your actual Render service name.

3. **For DEBUG builds, you can also use Render:**
   In `EnvironmentConfig.swift`, change:
   ```swift
   #if DEBUG
   // Use Render backend
   return renderBackendURL
   // Or use local: return "http://localhost:3000/api"
   #endif
   ```

---

### Option 2: Run Backend Locally

If you want to test with a local backend:

1. **Start the backend server:**
   ```bash
   cd backend
   npm install  # If not already done
   npm start
   ```

   The server should start on `http://localhost:3000`

2. **Verify it's running:**
   ```bash
   curl http://localhost:3000/health
   ```
   Should return: `{"status":"ok","timestamp":"..."}`

3. **For iOS Simulator:**
   - The app is already configured to use `http://localhost:3000/api`
   - Just make sure the backend is running

4. **For Physical iOS Device:**
   - Find your Mac's IP address:
     ```bash
     ifconfig | grep "inet " | grep -v 127.0.0.1
     ```
   - Update `EnvironmentConfig.swift`:
     ```swift
     #if DEBUG
     return "http://192.168.1.XXX:3000/api"  // Replace XXX with your Mac's IP
     #endif
     ```
   - Make sure your Mac's firewall allows connections on port 3000

---

## Quick Fix Steps

### If Using Render:

1. Open `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`
2. Find `renderBackendURL` and update it with your Render URL
3. Rebuild the app

### If Running Locally:

1. Open Terminal
2. Navigate to backend: `cd backend`
3. Start server: `npm start`
4. Make sure you see: `🚀 Server running on port 3000`
5. Try the app again

---

## Verify Connection

After updating, test the connection:

1. **Test backend health:**
   - Local: `curl http://localhost:3000/health`
   - Render: `curl https://your-service.onrender.com/health`

2. **Check app logs:**
   - Look for network errors in Xcode console
   - Should see successful API calls

---

## Common Issues

### "Connection refused"
- Backend isn't running
- Wrong port number
- Firewall blocking connection

### "Hostname not found"
- Wrong URL in `EnvironmentConfig.swift`
- Render service is sleeping (free tier)
- Network connectivity issue

### "SSL/TLS error" (on Render)
- Make sure you're using `https://` not `http://`
- Render provides HTTPS automatically

---

## Current Configuration

The app is currently set to:
- **DEBUG mode:** `http://localhost:3000/api` (local backend)
- **RELEASE mode:** Your Render URL (update `renderBackendURL`)

To switch between local and Render in DEBUG mode, just comment/uncomment the return statement in `EnvironmentConfig.swift`.

