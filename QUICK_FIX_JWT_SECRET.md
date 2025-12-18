# 🚨 QUICK FIX: JWT_SECRET Error

## The Problem
```
Error: JWT_SECRET not configured
```

Your Render backend is missing the `JWT_SECRET` environment variable.

## The Solution (5 Minutes)

### Step 1: Generate JWT_SECRET
I've generated one for you:
```
wd5Esdj1x/GjxG//4QZ31KIvYL0TpgFmpg13XR1mmPc=
```

**Or generate your own:**
```bash
openssl rand -base64 32
```

### Step 2: Add to Render
1. Go to: https://dashboard.render.com
2. Click on your service: `gofit-ai-live-healthy-1`
3. Click **"Environment"** in the left sidebar
4. Click **"Add Environment Variable"**
5. Add these variables:

#### Required Variables:
```
Key: JWT_SECRET
Value: wd5Esdj1x/GjxG//4QZ31KIvYL0TpgFmpg13XR1mmPc=
```

```
Key: MONGODB_URI
Value: mongodb+srv://rakshitbargotra_db_user:Admin9858@cluster0.3ia87nv.mongodb.net/gofitai?retryWrites=true&w=majority
```

```
Key: OPENAI_API_KEY
Value: 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
```

```
Key: NODE_ENV
Value: production
```

```
Key: PORT
Value: 3000
```

```
Key: REDIS_ENABLED
Value: false
```

### Step 3: Save and Redeploy
1. Click **"Save Changes"** after adding each variable
2. Render will automatically redeploy
3. Wait 2-3 minutes for deployment to complete

### Step 4: Test
Try registering again in your app. The error should be gone!

## Visual Guide

```
Render Dashboard
  └─ Your Service (gofit-ai-live-healthy-1)
      └─ Environment Tab
          └─ Add Environment Variable
              ├─ Key: JWT_SECRET
              │   Value: [paste generated secret]
              ├─ Key: MONGODB_URI
              │   Value: [your MongoDB URI]
              └─ ... (add other variables)
```

## After Adding Variables

1. ✅ Variables are saved
2. ✅ Service automatically redeploys
3. ✅ Check logs to verify startup
4. ✅ Test registration/login

## Still Not Working?

1. **Check variable names**: Must be exact (case-sensitive)
   - ✅ `JWT_SECRET` (correct)
   - ❌ `jwt_secret` (wrong)
   - ❌ `JWT_SECRET ` (extra space)

2. **Check variable values**: No extra spaces
   - ✅ `wd5Esdj1x/GjxG//4QZ31KIvYL0TpgFmpg13XR1mmPc=`
   - ❌ ` wd5Esdj1x/GjxG//4QZ31KIvYL0TpgFmpg13XR1mmPc= ` (spaces)

3. **Redeploy manually**: 
   - Service → Manual Deploy → Deploy latest commit

4. **Check logs**:
   - Service → Logs tab
   - Look for startup messages
   - Should NOT see "JWT_SECRET not configured"

## Test Command

After fixing, test with:
```bash
curl -X POST https://gofit-ai-live-healthy-1.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"testpass123"}'
```

Should return:
```json
{
  "accessToken": "eyJhbGc...",
  "user": { ... }
}
```

Instead of:
```json
{
  "message": "JWT_SECRET not configured"
}
```

