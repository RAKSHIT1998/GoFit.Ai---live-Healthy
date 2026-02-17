# 👥 Social Competition System - Architecture & Implementation

**Status:** Planning Phase  
**Date:** February 17, 2026

## 🎯 Feature Overview

Complete social & competition system allowing users to:
- ✅ Add and manage friends
- ✅ Share daily workout & meal logs
- ✅ Create personal & group challenges
- ✅ Compete on leaderboards
- ✅ Receive AI-generated competitive notifications
- ✅ Track progress against friends

## 📊 Data Models

### 1. Friend Relationship
```
User → Friends → User
├── Statuses: pending, accepted, blocked
├── CreatedAt: Timestamp
└── SharedData: meal_logs, workout_logs, daily_summary
```

### 2. Challenge/Competition
```
Challenge
├── ID: UUID
├── Type: personal_1v1, group, team
├── Metric: calories_burned, workouts_completed, steps, weight_lost, etc.
├── Duration: start_date, end_date
├── Participants: [User]
├── Leaderboard: rankings with scores
└── Rewards: badges, points, achievements
```

### 3. Activity Log (Sharable)
```
ActivityLog (extends existing logs)
├── SharedWith: [User] (list of friends with access)
├── Visibility: private, friends_only, public
├── CompetitionID: linked to challenge
└── Timestamp: when activity occurred
```

### 4. AI Notification
```
Notification
├── Type: friend_activity, challenge_update, milestone, leaderboard_change
├── AIGenerated: boolean
├── Content: AI-written message
├── Recipient: User
├── RelatedUser: Friend who triggered it
└── CreatedAt: Timestamp
```

## 🏗️ Backend Architecture

### New API Endpoints

#### Friends Management
```
POST   /api/friends/request/{friendId}          - Send friend request
GET    /api/friends/requests                    - Get pending requests
POST   /api/friends/accept/{friendId}           - Accept friend request
POST   /api/friends/reject/{friendId}           - Reject friend request
GET    /api/friends                             - Get all friends
POST   /api/friends/remove/{friendId}           - Remove friend
GET    /api/friends/search?q={query}            - Search users by username/email
```

#### Daily Log Sharing
```
POST   /api/logs/meal/share                     - Share meal log with friends
POST   /api/logs/workout/share                  - Share workout log with friends
GET    /api/logs/friends                        - Get shared logs from friends
POST   /api/logs/{logId}/visibility             - Update log visibility
```

#### Challenges & Competitions
```
POST   /api/challenges/create                   - Create new challenge
GET    /api/challenges                          - Get active challenges
GET    /api/challenges/{id}                     - Get challenge details
POST   /api/challenges/{id}/join                - Join public challenge
GET    /api/challenges/{id}/leaderboard         - Get leaderboard
POST   /api/challenges/{id}/invite              - Invite friend to challenge
POST   /api/challenges/group/create             - Create group challenge
```

#### AI Notifications
```
GET    /api/notifications                       - Get all notifications
POST   /api/notifications/read/{id}             - Mark as read
DELETE /api/notifications/{id}                  - Delete notification
```

## 💾 Database Schema

### Table: friends
```sql
CREATE TABLE friends (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    friend_id UUID NOT NULL,
    status ENUM('pending', 'accepted', 'blocked'),
    created_at TIMESTAMP,
    UNIQUE(user_id, friend_id),
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(friend_id) REFERENCES users(id)
);
```

### Table: challenges
```sql
CREATE TABLE challenges (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL,
    type ENUM('personal_1v1', 'group', 'team'),
    metric VARCHAR(100),  -- e.g., 'calories_burned', 'workouts'
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    status ENUM('active', 'completed', 'cancelled'),
    created_at TIMESTAMP,
    FOREIGN KEY(creator_id) REFERENCES users(id)
);
```

