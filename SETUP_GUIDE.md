# GoFit.ai Setup Guide

Complete setup instructions for the GoFit.ai health tracking app.

## Prerequisites

### Required Software
- **Xcode 15+** - Download from Mac App Store
- **Node.js 18+** - Download from [nodejs.org](https://nodejs.org)
- **MongoDB** - Download from [mongodb.com](https://www.mongodb.com/try/download/community)
- **Redis** - Install via Homebrew: `brew install redis`
- **Git** - Usually pre-installed on macOS

### Required Accounts
- **OpenAI Account** - Get API key from [platform.openai.com](https://platform.openai.com)
- **AWS Account** - For S3 storage (or use DigitalOcean Spaces)
- **Apple Developer Account** - For App Store deployment ($99/year)

## Step 1: Backend Setup

### 1.1 Install MongoDB

```bash
# macOS (using Homebrew)
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# Verify installation
mongosh
```

### 1.2 Install Redis

```bash
# macOS (using Homebrew)
brew install redis
brew services start redis

# Verify installation
redis-cli ping
# Should return: PONG
```

### 1.3 Configure Backend

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env file with your credentials
nano .env  # or use your preferred editor
```

**Required .env variables:**
```env
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/gofitai
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
OPENAI_API_KEY=sk-your-openai-api-key
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
S3_BUCKET_NAME=gofit-ai-meals
REDIS_HOST=localhost
REDIS_PORT=6379
APPLE_SHARED_SECRET=your-apple-shared-secret
APPLE_BUNDLE_ID=com.gofitai.app
```

### 1.4 Start Backend Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The server should start on `http://localhost:3000`

**Test the server:**
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

## Step 2: iOS App Setup

### 2.1 Open Project in Xcode

```bash
# Open the Xcode project
open "GoFit.Ai - live Healthy.xcodeproj"
```

### 2.2 Configure API Endpoint

Edit `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`:

```swift
static var apiBaseURL: String {
    #if DEBUG
    return "http://localhost:3000/api"  // For simulator
    // For physical device, use your Mac's IP: "http://192.168.1.100:3000/api"
    #else
    return "https://api.gofit.ai/api"  // Production
    #endif
}
```

**Note:** For physical iOS device testing:
- Find your Mac's IP: `ifconfig | grep "inet "`
- Update the DEBUG URL to use your Mac's IP address
- Ensure your Mac's firewall allows connections on port 3000

### 2.3 Add Capabilities

1. Select the project in Xcode navigator
2. Select the app target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add:
   - **HealthKit** - Required for health data
   - **In-App Purchase** - Required for subscriptions
   - **Camera** - Required for meal scanning
   - **Photo Library** - Required for photo selection

### 2.4 Configure Info.plist

Add these keys to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>GoFit.ai needs camera access to take photos of your meals.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>GoFit.ai needs photo library access to choose meal photos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>GoFit.ai needs to save images for your meal logs.</string>
<key>NSHealthShareUsageDescription</key>
<string>GoFit.ai needs access to your health data to sync steps, heart rate, and calories.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>GoFit.ai needs to write weight and water intake data to Health.</string>
```

### 2.5 Configure Signing

1. Select your development team in "Signing & Capabilities"
2. Xcode will automatically create provisioning profiles
3. Ensure bundle identifier matches your Apple Developer account

### 2.6 Build and Run

1. Select a target device (simulator or physical device)
2. Press `Cmd + R` to build and run
3. The app should launch on your device

## Step 3: Apple Watch App (Optional)

### 3.1 Add Watch Target

1. File → New → Target
2. Select "watchOS" → "App"
3. Name it "GoFit Watch App"
4. Choose "SwiftUI" interface

### 3.2 Configure Watch App

1. Add HealthKit capability to Watch app
2. Set up Watch Connectivity framework
3. Implement Watch-specific features:
   - Steps display
   - Quick water logging
   - Fasting timer complication
   - Heart rate monitoring

### 3.3 Build Watch App

1. Select Watch scheme
2. Build and run on paired Apple Watch

## Step 4: Configure In-App Purchase

### 4.1 App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app (if not exists)
3. Go to "Features" → "In-App Purchases"
4. Create two subscriptions:
   - **Monthly Premium** - Product ID: `com.gofitai.premium.monthly`
   - **Yearly Premium** - Product ID: `com.gofitai.premium.yearly`
5. Configure pricing and 3-day free trial
6. Submit for review

### 4.2 Update Code

Product IDs are already configured in `PurchaseManager.swift`. Ensure they match your App Store Connect products.

## Step 5: Testing

### 5.1 Test Authentication

1. Launch the app
2. Complete onboarding
3. Sign up with test email
4. Verify login works

### 5.2 Test Food Scanning

1. Tap "Scan Meal"
2. Take a photo or select from library
3. Verify AI analysis returns results
4. Save meal entry

### 5.3 Test HealthKit

1. Grant HealthKit permissions
2. Verify steps and calories sync
3. Check data appears in dashboard

### 5.4 Test Subscriptions

1. Navigate to paywall
2. Use sandbox test account
3. Complete purchase flow
4. Verify subscription status updates

## Step 6: Production Deployment

### 6.1 Backend Deployment

**Option A: Heroku**
```bash
heroku create gofit-backend
heroku addons:create mongolab
heroku addons:create rediscloud
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=your-production-secret
# ... set all other env vars
git push heroku main
```

**Option B: AWS/DigitalOcean**
- Set up EC2/Droplet
- Install Node.js, MongoDB, Redis
- Use PM2 for process management
- Set up Nginx reverse proxy
- Configure SSL with Let's Encrypt

### 6.2 iOS App Deployment

1. Update `EnvironmentConfig.swift` with production API URL
2. Archive the app in Xcode (Product → Archive)
3. Upload to App Store Connect
4. Submit for App Store review

## Troubleshooting

### Backend Issues

**MongoDB connection failed:**
- Verify MongoDB is running: `brew services list`
- Check connection string in .env

**Redis connection failed:**
- Verify Redis is running: `redis-cli ping`
- Check REDIS_HOST and REDIS_PORT in .env

**OpenAI API errors:**
- Verify API key is correct
- Check API usage limits
- Ensure sufficient credits

### iOS App Issues

**Network requests fail:**
- Check API URL in EnvironmentConfig
- Verify backend is running
- For physical device, use Mac's IP address
- Check firewall settings

**HealthKit not working:**
- Verify HealthKit capability is added
- Check Info.plist permissions
- Grant permissions in Settings → Privacy → Health

**In-App Purchase not working:**
- Use sandbox test account
- Verify product IDs match App Store Connect
- Check subscription status in Settings → App Store

## Next Steps

1. **Customize Branding**
   - Update app icon
   - Modify colors in Constants.swift
   - Add custom illustrations

2. **Add Features**
   - Implement Apple Watch app
   - Add advanced analytics
   - Create admin dashboard

3. **Testing**
   - Write unit tests
   - Add UI tests
   - Test on multiple devices

4. **App Store Submission**
   - Prepare screenshots
   - Write app description
   - Submit for review

## Support

For issues or questions:
- Check README.md for general information
- Review backend/README.md for API docs
- Open an issue on GitHub

---

Happy coding! 🚀

