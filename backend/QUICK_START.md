# Quick Start Guide - Backend Setup

Your API keys have been configured! Here's how to get started:

## ✅ Already Configured

- ✅ MongoDB connection string
- ✅ OpenAI API key
- ✅ .env file created
- ✅ .gitignore configured (your keys are safe)

## 🚀 Start the Backend

1. **Install dependencies:**
```bash
cd backend
npm install
```

2. **Start the server:**
```bash
npm run dev
```

The server will start on `http://localhost:3000`

## ⚠️ Still Need to Configure

### AWS S3 (for image storage)

You have two options:

**Option 1: AWS S3**
1. Create an AWS account
2. Create an S3 bucket named `gofit-ai-meals`
3. Create IAM user with S3 access
4. Add credentials to `.env`:
   ```
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-east-1
   ```

**Option 2: DigitalOcean Spaces (Cheaper alternative)**
1. Create DigitalOcean account
2. Create a Space
3. Use S3-compatible API
4. Update `.env` with Spaces credentials

**Option 3: Local Storage (for development)**
- You can modify the photo upload route to save locally
- Not recommended for production

### Redis (Optional - for background jobs)

For now, the app works without Redis. If you want background job processing:

```bash
# Install Redis (macOS)
brew install redis
brew services start redis
```

### Apple In-App Purchase

Only needed when you're ready to test subscriptions:
1. Go to App Store Connect
2. Create your app
3. Get the shared secret
4. Add to `.env`

## 🧪 Test the Backend

1. **Health check:**
```bash
curl http://localhost:3000/health
```

2. **Test MongoDB connection:**
The server will automatically connect when it starts. Check the console for:
```
✅ MongoDB connected
```

3. **Test OpenAI:**
The OpenAI key will be used when you upload a food photo. You can test it by:
- Starting the iOS app
- Taking a photo of food
- The backend will use OpenAI to analyze it

## 📱 Connect iOS App

Update `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`:

```swift
static var apiBaseURL: String {
    #if DEBUG
    // For simulator:
    return "http://localhost:3000/api"
    // For physical device, use your Mac's IP:
    // return "http://192.168.1.XXX:3000/api"
    #else
    return "https://api.gofit.ai/api"
    #endif
}
```

**To find your Mac's IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

## 🔒 Security Notes

- ✅ `.env` is in `.gitignore` - your keys won't be committed
- ⚠️ Change `JWT_SECRET` to a random string in production
- ⚠️ Never share your `.env` file
- ⚠️ Use environment variables in production (not .env file)

## 🐛 Troubleshooting

**MongoDB connection fails:**
- Check your internet connection
- Verify the connection string in `.env`
- Make sure your IP is whitelisted in MongoDB Atlas

**OpenAI API errors:**
- Verify the API key is correct
- Check your OpenAI account has credits
- Ensure the key has access to GPT-4 Vision API

**Server won't start:**
- Make sure all dependencies are installed: `npm install`
- Check port 3000 is not in use
- Look at error messages in console

## ✅ Next Steps

1. ✅ Backend is ready to use
2. ⏭️ Set up S3 for image storage (or use local storage for now)
3. ⏭️ Test with iOS app
4. ⏭️ Deploy to production when ready

---

**Your backend is configured and ready to use!** 🎉

