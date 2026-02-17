# 🚀 Quick Deployment Reference

## One-Command Deploy

```bash
git push origin main
```
Render auto-deploys from GitHub push!

---

## 🔑 Environment Variables (Render Dashboard)

```env
JWT_SECRET=88cff1d65c68bab07aea0daa8292b0b4
MONGODB_URI=mongodb+srv://rakshitbargotra_db_user:Admin9858@cluster0.3ia87nv.mongodb.net/gofitai?retryWrites=true&w=majority
OPENAI_API_KEY=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
NODE_ENV=production
REDIS_ENABLED=false
ALLOWED_ORIGINS=*
```

---

## ✅ Quick Test

```bash
# 1. Health Check
curl https://gofit-ai-backend.onrender.com/health

# 2. WebSocket Test
wscat -c "wss://gofit-ai-backend.onrender.com/socket.io/?EIO=4&transport=websocket"

# 3. Register User
curl -X POST https://gofit-ai-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123!","username":"test"}'
```

---

## 📱 iOS App Update

**Change this:**
```swift
// Production URL
private let baseURL = "https://gofit-ai-backend.onrender.com"
```

---

## 🎯 What's Working

✅ REST API (all endpoints)  
✅ WebSocket real-time notifications  
✅ Friend requests (instant)  
✅ Challenge invitations (instant)  
✅ Challenge score updates (live)  
✅ Achievement notifications  
✅ Auto-reconnection  
✅ JWT authentication  
✅ MongoDB database  
✅ CORS configured  

---

## 📊 Expected Results

| Test | Expected |
|------|----------|
| Health Check | `{"status":"ok"}` |
| WebSocket | Connection established |
| Register | User created |
| Login | JWT token returned |
| Friend Request | <2 sec notification |
| Challenge Invite | <2 sec notification |

---

## 🐛 If Something Breaks

1. **Check Render logs** → Dashboard → Your Service → Logs
2. **Verify env vars** → Dashboard → Your Service → Environment
3. **Check MongoDB** → Atlas → Network Access (allow 0.0.0.0/0)
4. **Test locally first** → `cd backend && npm start`

---

## 📚 Full Documentation

- **Setup**: [PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md)
- **Testing**: [WEBSOCKET_TESTING_GUIDE.md](WEBSOCKET_TESTING_GUIDE.md)
- **Status**: [PRODUCTION_READY_STATUS.md](PRODUCTION_READY_STATUS.md)

---

**Ready to Deploy?** → `git push origin main` 🚀
