# Test Backend Registration Endpoint

Use this guide to test if the registration endpoint is working correctly.

## Step 1: Test Backend Health

First, verify the backend is running:

```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

Expected response:
```json
{"status":"ok","timestamp":"..."}
```

## Step 2: Test Registration Endpoint

Test the registration endpoint directly:

```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "TestPass123!"
  }' \
  -v
```

The `-v` flag will show:
- HTTP status code
- Response headers
- Response body
- Any connection errors

## Step 3: Check Common Issues

### Issue 1: CORS Error
If you see CORS errors, check:
- Backend CORS configuration allows your origin
- `ALLOWED_ORIGINS` environment variable in Render

### Issue 2: MongoDB Connection
Check Render logs for:
```
❌ MongoDB connection error: ...
```

### Issue 3: JWT_SECRET Missing
Check Render logs for:
```
Error: JWT_SECRET not configured
```

### Issue 4: Rate Limiting
If you see 429 errors, you've hit the rate limit. Wait 15 minutes.

## Step 4: Check iOS App Logs

In Xcode console, look for:
```
❌ Registration error: [actual error message]
Response: [response body]
```

This will show the exact error from the backend.

## Step 5: Verify Environment Variables on Render

Make sure these are set in Render:
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Strong random string (min 32 chars)
- `JWT_EXPIRES_IN` - Optional (defaults to "7d")
- `ALLOWED_ORIGINS` - Optional (defaults to "*")

## Common Error Responses

### 400 Bad Request
```json
{
  "message": "Name, email, and password are required"
}
```
→ Check that all fields are being sent

### 400 Bad Request
```json
{
  "message": "User already exists"
}
```
→ Email is already registered

### 500 Internal Server Error
```json
{
  "message": "Registration failed",
  "error": "..."
}
```
→ Check the `error` field for details. Common causes:
- MongoDB connection issue
- JWT_SECRET not configured
- Validation error

