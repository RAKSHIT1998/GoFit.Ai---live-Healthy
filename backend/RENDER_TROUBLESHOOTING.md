# Render Deployment Troubleshooting Guide

## Common Errors and Solutions

### 1. Redis Connection Error: `ECONNREFUSED 127.0.0.1:6379`

**Problem:** The app is trying to connect to Redis on localhost, which doesn't exist on Render.

**Solutions:**

#### Option A: Disable Redis (Recommended for initial deployment)
Add this environment variable in Render:
```
REDIS_ENABLED=false
```

The app will work without Redis. Background job processing will be disabled, but all core features will work.

#### Option B: Use Render Redis Service
1. Create a Redis service in Render dashboard
2. Add these environment variables:
   ```
   REDIS_HOST=your-redis-service-name.onrender.com
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   ```

#### Option C: Use External Redis (Upstash, Redis Cloud)
1. Sign up for a free Redis service (Upstash, Redis Cloud, etc.)
2. Get connection details
3. Add environment variables:
   ```
   REDIS_HOST=your-redis-host
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   ```

---

### 2. MongoDB Authentication Error: `bad auth : authentication failed`

**Problem:** MongoDB credentials are incorrect or user doesn't have proper permissions.

**Solutions:**

1. **Verify MongoDB URI Format:**
   ```
   mongodb+srv://username:password@cluster.mongodb.net/database?retryWrites=true&w=majority
   ```
   - Make sure username and password are URL-encoded (special characters replaced)
   - Example: `password@123` → `password%40123`

2. **Check MongoDB Atlas User:**
   - Go to MongoDB Atlas → Database Access
   - Verify username and password
   - Make sure user has "Read and write to any database" permissions
   - Or create a new user with proper permissions

3. **Verify Network Access:**
   - Go to MongoDB Atlas → Network Access
   - Add IP address: `0.0.0.0/0` (allows all IPs, including Render)
   - Or add Render's IP ranges (check Render docs)

4. **Test Connection String:**
   - Copy your MONGODB_URI from Render environment variables
   - Test it in MongoDB Compass or mongo shell
   - If it works there, the issue might be with special characters

5. **Common Issues:**
   - Password contains special characters that need URL encoding:
     - `@` → `%40`
     - `#` → `%23`
     - `$` → `%24`
     - `%` → `%25`
     - `&` → `%26`
     - `+` → `%2B`
     - `=` → `%3D`
   - Example: If password is `P@ss#123`, use `P%40ss%23123` in URI

---

### 3. Environment Variables Not Set

**Problem:** App crashes because required environment variables are missing.

**Required Variables:**
```
NODE_ENV=production
PORT=10000
MONGODB_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
OPENAI_API_KEY=your_openai_key
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
S3_BUCKET_NAME=your_bucket_name
ALLOWED_ORIGINS=https://your-frontend.com
```

**Optional Variables:**
```
REDIS_ENABLED=false  # Set to false to disable Redis
REDIS_HOST=your_redis_host
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
APPLE_SHARED_SECRET=your_apple_secret
APPLE_BUNDLE_ID=com.gofitai.app
```

---

### 4. Build Fails

**Problem:** npm install fails or build errors occur.

**Solutions:**
1. Check Node.js version in Render (should be 18 or 20)
2. Verify package.json is correct
3. Check build logs for specific errors
4. Make sure all dependencies are listed in package.json

---

### 5. App Crashes on Start

**Problem:** App starts but immediately crashes.

**Solutions:**
1. Check runtime logs in Render dashboard
2. Verify all environment variables are set
3. Test MongoDB connection separately
4. Check if port is correct (Render uses PORT env var automatically)

---

### 6. Health Check Fails

**Problem:** Render health checks fail.

**Solutions:**
1. Verify `/health` endpoint is accessible
2. Check that server is listening on correct port
3. Ensure MongoDB connection doesn't block server startup

---

## Quick Fix Checklist

When deploying to Render:

- [ ] All required environment variables are set
- [ ] MongoDB URI is correct and URL-encoded
- [ ] MongoDB user has proper permissions
- [ ] MongoDB network access allows Render IPs (0.0.0.0/0)
- [ ] Redis is disabled (REDIS_ENABLED=false) or properly configured
- [ ] CORS origins are set correctly
- [ ] Build command: `npm install`
- [ ] Start command: `npm start`
- [ ] Health check endpoint works: `/health`

---

## Testing Your Deployment

1. **Health Check:**
   ```
   curl https://your-service.onrender.com/health
   ```
   Should return: `{"status":"ok","timestamp":"..."}`

2. **Test API Endpoint:**
   ```
   curl https://your-service.onrender.com/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123"}'
   ```

3. **Check Logs:**
   - Go to Render dashboard → Your service → Logs
   - Look for connection messages:
     - ✅ MongoDB connected successfully
     - ⚠️ Redis disabled or not configured (if Redis is disabled)

---

## Getting Help

If you're still having issues:

1. Check Render logs for specific error messages
2. Verify all environment variables are set correctly
3. Test MongoDB connection string separately
4. Check MongoDB Atlas dashboard for connection attempts
5. Review this troubleshooting guide for your specific error