### Table: challenge_participants
```sql
CREATE TABLE challenge_participants (
    id UUID PRIMARY KEY,
    challenge_id UUID NOT NULL,
    user_id UUID NOT NULL,
    score DOUBLE,
    rank INT,
    joined_at TIMESTAMP,
    UNIQUE(challenge_id, user_id),
    FOREIGN KEY(challenge_id) REFERENCES challenges(id),
    FOREIGN KEY(user_id) REFERENCES users(id)
);
```

### Table: activity_logs (extends meal/workout logs)
```sql
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    type ENUM('meal', 'workout', 'daily_summary'),
    data JSONB,  -- flexible storage
    shared_with TEXT[],  -- array of user IDs
    visibility ENUM('private', 'friends_only', 'public'),
    challenge_id UUID,
    created_at TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(challenge_id) REFERENCES challenges(id)
);
```

### Table: notifications
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY,
    recipient_id UUID NOT NULL,
    type ENUM('friend_activity', 'challenge_update', 'milestone', 'leaderboard'),
    title VARCHAR(255),
    message TEXT,
    ai_generated BOOLEAN,
    related_user_id UUID,
    challenge_id UUID,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMP,
    FOREIGN KEY(recipient_id) REFERENCES users(id)
);
```

## 🎨 Frontend Components

### Views Needed

1. **FriendsView** - List friends, send requests
2. **FriendRequestsView** - Pending requests
3. **AddFriendView** - Search and add
4. **ChallengesView** - Browse active challenges
5. **ChallengeDetailView** - Challenge details & leaderboard
6. **CreateChallengeView** - Create new challenge
7. **CompetitionLeaderboardView** - Real-time leaderboard
8. **SharedLogsView** - View friend activity
9. **NotificationsView** - AI notifications
10. **SocialTabView** - Main social hub

### Components

- Friend Card (with status, add/remove button)
- Challenge Card (with progress, rank)
- Leaderboard Entry (with rank, score, trend)
- Notification Card (AI-generated message)
- Achievement Badge

## 🤖 AI Notification Generation

### Notification Types

1. **Friend Activity** (Daily)
   ```
   "🏃 Your friend Alex just completed a 45-minute workout! 
    They burned 520 calories on the treadmill. 
    You're still 180 calories ahead in today's challenge!"
   ```

2. **Milestone Achieved**
   ```
   "🎉 Your friend Sarah hit 5000 steps today! 
    Only 3000 more than yesterday. Keep pushing!"
   ```

3. **Leaderboard Change**
   ```
   "📊 You've dropped to 2nd place in the Weekly Challenge! 
    Alex is now leading with 3200 calories burned. 
    Can you catch up?"
   ```

4. **Challenge Update**
   ```
   "⏰ Only 2 days left in the 'March Marathon' challenge! 
    You're in 3rd place. Final push!"
   ```

### AI Message Generation
```python
def generate_competitive_notification(friend, action, context):
    templates = {
        "workout": [
            f"🏋️ Your friend {friend.name} just crushed a {action['type']} workout!",
            f"💪 {friend.name} is getting serious - {action['duration']}min {action['type']}",
            f"⚡ {friend.name} just burned {action['calories']} calories!"
        ],
        "meal": [
            f"🍽️ {friend.name} logged a nutritious meal",
            f"🥗 {friend.name} is staying on track with their nutrition"
        ],
        "milestone": [
            f"🎯 {friend.name} hit {action['milestone']} today!",
            f"🔥 {friend.name} reached a new personal best!"
        ]
    }
    
    # Select random template, inject context
    template = random.choice(templates[action_type])
    return template + contextual_comment(context)
```

## 📱 User Flow

### Adding a Friend
```
User
  ↓
Friends Tab → Search Friend
  ↓
Send Request
  ↓
Friend receives notification
  ↓
Friend Accept/Reject
  ↓
Connected (can see shared data)
```

### Creating a Challenge
```
User
  ↓
Challenges Tab → Create Challenge
  ↓
Select Type (1v1, Group, Team)
  ↓
Set Metric (calories, workouts, steps)
  ↓
Set Duration (start, end date)
  ↓
Invite Friends or make public
  ↓
Challenge starts
  ↓
Leaderboard updates in real-time
  ↓
