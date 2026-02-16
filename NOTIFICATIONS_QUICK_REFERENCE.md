# Notifications Quick Reference Guide

## 🎯 What's New

Notifications are now **enabled by default** when users first launch the GoFit app. Users can easily disable them in settings if they prefer.

---

## ⚙️ For Users

### Enable/Disable All Notifications
1. Open GoFit app
2. Tap **Profile** tab (bottom right)
3. Scroll to **Account** section
4. Toggle **Notifications** switch
   - **ON** (green) = Get all reminders
   - **OFF** (gray) = No notifications

### Control Specific Reminders
When notifications are enabled, you'll see:
- 🍴 **Meal Reminders** - Breakfast, lunch, dinner, snack
- 💧 **Water Reminders** - Stay hydrated throughout day
- 🏃 **Workout Reminders** - Morning and evening

Toggle each individually to customize which reminders you get.

### Check Notification Status
- Open ProfileView → Account section
- Toggle will show current status
- Green = notifications active
- Gray = notifications disabled

---

## 👨‍💻 For Developers

### Access Notification Service
```swift
let notificationService = NotificationService.shared

// Check if notifications are enabled
if notificationService.notificationsEnabled {
    print("Notifications are active")
}

// Get status of specific reminders
print("Meals: \(notificationService.mealRemindersEnabled)")
print("Water: \(notificationService.waterRemindersEnabled)")
print("Workouts: \(notificationService.workoutRemindersEnabled)")
```

### Enable/Disable All Notifications
```swift
// Turn all notifications on
NotificationService.shared.enableAllNotifications()

// Turn all notifications off
NotificationService.shared.disableAllNotifications()
```

### Update Individual Reminders
```swift
// Update specific reminder types
NotificationService.shared.updateMealReminders(true)
NotificationService.shared.updateWaterReminders(false)
NotificationService.shared.updateWorkoutReminders(true)
```

### Observe Notification Changes
```swift
@StateObject private var notifications = NotificationService.shared

// These will automatically update when user changes settings
notifications.notificationsEnabled       // true/false
notifications.mealRemindersEnabled       // true/false
notifications.waterRemindersEnabled      // true/false
notifications.workoutRemindersEnabled    // true/false
```

### Bind to UI
```swift
// In SwiftUI view
Toggle("Notifications", isOn: $notifications.notificationsEnabled)

// Will automatically save to UserDefaults
```

---

## 📱 Default Notification Schedule

### Meal Reminders (when enabled)
- 🌅 **8:00 AM** - Breakfast reminder
- 🌤️ **12:30 PM** - Lunch reminder  
- 🥗 **3:00 PM** - Snack reminder
- 🍽️ **7:00 PM** - Dinner reminder

### Water Reminders (when enabled)
- Every 2 hours from 8 AM to 8 PM
- **8 AM, 10 AM, 12 PM, 2 PM, 4 PM, 6 PM, 8 PM**

### Workout Reminders (when enabled)
- 💪 **7:00 AM** - Morning workout motivation
- 🏋️ **6:00 PM** - Evening fitness reminder

---

## 🔧 How It Works

### First App Launch
1. App detects this is first launch
2. Automatically requests notification permission
3. Sets all notification toggles to ON
4. Schedules reminders for today
5. Saves preference to device

### On Every App Open
1. App loads saved notification preferences
2. Checks if user has authorized notifications
3. Reschedules reminders if they're enabled
4. Ready to send notifications at scheduled times

### When User Changes Settings
1. User toggles notification in ProfileView
2. Preference immediately saved
3. Notifications rescheduled or cleared
4. Next app launch restores this preference

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Not getting notifications | Check Settings → Notifications → GoFit is enabled in iOS |
| Settings not saving | Try force quit app and reopen |
| Only some reminders appearing | Check individual toggles in ProfileView |
| Notifications all disappeared | Check master "Notifications" toggle is ON |

---

## 📊 Implementation Details

**Files Modified:**
- `Services/NotificationService.swift` - Core notification engine
- `Features/Authentication/ProfileView.swift` - Settings UI
- `Services/AppLogger.swift` - Logging of preference changes

**Storage:**
- UserDefaults keys: `notificationsEnabled`, `mealRemindersEnabled`, etc.
- First-launch tracked with: `gofit_notif_initialized`

**Permission:**
- Uses iOS `UNUserNotificationCenter`
- Auto-requests on first launch
- User can change in iOS Settings → Notifications

---

## 💡 Key Features

✅ **Enabled by Default** - Users get reminders without setup
✅ **Opt-Out** - Users can disable anytime in settings
✅ **Flexible Control** - Enable/disable specific reminder types
✅ **Persistent** - Settings saved across app restarts
✅ **Smart Scheduling** - AI-generated personalized content
✅ **Battery Efficient** - Only schedules when enabled
✅ **Fallback Messages** - Works even if AI API unavailable

---

## 🎓 Common Questions

### Q: Why do I get notifications on first launch?
A: Notifications are enabled by default to keep you engaged with your health goals. You can easily turn them off in settings.

### Q: Do my notification preferences save?
A: Yes! Whatever you set in ProfileView will be remembered even after closing the app.

### Q: Can I get different reminders?
A: Yes! Turn off the main Notifications toggle, or fine-tune individual reminder types.

### Q: What if I don't have notifications enabled on my phone?
A: Go to iOS Settings → Notifications → Find GoFit and enable it to allow the app to send notifications.

### Q: Are reminders the same every day?
A: Meal and water reminders have AI-generated personalized messages that vary based on your progress and preferences.

---

## 📞 Support

For issues with notifications:
1. Check this guide's troubleshooting section
2. Verify iOS notification settings for GoFit
3. Check app notification logs in ProfileView → Export Data
4. Look for "🔔 Notification Settings Updated" in logs
