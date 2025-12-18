# Render Environment Variables Setup Guide

## Problem
Your backend is failing with: `JWT_SECRET not configured`

This means the environment variables are not set in your Render deployment.

## Solution: Set Environment Variables in Render

### Step 1: Go to Your Render Dashboard
1. Log in to [Render Dashboard](https://dashboard.render.com)
2. Navigate to your service: `gofit-ai-live-healthy-1`
3. Click on your service to open its settings

### Step 2: Add Environment Variables
1. Click on **"Environment"** tab in the left sidebar
2. Click **"Add Environment Variable"** button
3. Add each variable one by one (see list below)

### Step 3: Required Environment Variables

#### 🔐 Critical (Required for Authentication)
```
JWT_SECRET=<generate-a-strong-random-string-min-32-characters>
JWT_EXPIRES_IN=7d
```

**To generate a secure JWT_SECRET**, run this command in your terminal:
```bash
openssl rand -base64 32
```

Or use this online generator: https://www.lastpass.com/features/password-generator

**Your JWT_SECRET**:
```
JWT_SECRET=88cff1d65c68bab07aea0daa8292b0b4
```

#### 🗄️ Database (Required)
```
MONGODB_URI=mongodb+srv://rakshitbargotra_db_user:Admin9858@cluster0.3ia87nv.mongodb.net/gofitai?retryWrites=true&w=majority
```

#### 🤖 OpenAI (Required for AI features)
```
OPENAI_API_KEY=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
```

#### ⚙️ Server Configuration
```
PORT=3000
NODE_ENV=production
```

#### 🔴 Redis (Optional - can disable if not using)
```
REDIS_ENABLED=false
```

Or if you have Redis:
```
REDIS_ENABLED=true
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
```

#### ☁️ AWS S3 (Optional - for image storage)
```
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
S3_BUCKET_NAME=gofit-ai-meals
```

#### 🍎 Apple (Optional - for in-app purchases)
```
APPLE_SHARED_SECRET=your-apple-shared-secret
APPLE_BUNDLE_ID=com.rakshit.Gofit.ai.GoFit-Ai-live-Healthy
```

#### 🌐 CORS (Optional)
```
ALLOWED_ORIGINS=https://your-frontend-domain.com
```

## Quick Setup Script

Copy and paste this into your terminal to generate a secure JWT_SECRET:

```bash
# Generate JWT_SECRET
echo "JWT_SECRET=$(openssl rand -base64 32)"
```

## Step-by-Step Instructions

### 1. Generate JWT_SECRET
```bash
openssl rand -base64 32
```

Copy the output (it will look like: `aB3xK9mP2qR7vN4wL8tY5uI1oE6hG0jF3dS9aZ2xC5vB8nM1qW4eR7tY0uI3oP6`)

### 2. Add to Render
1. Go to Render Dashboard → Your Service → Environment
2. Click "Add Environment Variable"
3. Key: `JWT_SECRET`
4. Value: Paste the generated secret
5. Click "Save Changes"

### 3. Add Other Required Variables
Repeat for:
- `MONGODB_URI` (your MongoDB connection string)
- `OPENAI_API_KEY` (your OpenAI API key)
- `NODE_ENV=production`
- `PORT=3000`

### 4. Redeploy
After adding environment variables:
1. Render will automatically detect changes
2. Or manually trigger a redeploy: Service → Manual Deploy → Deploy latest commit

## Verification

After setting environment variables and redeploying, test:

```bash
# Test registration endpoint
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"testpass123"}'
```

You should get a response with `accessToken` instead of the JWT_SECRET error.

## Troubleshooting

### Still getting "JWT_SECRET not configured"?
1. ✅ Make sure you saved the environment variable in Render
2. ✅ Check the variable name is exactly `JWT_SECRET` (case-sensitive)
3. ✅ Make sure there are no extra spaces in the value
4. ✅ Redeploy the service after adding variables
5. ✅ Check Render logs to see if the variable is being read

### Check Render Logs
1. Go to your service in Render Dashboard
2. Click "Logs" tab
3. Look for startup messages
4. Check if environment variables are being loaded

### Common Issues

**Issue**: Variable not found after adding
- **Solution**: Make sure to redeploy after adding environment variables

**Issue**: Still getting 401 errors
- **Solution**: Check that JWT_SECRET is set correctly and service was redeployed

**Issue**: MongoDB connection errors
- **Solution**: Verify MONGODB_URI is correct and MongoDB Atlas allows connections from Render's IPs (0.0.0.0/0)

## Security Notes

⚠️ **IMPORTANT**:
- Never commit `.env` files to git
- Use strong, random JWT_SECRETs in production
- Rotate secrets regularly
- Don't share secrets publicly
- Use different secrets for development and production

## Current Status

Based on your error, you need to add at minimum:
- ✅ `JWT_SECRET` (CRITICAL - missing)
- ✅ `MONGODB_URI` (if not already set)
- ✅ `OPENAI_API_KEY` (if using AI features)
- ✅ `NODE_ENV=production`
- ✅ `PORT=3000`

After adding these, your authentication should work!

