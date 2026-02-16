# Notifications System - FAQ (Frequently Asked Questions)

## ❓ General Questions

### Q: Are notifications really enabled by default?
**A:** Yes! When a user opens the GoFit app for the first time, all notifications are enabled by default:
- Meal reminders (breakfast, lunch, dinner, snacks)
- Water reminders (every 2 hours)
- Workout reminders (morning and evening)

The user doesn't need to do anything—they start receiving reminders immediately after granting permission.

### Q: What if the user doesn't want notifications?
**A:** They can easily turn them off anytime:
1. Open GoFit app
2. Tap "Profile" tab (bottom right)
3. Scroll to "Account" section
4. Toggle "Notifications" switch OFF

It's that simple! They can re-enable anytime by toggling back ON.

### Q: Do notification settings get saved?
**A:** Yes, absolutely! Whatever the user sets in the notification preferences gets saved to their device and remembered:
- Close the app → reopen it → settings are still there
- Restart phone → settings are still there
- Update the app → settings are preserved

The preferences use `UserDefaults` for reliable persistence.

### Q: Will notifications work without internet?
**A:** Yes! The notification system works completely offline:
- Notifications are scheduled locally on the device
- They use iOS's local notification system
- No backend connection required
- Perfect for offline-first experience

---

## 👤 User Questions

### Q: I'm a new user. Will I see a notification popup?
**A:** Yes. On your first app open, you'll see an iOS permission dialog asking to allow notifications:
```
"GoFit" Would Like to Send You Notifications

[Don't Allow] [Allow]
```

Just tap **[Allow]** and you're good to go! Notifications will start right away.

### Q: I accidentally tapped "Don't Allow". How do I turn them on?
**A:** No problem! You can enable them:
1. Go to iOS Settings
2. Find "GoFit" in the list
3. Tap it and turn on "Allow Notifications"

Or in the GoFit app:
1. ProfileView → Account → Notifications toggle
2. Tap the toggle to turn ON
3. You'll be prompted to enable in iOS Settings
4. Grant permission and you're done!

### Q: Why am I getting 13 notifications per day?
**A:** That's the default schedule when all reminders are on:
- **4 Meal reminders:** 8 AM (breakfast), 12:30 PM (lunch), 3 PM (snack), 7 PM (dinner)
- **7 Water reminders:** Every 2 hours from 8 AM to 8 PM
- **2 Workout reminders:** 7 AM (morning), 6 PM (evening)

You can reduce this by disabling specific reminder types in settings!

### Q: Can I change the notification times?
**A:** Currently, the times are fixed, but we're planning custom notification times in the future. For now, you can:
- Disable specific reminder types
- Enable/disable notifications during certain hours
- Use iOS's Do Not Disturb feature

### Q: I keep dismissing water reminders. Can I turn them off?
**A:** Yes! You can disable just water reminders while keeping meal and workout reminders:

1. ProfileView → Account → Notifications (make sure ON)
2. Under "Water Reminders" → toggle OFF
3. You'll no longer get water reminders
4. Meal and workout reminders continue

This is saved automatically!

### Q: The notification messages are generic. Will they get more personal?
**A:** Eventually, yes! The backend already has AI prompts to generate personalized messages based on your:
- Dietary preferences
- Goals
- Activity level
- Recent meals and workouts

We're currently using fallback messages, but AI-generated personalized content will roll out soon!

---

## 👨‍💻 Developer Questions

### Q: How do I check if notifications are enabled?
**A:** Use this simple code:

```swift
let isEnabled = NotificationService.shared.notificationsEnabled
print("Notifications: \(isEnabled ? "ON" : "OFF")")
```

### Q: How do I enable/disable all notifications programmatically?
**A:** Use these methods:

```swift
// Enable all notifications
NotificationService.shared.enableAllNotifications()

// Disable all notifications
NotificationService.shared.disableAllNotifications()
```

### Q: How do I update specific reminder types?
**A:** Use the update methods:

```swift
NotificationService.shared.updateMealReminders(true)      // Enable meals
NotificationService.shared.updateWaterReminders(false)    // Disable water
NotificationService.shared.updateWorkoutReminders(true)   // Enable workouts
```

### Q: How do I bind notification settings to UI?
**A:** Use @StateObject and @Published:

```swift
@StateObject private var notifications = NotificationService.shared

var body: some View {
    Toggle("Meals", isOn: $notifications.mealRemindersEnabled)
        .onChange(of: notifications.mealRemindersEnabled) { _, newValue in
            notifications.updateMealReminders(newValue)
        }
}
```

### Q: Where are notification preferences stored?
**A:** In UserDefaults under these keys:
- `notificationsEnabled` - Master toggle
- `mealRemindersEnabled` - Meal reminders
- `waterRemindersEnabled` - Water reminders
- `workoutRemindersEnabled` - Workout reminders
- `gofit_notif_initialized` - First-launch flag

