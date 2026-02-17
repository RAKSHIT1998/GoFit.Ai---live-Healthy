# Quick Start Guide - Phases 2-5 System

## 🚀 Getting Started

### 1. Run Database Migration

```bash
cd backend
node scripts/phase-2-5-migration.js
```

Expected output:
```
✅ Phase 2-5 database migration completed successfully
```

### 2. Start the Backend Server

```bash
npm run dev
# OR
npm start
```

### 3. Verify Routes Are Registered

Visit the root endpoint to confirm all routes are loaded:
```
GET http://localhost:3000/
```

Look for these endpoints in the response:
- `/api/logs` - Log sharing
- `/api/challenges` - Challenges
- `/api/notifications` - Notifications  
- `/api/gamification` - Gamification

## 📋 Feature Overview

### Phase 2: Log Sharing
Users can share their meals and workouts with:
- **Private**: Only visible to user
- **Friends Only**: Shared with accepted friends
- **Public**: Visible to all users
- **Selective**: Shared with specific friends

**Points**: 10 points per share

### Phase 3: Challenges
Create or join competitions with:
- **Personal Challenges**: Individual goals
- **Group Challenges**: Compete with friends
- **Leaderboards**: Real-time rankings
- **Score Updates**: Automatic rank calculation

**Points**: 25 for creating, 10 for joining

### Phase 4: Notifications
AI-generated competitive messages including:
- Milestone achievements
- Friend progress alerts
- Challenge status updates
- Streak encouragement
- Competitive pressure notifications

### Phase 5: Gamification
- **Points**: Earned through actions (share, create challenge, etc.)
- **Badges**: 6 milestone-based badges (100 → 5000 points)
- **Achievements**: 8 action-based achievements
- **Streaks**: Track consecutive activity days
- **Leaderboard**: Global rankings by total points

## 🧪 Testing the API

### 1. Share a Meal Log
```bash
curl -X POST http://localhost:3000/api/logs/meal/share \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mealId": 1,
    "visibility": "friends_only",
    "sharedWith": [2, 3]
  }'
```

### 2. Create a Challenge
```bash
curl -X POST http://localhost:3000/api/challenges/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "July Step Challenge",
    "description": "Walk 100,000 steps this month",
    "challengeType": "group",
    "metric": "steps",
    "targetValue": 100000,
    "duration": 30,
    "isGroupChallenge": true,
    "invitedUsers": [2, 3, 4]
  }'
```

### 3. Join a Challenge
```bash
curl -X POST http://localhost:3000/api/challenges/1/join \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Get Gamification Stats
```bash
curl -X GET http://localhost:3000/api/gamification/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Get Notifications
```bash
curl -X GET http://localhost:3000/api/notifications \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📱 Frontend Integration

### Using LogSharingService
```swift
@StateObject private var logService = LogSharingService()

// Share a meal
try await logService.shareMealLog(
  mealId: 123,
  visibility: "friends_only",
  sharedWith: [2, 3, 4]
)

// Get activity feed
try await logService.getActivityFeed()
```

### Using ChallengeService
```swift
@StateObject private var challengeService = ChallengeService()

// Create challenge
try await challengeService.createChallenge(
  name: "July Step Challenge",
  description: "100k steps",
  type: "group",
  metric: "steps",
  targetValue: 100000,
  durationDays: 30,
  isGroupChallenge: true,
  invitedUsers: [2, 3, 4]
)

// Get leaderboard
try await challengeService.getLeaderboard(challengeId: 1)
```

### Using GamificationService
```swift
@StateObject private var gamService = GamificationService()

// Get stats
try await gamService.getStats()

// Get badges
try await gamService.getBadges()

// Get leaderboard
try await gamService.getLeaderboard(limit: 50)
```

### Using NotificationService
```swift
@StateObject private var notifService = NotificationService()

// Get notifications
try await notifService.getNotifications(limit: 30)

// Get unread count
try await notifService.getUnreadCount()

// Mark as read
try await notifService.markAsRead(notificationId: 1)
```

## 🔍 Database Queries

### Check migration was successful
```sql
-- List all new tables
SELECT * FROM information_schema.tables 
WHERE table_name IN (
  'activity_logs', 'challenges', 'challenge_participants',
  'social_notifications', 'gamification_points', 'badges',
  'user_badges', 'achievements', 'user_achievements', 'user_streaks'
);

-- Check badges were seeded
SELECT * FROM badges;

-- Check achievements were seeded
SELECT * FROM achievements;
```

### View user's points
```sql
SELECT 
  u.username,
  SUM(gp.points) as total_points,
  COUNT(*) as action_count
FROM users u
LEFT JOIN gamification_points gp ON u.id = gp.user_id
GROUP BY u.id, u.username
ORDER BY total_points DESC;
```

### View active challenges
```sql
SELECT 
  c.name,
  c.challenge_type,
  COUNT(cp.user_id) as participant_count,
  c.end_date
FROM challenges c
LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
WHERE c.is_active = true AND c.end_date > NOW()
GROUP BY c.id
ORDER BY c.created_at DESC;
```

## 🆘 Troubleshooting

### Migration fails
- Ensure PostgreSQL is running
- Check database connection in `.env`
- Verify tables don't already exist (safe to re-run)

### Routes not loading
- Check server imports in `server.js`
- Verify route files exist in `/backend/routes/`
- Check console for import errors

### Swift compilation errors
- Ensure models match API responses
- Check APIConfig.baseURL is correct
- Verify AuthService.getToken() returns valid JWT

### Bearer token errors
- Confirm token is valid and not expired
- Check Authorization header format: `Bearer <token>`
- Test with known-good token from login

## 📊 Database Schema Overview

```
Users
├── activity_logs (Phase 2)
├── challenges (Phase 3)
│   ├── challenge_participants
│   └── challenge_invitations
├── social_notifications (Phase 4)
├── gamification_points (Phase 5)
├── user_badges
├── user_achievements
└── user_streaks
```

## 🎯 Success Metrics

- ✅ All 4 route files created and serving
- ✅ 11 database tables created with indexes
- ✅ 600+ lines of backend code
- ✅ 20+ Swift data models
- ✅ 4 service layers for frontend
- ✅ Complete gamification system
- ✅ AI notification generation
- ✅ Real-time leaderboards

## 📞 Support

If you encounter issues:
1. Check server console for errors
2. Verify database migration completed
3. Confirm all route files exist
4. Check token validity
5. Review error responses from API

---

**Status**: Ready for testing and frontend integration
**Last Updated**: Phases 2-5 Complete
