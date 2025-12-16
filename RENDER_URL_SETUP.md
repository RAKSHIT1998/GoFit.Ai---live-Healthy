# Setting Up Your Render Backend URL

## Step 1: Find Your Render Service URL

1. **Go to Render Dashboard:**
   - Visit: https://dashboard.render.com
   - Log in to your account

2. **Find Your Web Service:**
   - Click on "Services" in the left menu
   - Find your backend service (the one you deployed)
   - Click on it to open the service details

3. **Copy the URL:**
   - At the top of the service page, you'll see the URL
   - It will look like: `https://gofit-ai-backend.onrender.com`
   - Copy this entire URL

## Step 2: Update EnvironmentConfig.swift

1. **Open the file:**
   - In Xcode, navigate to: `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`

2. **Find this line:**
   ```swift
   private static let renderBackendURL = "https://YOUR-SERVICE-NAME.onrender.com/api"
   ```

3. **Replace with your actual URL:**
   ```swift
   private static let renderBackendURL = "https://gofit-ai-backend.onrender.com/api"
   ```
   - Replace `gofit-ai-backend` with your actual service name
   - Make sure to keep `/api` at the end
   - Make sure to use `https://` (not `http://`)

## Step 3: Verify Your Backend is Running

Before testing the app, make sure your Render service is running:

1. **Check Render Dashboard:**
   - Your service should show "Live" status
   - If it shows "Sleeping" (free tier), click "Manual Deploy" or wait for it to wake up

2. **Test the Health Endpoint:**
   - Open your browser or use curl:
   ```bash
   curl https://your-service-name.onrender.com/health
   ```
   - Should return: `{"status":"ok","timestamp":"..."}`

## Step 4: Rebuild and Test

1. **Clean Build Folder:**
   - In Xcode: Product → Clean Build Folder (Shift + Cmd + K)

2. **Rebuild:**
   - Product → Build (Cmd + B)

3. **Run the App:**
   - Product → Run (Cmd + R)
   - Try creating an account or logging in

## Troubleshooting

### "Hostname not found"
- Double-check the URL in `EnvironmentConfig.swift`
- Make sure you're using `https://` not `http://`
- Verify the service name is correct (case-sensitive)

### "Connection timeout"
- Your Render service might be sleeping (free tier)
- Wake it up by visiting the URL in a browser
- Or upgrade to a paid plan for always-on service

### "SSL/TLS error"
- Make sure you're using `https://` not `http://`
- Render provides HTTPS automatically

### Service is "Sleeping"
- Free tier services sleep after 15 minutes of inactivity
- First request after sleep takes ~30 seconds to wake up
- Consider upgrading to "Starter" plan ($7/month) for always-on service

## Example Configuration

Here's what a correctly configured `EnvironmentConfig.swift` looks like:

```swift
import Foundation

struct EnvironmentConfig {
    // Your actual Render URL
    private static let renderBackendURL = "https://gofit-ai-backend.onrender.com/api"
    
    static var apiBaseURL: String {
        #if DEBUG
        return renderBackendURL
        #else
        return renderBackendURL
        #endif
    }
    // ... rest of the code
}
```

## Quick Checklist

- [ ] Found your Render service URL
- [ ] Updated `renderBackendURL` in `EnvironmentConfig.swift`
- [ ] Added `/api` at the end of the URL
- [ ] Using `https://` (not `http://`)
- [ ] Verified backend is running (health check works)
- [ ] Rebuilt the app in Xcode
- [ ] Tested the connection

---

**Need Help?** If you can't find your Render URL or need assistance, check your Render dashboard or contact support.

