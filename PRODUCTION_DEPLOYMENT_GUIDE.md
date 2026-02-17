# 🚀 Production Deployment Checklist - Render

## ✅ Pre-Deployment Verification

### Backend Status
- [x] Socket.IO installed (v4.8.3)
- [x] WebSocket service implemented
- [x] All routes have WebSocket emits
- [x] Friend request real-time notifications
- [x] Challenge invitation real-time notifications
- [x] Challenge score update real-time notifications
- [x] ES6 modules configured (type: "module")
- [x] Express server wrapped with HTTP server for Socket.IO

### Environment Variables Required

Copy these to **Render Dashboard → Environment**:

```env
# Required - Core
JWT_SECRET=88cff1d65c68bab07aea0daa8292b0b4
MONGODB_URI=mongodb+srv://rakshitbargotra_db_user:Admin9858@cluster0.3ia87nv.mongodb.net/gofitai?retryWrites=true&w=majority
NODE_ENV=production
PORT=10000

# Required - AI Features  
OPENAI_API_KEY=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

# Optional - Redis (Disabled for now)
REDIS_ENABLED=false

# Optional - AWS S3 (If using image uploads)
AWS_ACCESS_KEY_ID=your-access-key-if-needed
AWS_SECRET_ACCESS_KEY=your-secret-key-if-needed
AWS_REGION=us-east-1
S3_BUCKET_NAME=gofit-ai-meals

# Optional - Apple IAP
APPLE_SHARED_SECRET=0c401df645b84cbd949f34a68d706ff9
APPLE_APP_STORE_CONNECT_API_KEY_ID=AM9B5Z682V
APPLE_IN_APP_PURCHASE_KEY_ID=2WR55LJR4K
APPLE_BUNDLE_ID=com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy

# Required - CORS
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://gofit.ai
```

---

## 🔧 Render Dashboard Setup

### Step 1: Create Web Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository: `RAKSHIT1998/GoFit.Ai---live-Healthy`
4. Configure:
   - **Name**: `gofit-ai-backend`
   - **Region**: Choose closest to users
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free (or Starter for better performance)

### Step 2: Add Environment Variables

In **Environment** tab, add each variable from above:

```
Key: JWT_SECRET
Value: 88cff1d65c68bab07aea0daa8292b0b4
```

Repeat for all variables listed above.

### Step 3: Deploy

1. Click **"Create Web Service"**
2. Wait for deployment (~2-5 minutes)
3. Check logs for:
   ```
   ✅ MongoDB connected successfully
   ✅ WebSocket server initialized
   🚀 Server running on port 10000
   🔌 WebSocket server ready for real-time connections
   ```

---

## 🧪 Post-Deployment Testing

### 1. Health Check

Test the API is responding:

```bash
curl https://gofit-ai-backend.onrender.com/api/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-02-17T..."
}
```

### 2. WebSocket Connection Test

Install wscat globally:
```bash
npm install -g wscat
```

Test WebSocket connection:
```bash
wscat -c "wss://gofit-ai-backend.onrender.com/socket.io/?EIO=4&transport=websocket"
```

Expected output:
```
Connected (press CTRL+C to quit)
< 0{"sid":"...","upgrades":[],"pingInterval":25000,"pingTimeout":60000}
```

Send ping (type `2` and press Enter):
```
> 2
< 3
```

### 3. API Endpoint Tests

**Register a test user:**
```bash
curl -X POST https://gofit-ai-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "username": "testuser",
    "full_name": "Test User"
  }'
```

**Login:**
```bash
curl -X POST https://gofit-ai-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

Save the token from response.

**Test authenticated endpoint:**
```bash
curl https://gofit-ai-backend.onrender.com/api/friends \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. WebSocket Real-Time Test

With two devices/browsers:

1. **Device A**: Login as User A, send friend request to User B
2. **Device B**: Should receive instant notification (<2 seconds)

If notification appears instantly → ✅ WebSocket working in production!

---

## 📱 iOS App Configuration

Update the backend URL in your iOS app for production:

### Option 1: Hardcode Production URL

In `NetworkManager.swift` or wherever baseURL is defined:

```swift
private let baseURL = "https://gofit-ai-backend.onrender.com"
```

### Option 2: Environment-Based Configuration

```swift
#if DEBUG
    private let baseURL = "http://localhost:3000"
#else
    private let baseURL = "https://gofit-ai-backend.onrender.com"
#endif
```

