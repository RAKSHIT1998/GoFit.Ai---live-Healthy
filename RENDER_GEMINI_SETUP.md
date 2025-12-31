# Render Gemini API Setup - Quick Guide

## ✅ You've Set GEMINI_API_KEY - Next Steps

### 1. **Restart Your Render Service**
After adding environment variables, you MUST restart the service:
- Go to Render Dashboard → Your Service
- Click "Manual Deploy" → "Deploy latest commit"
- OR wait for auto-deploy if you just pushed changes

### 2. **Verify the Key is Loaded**
Check Render logs after restart:
```
✅ GEMINI_API_KEY is configured (AIzaSyABC...)
```

If you see:
```
⚠️  GEMINI_API_KEY is NOT configured
```
Then the key wasn't loaded properly.

### 3. **Common Issues**

#### Issue: Key Not Being Read
**Solution:**
- Make sure there are NO quotes around the key value
- Correct: `GEMINI_API_KEY=AIzaSyABC123...`
- Wrong: `GEMINI_API_KEY="AIzaSyABC123..."`

#### Issue: Service Still Shows "AI service unavailable"
**Check:**
1. Render Logs → Look for error messages
2. Verify the key format (should start with `AIza`)
3. Make sure service was restarted after adding the key

#### Issue: Model Not Found Error
**Solution:**
The code now tries multiple models:
- First: `gemini-pro`
- Fallback: `gemini-1.5-pro`
- Fallback: `gemini-1.5-flash`

Check logs to see which model is being used.

### 4. **Test the Backend**

#### Test Health Endpoint:
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
```

#### Test Photo Analysis (requires auth):
1. Login to get a token
2. Upload a photo to `/api/photo/analyze`
3. Check the response

### 5. **Check Logs for Errors**

In Render Dashboard → Logs, look for:
- ✅ `Starting Google Gemini analysis` - Good!
- ✅ `GEMINI_API_KEY is configured` - Good!
- ❌ `GEMINI_API_KEY is NOT configured` - Key not loaded
- ❌ `Google Gemini API error` - Check the error details

### 6. **Get Your API Key**

If you need a new key:
1. Go to: https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (starts with `AIza`)
4. Add to Render: `GEMINI_API_KEY=your_key_here`
5. **Restart the service**

### 7. **Verify Everything Works**

After restart, the logs should show:
```
🚀 Server running on port 10000
📱 Environment: production
✅ Required environment variables loaded
✅ GEMINI_API_KEY is configured (AIzaSy...)
```

Then test photo analysis - it should work! 🎉

## Still Having Issues?

1. **Check Render Logs** - Most errors are logged there
2. **Verify API Key** - Make sure it's active in Google AI Studio
3. **Check Service Status** - Make sure the service is running
4. **Test Health Endpoint** - Verify backend is accessible

