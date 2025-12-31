# Backend Connection Check Guide

## Backend URL
Your backend is deployed at: **https://gofit-ai-live-healthy-1.onrender.com**

## Quick Health Check

### 1. Test Backend Health Endpoint
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

Expected response:
```json
{"status":"ok","timestamp":"2024-..."}
```

### 2. Test Root Endpoint
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/
```

Should return API information with available endpoints.

## Required Environment Variables on Render

Make sure these are set in your Render dashboard:

### Required:
- ✅ `JWT_SECRET` - Secret key for JWT tokens
- ✅ `MONGODB_URI` - MongoDB connection string
- ✅ `GEMINI_API_KEY` - Google Gemini API key (get from https://aistudio.google.com/app/apikey)

### Optional:
- `AWS_ACCESS_KEY_ID` - For S3 image storage (optional)
- `AWS_SECRET_ACCESS_KEY` - For S3 image storage (optional)
- `S3_BUCKET_NAME` - S3 bucket name (optional)
- `AWS_REGION` - AWS region (default: us-east-1)
- `REDIS_URL` - Redis connection URL (optional, for background jobs)
- `NODE_ENV` - Set to "production" for production

## Common Issues

### "AI service unavailable" Error

This error can occur due to:

1. **Missing GEMINI_API_KEY**
   - Check Render dashboard → Environment → Verify `GEMINI_API_KEY` is set
   - Get your free API key: https://aistudio.google.com/app/apikey

2. **Invalid API Key**
   - Verify the key is correct (no extra spaces)
   - Check if the key is active in Google AI Studio

3. **Backend Not Running**
   - Check Render dashboard → Logs
   - Look for startup errors
   - Verify MongoDB connection is working

4. **Network Issues**
   - Check if backend URL is accessible
   - Verify CORS settings allow your app

### Testing Backend Endpoints

#### 1. Health Check
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

#### 2. Test Photo Analysis (requires auth token)
```bash
# First, get auth token by logging in
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Then use token for photo analysis
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/photo/analyze \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "photo=@food.jpg"
```

## Frontend Configuration

The app is configured to use:
```
https://gofit-ai-live-healthy-1.onrender.com/api
```

This is set in: `GoFit.Ai - live Healthy/Core/EnvironmentConfig.swift`

## Debugging Steps

1. **Check Render Logs**
   - Go to Render dashboard → Your service → Logs
   - Look for errors related to:
     - Gemini API calls
     - Missing environment variables
     - Database connection issues

2. **Verify Environment Variables**
   - Render dashboard → Environment
   - Ensure all required variables are set
   - No typos in variable names

3. **Test API Key**
   - Go to https://aistudio.google.com/app/apikey
   - Verify your API key is active
   - Check usage limits

4. **Check Backend Response**
   - Use browser DevTools or Postman
   - Test the `/api/photo/analyze` endpoint
   - Check the actual error message returned

## Expected Error Messages

### If GEMINI_API_KEY is missing:
```json
{
  "message": "Food recognition service is not configured. Please set GEMINI_API_KEY environment variable. Get your free API key at https://aistudio.google.com/app/apikey",
  "error": "Gemini API key missing"
}
```

### If API key is invalid:
```json
{
  "message": "Food recognition service authentication failed. Please check GEMINI_API_KEY configuration.",
  "error": "Gemini API key issue"
}
```

### If service is busy:
```json
{
  "message": "Food recognition service is currently busy. Please try again in a moment.",
  "error": "Rate limit exceeded"
}
```

## Next Steps

1. ✅ Verify `GEMINI_API_KEY` is set in Render
2. ✅ Check Render logs for startup errors
3. ✅ Test health endpoint
4. ✅ Verify MongoDB connection
5. ✅ Test photo analysis endpoint with valid token