You can read them directly:
```swift
UserDefaults.standard.bool(forKey: "notificationsEnabled")
```

### Q: How do I log notification changes?
**A:** The system already logs all changes automatically via AppLogger:

```swift
AppLogger.shared.storage("🔔 Notification Settings Updated: ...")
```

You can view logs in:
1. ProfileView → Privacy & Data → Export Data
2. Search for "🔔" in the exported logs

### Q: Can I post a notification after user action?
**A:** Yes! Here's an example:

```swift
let content = UNMutableNotificationContent()
content.title = "✅ Meal Logged!"
content.body = "Great job logging \(mealName)"
content.sound = .default

let request = UNNotificationRequest(
    identifier: UUID().uuidString,
    content: content,
    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
)

UNUserNotificationCenter.current().add(request)
```

### Q: How do I test notifications without waiting?
**A:** Use this utility view:

```swift
struct NotificationTestView: View {
    var body: some View {
        VStack {
            Button("Send Test Meal Notification") {
                sendTestNotification(title: "Test 🍴", body: "This is a test")
            }
        }
    }
    
    func sendTestNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 🔧 Technical Questions

### Q: What happens if UserDefaults is corrupted?
**A:** The system has fallback logic:
```swift
// If value missing, defaults to true
notificationsEnabled = UserDefaults.standard.object(...) as? Bool ?? true
```
So notifications will revert to ON if data is lost.

### Q: Is the notification system thread-safe?
**A:** Yes! NotificationService uses `@MainActor` to ensure all updates happen on the main thread:
```swift
@MainActor
class NotificationService: ObservableObject { ... }
```

### Q: How does the first-launch detection work?
**A:** It uses a simple flag in UserDefaults:
```swift
let hasLoadedBefore = UserDefaults.standard.object(forKey: "gofit_notif_initialized") != nil