Notifications sent to participants
```

### Daily Log Sharing
```
User logs meal/workout
  ↓
Option to share with friends
  ↓
Select visibility (private, friends, public)
  ↓
Friends see in "Shared Logs" tab
  ↓
AI notifications generated
  ↓
Contribute to challenge scores
```

## 🔔 Notification System Flow

```
User completes workout
  ↓
Activity saved & visibility set
  ↓
Check if activity shared with friends
  ↓
For each friend receiving notification:
    ├── Generate AI message
    ├── Calculate context (competition standing, trends)
    ├── Create notification record
    └── Send push notification
  ↓
Notification appears in app
  ↓
User sees: "Your friend completed 45-min run, you're still ahead!"
```

## 🎮 Gamification Elements

1. **Achievements/Badges**
   - "Social Butterfly" - 10 friends added
   - "Competitive Spirit" - Won 5 challenges
   - "Team Leader" - Created group challenge with 5+ people
   - "Consistency" - Never missed a day for 30 days

2. **Points & Ranks**
   - Earning points from challenges
   - Ranking system (Bronze, Silver, Gold, Platinum)
   - Leaderboard position

3. **Streaks**
   - Daily activity streak
   - Friend interaction streak
   - Challenge participation streak

## 🔐 Privacy & Security

1. **Data Sharing Controls**
   - Users choose what to share (meals, workouts, summary)
   - Visibility levels: private, friends_only, public
   - Can block users
   - Can revoke access anytime

2. **Authentication**
   - Only authenticated users can add friends
   - Friend requests require acceptance
   - Challenges are opt-in

3. **Data Protection**
   - Encrypt shared data in transit
   - Validate all access permissions
   - Audit logs for shared data access

## 📋 Implementation Phases

### Phase 1: Core Friends System (Week 1)
- [ ] Database setup
- [ ] Friend request API
- [ ] Friends list API
- [ ] FriendsView UI

### Phase 2: Log Sharing (Week 2)
- [ ] Share meal/workout APIs
- [ ] SharedLogsView
- [ ] Visibility controls

### Phase 3: Challenges (Week 3)
- [ ] Challenge creation API
- [ ] Leaderboard system
- [ ] ChallengesView UI
- [ ] Real-time updates

### Phase 4: AI Notifications (Week 4)
- [ ] Notification generation engine
- [ ] AI message templates
- [ ] NotificationsView
- [ ] Push notifications

### Phase 5: Polish & Gamification (Week 5)
- [ ] Achievements system
- [ ] Badges & rewards
- [ ] Performance optimization
- [ ] Testing & refinement

## 📊 Performance Considerations

1. **Real-time Updates**
   - Use WebSockets or Server-Sent Events for live leaderboard
   - Or use polling with 5-10 second intervals

2. **Database Optimization**
   - Index on (user_id, friend_id) for friends table
   - Index on (challenge_id, user_id) for participants
   - Cache leaderboards (update every 30 seconds)

3. **Notification Batching**
   - Batch AI notifications (send digest at specific times)
   - Don't send duplicate notifications
   - Rate limit to prevent notification spam

## 🎯 Success Metrics

- User engagement (% users with friends)
- Challenge participation rate
- Daily active challenges
- Notification open rate
- User retention (especially with social features)
- Competitive engagement (challenge completion)

## 🚀 Future Enhancements

1. **Team Competitions** - Multi-person teams with team leaders
2. **Seasonal Events** - Monthly/yearly challenges with leaderboards
3. **Rewards Integration** - Real rewards for winners
4. **Social Feed** - Activity feed showing friend progress
5. **Live Notifications** - Real-time updates (WebSocket)
6. **Video Sharing** - Share workout videos with form tips
7. **Challenge Templates** - Pre-built challenges (30-day workout, etc.)
8. **AI Coach** - Personalized tips based on competition standing
9. **Integration with Wearables** - Apple Watch, Fitbit sync
10. **Tournament Brackets** - March Madness style tournaments

---

**Next Step:** Implement Phase 1 (Backend: Friends System API)