### Option 3: User-Configurable

Keep the current UserDefaults approach and set it on first launch:

```swift
if UserDefaults.standard.string(forKey: "backendURL") == nil {
    UserDefaults.standard.set("https://gofit-ai-backend.onrender.com", forKey: "backendURL")
}
```

---

## 🔍 Monitoring & Debugging

### View Live Logs

In Render Dashboard:
1. Select your service
2. Click **"Logs"** tab
3. Enable auto-scroll

Look for:
- ✅ Successful connections
- 📡 WebSocket events
- ❌ Errors or warnings

### Common Issues & Solutions

#### Issue: "Cannot find module"
**Solution**: Ensure all imports use `.js` extension (ES6 modules)
```javascript
import wsService from './services/websocketService.js';  // ✅ Good
import wsService from './services/websocketService';     // ❌ Bad
```

#### Issue: WebSocket connection fails
**Solution**: 
- Check CORS settings in `ALLOWED_ORIGINS`
- Ensure using `wss://` (not `ws://`) for HTTPS backend
- Verify Socket.IO version matches on client and server

#### Issue: MongoDB connection timeout
**Solution**:
- Whitelist Render's IP in MongoDB Atlas Network Access
- Or use "Allow access from anywhere" (0.0.0.0/0) for testing

#### Issue: Environment variables not loading
**Solution**:
- Double-check variable names (case-sensitive)
- Redeploy after adding new variables
- Check for typos in Render dashboard

---

## 🚀 Deployment Commands

### Manual Deployment

From your local machine:

```bash
cd /path/to/GoFit.Ai-live-Healthy
git add .
git commit -m "Production-ready deployment"
git push origin main
```

Render auto-deploys on push to `main` branch.

### Trigger Redeploy

If you need to redeploy without code changes:
1. Go to Render Dashboard
2. Select your service
3. Click **"Manual Deploy"** → **"Deploy latest commit"**

---

## 📊 Performance Optimization

### Enable Render's Redis (Optional)

For better WebSocket scaling:

1. In Render Dashboard, create a Redis instance
2. Copy the Internal Redis URL
3. Update environment variables:
   ```
   REDIS_ENABLED=true
   REDIS_HOST=your-redis-url.render.com
   REDIS_PORT=6379
   ```

4. Update `backend/server.js` to use Redis adapter for Socket.IO:
   ```javascript
   import { createAdapter } from '@socket.io/redis-adapter';
   import { createClient } from 'redis';
   
   const pubClient = createClient({ url: process.env.REDIS_URL });
   const subClient = pubClient.duplicate();
   
   await pubClient.connect();
   await subClient.connect();
   
   io.adapter(createAdapter(pubClient, subClient));
   ```

### Health Check Endpoint

Already implemented in `server.js`:

```javascript
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

Configure in Render:
- **Health Check Path**: `/api/health`

---

## 🎯 Production Checklist

Before going live:

- [ ] All environment variables added to Render
- [ ] MongoDB Atlas allows Render IP (or 0.0.0.0/0)
- [ ] OPENAI_API_KEY is valid and has credits
- [ ] JWT_SECRET is strong and random
- [ ] ALLOWED_ORIGINS includes your production domain
- [ ] iOS app points to production URL
- [ ] Health check endpoint responds
- [ ] WebSocket connection successful
- [ ] Test user registration works
- [ ] Test login works
- [ ] Test friend request sends real-time notification
- [ ] Test challenge invitation sends real-time notification
- [ ] Logs show no errors
- [ ] SSL certificate valid (Render provides automatically)

---

## 📚 Resources

- **Render Docs**: https://render.com/docs/web-services
- **Socket.IO Docs**: https://socket.io/docs/v4/
- **MongoDB Atlas**: https://cloud.mongodb.com/
- **OpenAI API**: https://platform.openai.com/

---

## 🆘 Support

If you encounter issues:

1. Check Render logs first
2. Test API endpoints with curl/Postman
3. Verify environment variables are set correctly
4. Ensure MongoDB connection string is valid
5. Check Socket.IO connection from browser DevTools

---

**Deployment Date**: February 17, 2026  
**Status**: ✅ Production Ready  
**Backend URL**: `https://gofit-ai-backend.onrender.com`  
**WebSocket URL**: `wss://gofit-ai-backend.onrender.com`