if !hasLoadedBefore {
    // First time - set all to true
    UserDefaults.standard.set(true, forKey: "gofit_notif_initialized")
    // ... enable all notifications
}
```

### Q: Can I customize the notification schedule?
**A:** Currently, the times are hardcoded, but the system is designed to be extended:

**Current Schedule:**
- Breakfast: 8:00 AM
- Lunch: 12:30 PM
- Snack: 3:00 PM
- Dinner: 7:00 PM
- Water: Every 2 hours (8 AM - 8 PM)
- Workouts: 7 AM & 6 PM

To customize, modify the scheduling methods in NotificationService.swift:
- `scheduleMealReminders()`
- `scheduleWaterReminders()`
- `scheduleWorkoutReminders()`

### Q: How do I integrate with the meal/water caching system?
**A:** No special integration needed! The systems work independently:
- Caching system (Phase 4) saves data locally
- Notification system schedules reminders
- They can coexist and work together

When user logs meal:
1. Meal saved to local cache (WaterIntakeManager)
2. Notification could reference cached data (future enhancement)

### Q: What if iOS notification permission is denied?
**A:** The system handles it gracefully:
```swift
if settings.authorizationStatus == .authorized {
    self.notificationsEnabled = true
    self.scheduleAllNotifications()
} else {
    self.notificationsEnabled = false
    // User can tap toggle to request again
}
```

---

## 🐛 Troubleshooting Questions

### Q: Notifications aren't showing up. What's wrong?
**A:** Check these in order:
1. **iOS Settings**: Settings → Notifications → Find GoFit → Make sure "Allow Notifications" is ON
2. **App Settings**: ProfileView → Account → Notifications toggle should be Green (ON)
3. **Individual Reminders**: Check that the specific reminder type is enabled
4. **Do Not Disturb**: Make sure iOS DND isn't blocking them
5. **Force Restart**: Try force quit and reopen the app

### Q: Settings changed but aren't saving?
**A:** Try these steps:
1. Check if save is working: Go to ProfileView, toggle on/off, check if it responds
2. Force quit the app (double-tap home, swipe up)
3. Reopen and check if settings were remembered
4. Check device storage isn't full
5. Check app has write permissions

### Q: I see duplicate notifications?
**A:** This could happen if notifications are scheduled twice. Try:
1. Disable all notifications (toggle master OFF)
2. Force quit app (fully close)
3. Reopen app
4. Enable notifications again (toggle master ON)
5. Check system notifications are cleared

### Q: How do I reset to default settings?
**A:** You can:

**Option 1: In App**
1. Disable all notifications (toggle master OFF)
2. Re-enable all notifications (toggle master ON)

**Option 2: Programmatically**
```swift
NotificationService.shared.enableAllNotifications()
```

**Option 3: Complete Reset**
1. Delete app from device
2. Reinstall from Xcode
3. Open fresh (all defaults will be set)

### Q: How do I see notification logs?
**A:** Export and view logs:
1. ProfileView → Scroll to "Privacy & Data"
2. Tap "Export Data"
3. Open the exported file
4. Search for "🔔 Notification Settings"
5. You'll see all preference changes with timestamps

### Q: Notifications work on simulator?
**A:** Sometimes. Simulators can be unreliable with notifications:
- **Recommended**: Test on physical device
- **If using simulator**: Use Xcode Debug menu → Simulate Push Notification
- **Better option**: Always test on real iPhone/iPad

---

## 📊 Data & Privacy Questions

### Q: What data is sent with notifications?
**A:** Only generic data:
- No personal information
- No user data in notification body
- Just reminder text (e.g., "Time for breakfast")
- No tracking or analytics

### Q: Where is my preference data stored?
**A:** Entirely on your device:
- Stored in `UserDefaults` (secure local storage)
- Not uploaded to cloud
- Not shared with any service
- Deleted if app is uninstalled

### Q: Can I export my notification settings?
**A:** Yes! Use the app's export feature:
1. ProfileView → Privacy & Data → Export Data
2. Your settings are included in the export
3. You can review and backup

### Q: What happens if I delete the app?
**A:** All notification preferences are deleted with the app:
- Settings removed from device
- Preferences not stored anywhere else
- If you reinstall, you'll get default settings again

---

## 🔄 Integration Questions

### Q: How does this work with the meal/water caching system?
**A:** They're separate but compatible:
- **Caching**: Saves meal/water data locally for fast loading
- **Notifications**: Reminds user to log meals/water
- **Together**: User logs meal → cached locally → notification reminds for next meal

No conflicts or special integration needed!

### Q: Will this work with push notifications in the future?
**A:** Yes! Currently using local notifications, but the system is designed to support:
- Backend-scheduled notifications
- Push notifications from server
- User-specific AI-generated content

No code changes needed to add support—just extend the backend.

### Q: How does this interact with HealthKit?
**A:** No interaction currently:
- Notifications remind user to log
- HealthKit syncs with Apple Health
- Separate systems working in parallel
- Future: Could combine data for smarter reminders

---

## 📱 Platform Questions

### Q: Does this work on iPad?
**A:** Yes! Notifications work on both iPhone and iPad using the same system.

### Q: What about Apple Watch?
**A:** Currently only for iPhone/iPad. Watch support planned for future:
- Watch notifications
- Quick-log from Watch
- Watch complications

### Q: Do notifications work internationally?
**A:** Yes! The system works globally:
- Respects device timezone
- Notifications trigger at local times
- Works offline
- No location data sent

---

## ✨ Future Questions

### Q: Will times be customizable?
**A:** Yes, in a future update! Coming soon:
- Custom notification times
- Reminder frequency adjustment
- Quiet hours (don't notify during sleep)

### Q: Will there be AI-generated messages?
**A:** Yes! Currently on the backend, rolling out soon:
- Personalized meal suggestions
- Hydration encouragement based on activity
- Motivation based on goals

### Q: Can I set Do Not Disturb integration?
**A:** Planned for future:
- Respect iOS DND automatically
- Silence during sleep hours
- Custom quiet time windows

### Q: Will there be notification analytics?
**A:** Planned for future:
- See which notifications you interact with
- Understand your engagement
- Help improve reminder times

---

## 📞 Still Have Questions?

### Where to Look
1. **Quick answers**: Read [NOTIFICATIONS_QUICK_REFERENCE.md](NOTIFICATIONS_QUICK_REFERENCE.md)
2. **Detailed info**: Read [NOTIFICATIONS_ACTIVE_BY_DEFAULT.md](NOTIFICATIONS_ACTIVE_BY_DEFAULT.md)
3. **Code examples**: See [NOTIFICATIONS_INTEGRATION_EXAMPLES.md](NOTIFICATIONS_INTEGRATION_EXAMPLES.md)
4. **Visual flows**: Check [NOTIFICATIONS_DIAGRAMS_AND_FLOWS.md](NOTIFICATIONS_DIAGRAMS_AND_FLOWS.md)
5. **Navigation**: Use [NOTIFICATIONS_DOCUMENTATION_INDEX.md](NOTIFICATIONS_DOCUMENTATION_INDEX.md)

### Getting Help
- Check app notification logs (ProfileView → Export Data)
- Search for your issue in these FAQs
- Review troubleshooting guides
- Check Xcode console for errors

---

## 🎉 That's It!

Your notification system is fully documented and ready to use. If you have other questions not covered here, they'll likely be answered in one of the other documentation files. Happy notifying! 📢
