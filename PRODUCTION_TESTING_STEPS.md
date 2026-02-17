# Production Testing Steps 🚀

## ✅ Deployment Status

**Backend Pushed**: Commit `a06cddd` to GitHub  
**Render Deployment**: Auto-deploying now (2-5 minutes)  
**Production URL**: https://gofit-ai-live-healthy-1.onrender.com  
**WebSocket URL**: wss://gofit-ai-live-healthy-1.onrender.com

---

## 1️⃣ Verify Backend Deployment (Wait 2-5 minutes)

### Check Render Dashboard
1. Go to https://dashboard.render.com
2. Navigate to your service: "gofit-ai-live-healthy-1"
3. Check "Events" tab for deployment status
4. Wait for "Deploy succeeded" message

### Test Health Endpoint
```bash
curl https://gofit-ai-live-healthy-1.onrender.com/health
# Expected: {"status":"ok"}
```

### Check WebSocket Connection
```bash
# Install wscat if needed: npm install -g wscat

wscat -c "wss://gofit-ai-live-healthy-1.onrender.com/socket.io/?EIO=4&transport=websocket"
# Expected: Connected message with Socket.IO handshake
```

---

## 2️⃣ Test iOS App with Production Backend

### Build & Run iOS App
1. Open Xcode
2. Select iPhone simulator
3. Build and run (Cmd+R)
4. iOS app now uses production URLs:
   - REST API: `https://gofit-ai-live-healthy-1.onrender.com`
   - WebSocket: `wss://gofit-ai-live-healthy-1.onrender.com`

### Verify Connection
1. Launch app
2. Check console for:
   ```
   ✅ WebSocket connected
   ✅ Backend health check: ok
   ```

---

## 3️⃣ Test Real-Time Friend Requests ⚡️

### Setup (2 Devices Required)
- **Device A**: iPhone simulator or physical device
- **Device B**: Another simulator or physical device

### Test Steps

#### Step 1: Login on Both Devices
- **Device A**: Login as User 1
- **Device B**: Login as User 2

#### Step 2: Send Friend Request (Device A)
1. Navigate to Friends tab
2. Search for User 2
3. Tap "Add Friend"
4. **Watch Device B** 👀

#### Step 3: Verify Instant Notification (Device B)
✅ **Expected Result** (Within 2 seconds):
- 🔔 Notification banner appears at top
- Shows: "Friend Request from [User 1 Name]"
- Auto-dismisses after 4 seconds
- Friend request appears in list

#### Step 4: Accept Friend Request (Device B)
1. Tap on friend request
2. Accept request
3. **Watch Device A** 👀

#### Step 5: Verify Acceptance Notification (Device A)
✅ **Expected Result** (Within 2 seconds):
- 🔔 Notification banner appears
- Shows: "[User 2 Name] accepted your friend request"
- Friend appears in friends list

---

## 4️⃣ Test Challenge Invitations ⚡️

### Step 1: Create Challenge (Device A)
1. Navigate to Challenges tab
2. Create new challenge
3. Invite User 2
4. **Watch Device B** 👀

### Step 2: Verify Challenge Notification (Device B)
✅ **Expected Result** (Instant):
- 🏆 Notification banner appears
- Shows: "Challenge Invitation from [User 1 Name]"
- Challenge details visible

### Step 3: Update Challenge Score (Device B)
1. Accept challenge
2. Complete activity
3. **Watch Device A** 👀

### Step 4: Verify Score Update (Device A)
✅ **Expected Result** (Instant):
- 📊 Leaderboard updates automatically
- No manual refresh needed
- Score changes visible in real-time

---

## 5️⃣ Performance Verification

### Expected Latency
- Friend Request Notification: **< 500ms**
- Challenge Invitation: **< 500ms**
- Score Update: **< 1 second**
- WebSocket Reconnection: **< 3 seconds**

### Monitor Console Logs
**iOS Console (Xcode):**
```
✅ WebSocket connected
📬 Received: friendRequestReceived
🔔 Showing banner: Friend Request from...
```

**Backend Logs (Render Dashboard):**
```
✅ WebSocket client connected: user:12345
📤 Emitting friendRequest to user:67890
✅ Message delivered
```

---

## 6️⃣ Test Offline/Reconnection Behavior

### Disconnect Test
1. Turn off WiFi on Device A
2. Wait 5 seconds
3. Turn WiFi back on
4. **Expected**: WebSocket reconnects automatically within 3 seconds

### Background Test
1. Send app to background
2. Wait 10 seconds
3. Bring app to foreground
4. **Expected**: WebSocket reconnects, missed notifications appear

---

## 🐛 Troubleshooting

### Issue: "Connection Failed"
**Solution:**
```bash
# Check backend is running
curl https://gofit-ai-live-healthy-1.onrender.com/health

# Check Render logs
# Go to Render Dashboard → Logs tab
```

### Issue: "WebSocket not connecting"
**Check iOS Console for:**
```
❌ WebSocket error: ...
```

**Common Causes:**
1. JWT token expired → Re-login
2. Backend not running → Check Render dashboard
3. CORS issue → Check backend CORS configuration
4. Network issue → Check internet connection

### Issue: "Notifications not appearing"
**Check:**
1. Notification permissions granted?
2. WebSocket connected? (Check console)
3. Correct user ID in request?
4. Backend emitting events? (Check Render logs)

---

## 📊 Success Criteria

| Feature | Status | Latency |
|---------|--------|---------|
| Backend Health | ✅ | < 100ms |
| WebSocket Connect | ✅ | < 2s |
| Friend Request | ✅ | < 500ms |
| Challenge Invite | ✅ | < 500ms |
| Score Update | ✅ | < 1s |
| Auto-reconnect | ✅ | < 3s |

---

## 🎉 You're Live!

Once all tests pass:
1. ✅ Backend deployed on Render
2. ✅ iOS app using production URLs
3. ✅ WebSocket real-time working
4. ✅ Sub-second notification delivery
5. ✅ Auto-reconnection working

**Next Steps:**
- Monitor Render logs for errors
- Test with real users
- Consider Redis for scaling beyond 1000 concurrent users
- Set up monitoring/alerts (optional)

---

## 🔗 Quick Links

- **Render Dashboard**: https://dashboard.render.com
- **Health Check**: https://gofit-ai-live-healthy-1.onrender.com/health
- **WebSocket Test**: `wscat -c wss://gofit-ai-live-healthy-1.onrender.com/socket.io/?EIO=4&transport=websocket`
- **iOS App Logs**: Xcode Console (Cmd+Shift+C)
- **Backend Logs**: Render Dashboard → Logs

---

**Ready to Test!** 🚀
