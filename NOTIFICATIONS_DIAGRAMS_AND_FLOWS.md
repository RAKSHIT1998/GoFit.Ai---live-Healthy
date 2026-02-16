# Notifications System - Visual Diagrams & Flows

## 📊 First-Launch Flow

```
User Opens App for First Time
        ↓
NotificationService.init() runs
        ↓
Check if gofit_notif_initialized exists
        ↓
    NO (First Launch)            YES (Returning User)
      ↓                              ↓
Set all toggles to TRUE        Load saved preferences
Set gofit_notif_initialized    from UserDefaults
      ↓                              ↓
requestAuthorizationIfNeeded()  Restore user's choices
      ↓                              ↓
User sees iOS permission dialog  No dialog (already asked)
      ↓                              ↓
User taps "Allow"           Set notification status
      ↓                              ↓
scheduleAllNotifications()   Reschedule based on prefs
      ↓                              ↓
All reminders scheduled      Ready to send notifications
      ↓
ProfileView shows:
✅ Notifications: Enabled
  ✓ Meal Reminders
  ✓ Water Reminders
  ✓ Workout Reminders
```

---

## 🎮 User Control Flow

```
ProfileView → Account Section
        ↓
        ┌─────────────────────────────────┐
        │   Notifications Toggle          │
        │   ─────────────────────────     │
        │   [🟢 ON] or [⚪ OFF]           │
        └─────────────────────────────────┘
                ↓
        ┌──────────────┬──────────────┐
        ↓              ↓
    User Toggles ON   User Toggles OFF
        ↓                   ↓
    Request Auth      Remove All Pending
        ↓              Notifications
    Schedule All              ↓
    Notifications      Hide individual
        ↓              toggle controls
    Save to            ↓
    UserDefaults       Save to
        ↓              UserDefaults
    Show Enabled           ↓
    + Individual       Show Disabled
    Toggle Controls        ↓
        ↓              User in
    User can           "notifications off"
    disable each       state
    reminder type
        ↓
    Any change
    saved to
    UserDefaults
```

---

## 🔔 Notification Schedule Timeline

```
Daily Timeline (When All Enabled)

8:00 AM    10:00 AM    12:00 PM    2:00 PM     4:00 PM     6:00 PM     8:00 PM
│          │           │           │           │           │           │
├─ 🌅 Breakfast        ├─ 💧 Water  ├─ 💧 Water  ├─ 🍴 Lunch   ├─ 💧 Water  ├─ 🥘 Dinner    ├─ 💧 Water
│  Meal Reminder       │ Reminder   │ Reminder  │ Reminder   │ Reminder   │ Reminder      │ Reminder
│  + 💪 Workout         └──────────  └──────────  └──────────  └──────────  └───────────    └──────────
│  Reminder                                                      + 🏃 Workout
│                                                                 Reminder
│ 12:30 PM
├─ 🍴 Lunch
│  Reminder
│
│ 3:00 PM
├─ 🥗 Snack
│  Reminder
│
└─ 7:00 PM
   🏃 Workout
   Reminder

Total: 13 notifications per day when all enabled
```

---

## 📱 Settings Persistence

```
User Makes Change in ProfileView
        ↓
Toggle Property Changes
(e.g., mealRemindersEnabled = false)
        ↓
onChange() handler triggered
        ↓
Call updateMealReminders(false)
        ↓
Remove meal notifications
from system queue
        ↓
Call saveSettings()
        ↓
UserDefaults.set() for each toggle
        ↓
UserDefaults.synchronize()
        ↓
AppLogger records change
        ↓
                    Time passes...
                    User closes app
                    App is terminated
                            ↓
                    User reopens app
                            ↓
                    NotificationService.init()
                            ↓
                    loadSettings()
                            ↓
                    Read from UserDefaults
                            ↓
                    Restore all user's
                    previous choices
                            ↓
                    Reschedule
                    based on preferences
                            ↓
                    ProfileView shows
                    correct status
```

---

## 🔀 State Diagram

```
                         ┌──────────────────────┐
                         │  First App Launch    │
                         │  All toggles = true  │
                         └──────────┬───────────┘
                                    ↓
                    ┌───────────────────────────────────┐
                    │   NotificationService Created     │
                    │   - notificationsEnabled = true   │
                    │   - mealRemindersEnabled = true   │
                    │   - waterRemindersEnabled = true  │
                    │   - workoutRemindersEnabled = true│
                    └──────────┬────────────────────────┘
                               ↓
                    ┌──────────────────────────┐
                    │  Auto-Request Permission │
                    └──────┬────────┬──────────┘
                           ↓        ↓
                     User Allows   User Denies
                           ↓        ↓
                           │        └──→ notificationsEnabled 
                           │             remains true
                           │             (user can manually
                           │              request later)
                           ↓
                    ┌──────────────────────────┐
                    │   NOTIFICATIONS ACTIVE   │
                    │   Scheduled & Ready      │
                    └──────┬───────────────────┘
                           ↓
                ┌──────────────────────────────┐
                │  User Opens ProfileView      │
                │  Sees Toggle: Enabled ✅     │
                └──────┬───────────────────────┘
                       ↓
        ┌──────────────────────────────────────┐
        │ User Makes Preference Change         │
        │ (toggle any reminder type)           │
        └──┬───────────────────────────────┬──┘
           ↓                               ↓
    Disables Something          Enables Something
           ↓                               ↓
    Remove those                 Reschedule those
    notifications                 notifications
           ↓                               ↓
    Save to UserDefaults      Save to UserDefaults
           ↓                               ↓
    AppLogger logs change     AppLogger logs change
           ↓                               ↓
    ┌──────────────────────────────────────┐
    │ User Makes Multiple Changes          │
    │ Each one immediately persisted       │
    └──────┬───────────────────────────────┘
           ↓
    ┌──────────────────────────────────────┐
    │ App Continues Running                │
    │ Notifications send at scheduled times│
    └──────┬───────────────────────────────┘
           ↓
    ┌──────────────────────────────────────┐
    │ User Closes App / App Backgrounded   │
    │ All preferences saved to UserDefaults│
    └──────┬───────────────────────────────┘
           ↓
    ┌──────────────────────────────────────┐
    │ User Reopens App Later               │
    │ loadSettings() restores preferences  │
    │ Notifications rescheduled            │
    │ ProfileView shows saved state        │
    └──────────────────────────────────────┘
```

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│              User Interface Layer                   │
│  ┌────────────────────────────────────────────────┐ │
│  │  ProfileView (Account Section)                 │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │ Notifications Toggle (Master)            │ │ │
│  │  │ Meal Reminders Toggle                    │ │ │
│  │  │ Water Reminders Toggle                   │ │ │
│  │  │ Workout Reminders Toggle                 │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────┬─────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│            Service Layer                            │
│  ┌────────────────────────────────────────────────┐ │
│  │  NotificationService (Singleton)               │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │ @Published Properties:                   │ │ │
│  │  │ - notificationsEnabled                   │ │ │
│  │  │ - mealRemindersEnabled                   │ │ │
│  │  │ - waterRemindersEnabled                  │ │ │
│  │  │ - workoutRemindersEnabled                │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │ Public Methods:                          │ │ │
│  │  │ - enableAllNotifications()               │ │ │
│  │  │ - disableAllNotifications()              │ │ │
│  │  │ - updateMealReminders()                  │ │ │
│  │  │ - updateWaterReminders()                 │ │ │
│  │  │ - updateWorkoutReminders()               │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────┬─────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│           Persistence Layer                         │
│  ┌────────────────────────────────────────────────┐ │
│  │ UserDefaults                                   │ │
│  │ ┌──────────────────────────────────────────┐  │ │
│  │ │ Keys:                                    │  │ │
│  │ │ - gofit_notif_initialized (flag)        │  │ │
│  │ │ - notificationsEnabled                  │  │ │
│  │ │ - mealRemindersEnabled                  │  │ │
│  │ │ - waterRemindersEnabled                 │  │ │
│  │ │ - workoutRemindersEnabled               │  │ │
│  │ └──────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────┬─────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│           System Layer                              │
│  ┌────────────────────────────────────────────────┐ │
│  │ UNUserNotificationCenter                       │ │
│  │ (iOS Local Notifications Framework)            │ │
│  │ ┌──────────────────────────────────────────┐  │ │
│  │ │ Scheduled Notifications:                 │  │ │
│  │ │ - Meal reminders (4x daily)             │  │ │
│  │ │ - Water reminders (7x daily)            │  │ │
│  │ │ - Workout reminders (2x daily)          │  │ │
│  │ └──────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────┬─────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│           Logging Layer                             │
│  ┌────────────────────────────────────────────────┐ │
│  │ AppLogger                                      │ │
│  │ - Logs all preference changes                  │ │
│  │ - Saved to Documents/GoFitLogs/               │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

```
                        User Action
                             ↓
                    Toggle Changed
                             ↓
              onChange() handler fires
                             ↓
        ┌─────────────────────────────────┐
        │ Update NotificationService      │
        │ - Change @Published property    │
        │ - Update UI immediately         │
        └──────────────┬──────────────────┘
                       ↓
        ┌─────────────────────────────────┐
        │ Call update Method              │
        │ - updateMealReminders(value)    │
        │ - updateWaterReminders(value)   │
        │ - updateWorkoutReminders(value) │
        └──────────────┬──────────────────┘
                       ↓
        ┌─────────────────────────────────┐
        │ Schedule/Remove Notifications   │
        │ - If enabled: schedule          │
        │ - If disabled: remove pending   │
        └──────────────┬──────────────────┘
                       ↓
        ┌─────────────────────────────────┐
        │ Call saveSettings()             │
        │ - Save to UserDefaults          │
        │ - Synchronize                   │
        └──────────────┬──────────────────┘
                       ↓
        ┌─────────────────────────────────┐
        │ Log to AppLogger                │
        │ - Record preference change      │
        │ - Timestamp included            │
        └──────────────┬──────────────────┘
                       ↓
                    Done!
              ProfileView updated
           Notifications scheduled/removed
          Preference persisted to device
         Change logged for troubleshooting
```

---

## 🧪 Testing Flow

```
Test Case: First Launch Fresh Install
                    ↓
        Delete app from device
                    ↓
        Reinstall fresh from Xcode
                    ↓
        Open app (first time)
                    ↓
        ┌──────────────────────┐
        │ Expected Behavior:   │
        │ ✅ iOS permission    │
        │    dialog appears    │
        │ ✅ User taps "Allow" │
        │ ✅ App continues     │
        │ ✅ All toggles ON    │
        │ ✅ Notifications     │
        │    scheduled         │
        └──────────┬───────────┘
                   ↓
        Open ProfileView → Account
                   ↓
        ┌──────────────────────┐
        │ Verify:              │
        │ ✅ Notifications     │
        │    shows "Enabled"   │
        │ ✅ All individual    │
        │    toggles visible   │
        │ ✅ All toggles ON    │
        └──────────┬───────────┘
                   ↓
               PASS! ✅
```

```
Test Case: Settings Persistence
                    ↓
        Disable water reminders
                    ↓
        Verify UI updates
                    ↓
        Force quit app
                    ↓
        Reopen app
                    ↓
        ┌──────────────────────┐
        │ Expected Behavior:   │
        │ ✅ Water reminders   │
        │    still disabled    │
        │ ✅ Other toggles     │
        │    still enabled     │
        │ ✅ UI matches saved  │
        │    state             │
        └─────────────────────┘
                   ↓
               PASS! ✅
```

---

## 📈 Toggle Visibility Logic

```
Start
  ↓
Is notificationsEnabled == true?
  ↓
YES                          NO
  ↓                           ↓
Show:                    Hide:
- Meal Reminders         - Meal Reminders
- Water Reminders        - Water Reminders
- Workout Reminders      - Workout Reminders
  ↓
All individual toggles are
shown when master is ON
  ↓
User can customize
each reminder type
```

---

## 🎯 Permission Flow

```
App Launch
    ↓
requestAuthorizationIfNeeded()
    ↓
Check UNUserNotificationCenter
getNotificationSettings()
    ↓
┌──────────────────────────┐
│ authorizationStatus?     │
└──────┬───────────────────┘
       ├─ .notDetermined → Request permission
       │                   (show iOS dialog)
       │                      ↓
       │            User taps "Allow" or "Don't Allow"
       │                      ↓
       │            Update notificationsEnabled
       │
       ├─ .denied → notificationsEnabled = false
       │            (user can enable manually)
       │
       ├─ .authorized → notificationsEnabled = true
       │                (ready to schedule)
       │
       └─ .provisional → notificationsEnabled = true
                        (can send without user action)
```

---

## 💾 Data Lifecycle

```
┌─────────────────────────────────────────────┐
│   App First Opened                          │
│   - UserDefaults empty                      │
│   - gofit_notif_initialized missing         │
└──────────────────┬────────────────────────┘
                   ↓
        Create gofit_notif_initialized
        Set all toggles = true
        Save to UserDefaults
                   ↓
┌──────────────────────────────────────────────┐
│   App Running (Normal Operation)             │
│   - Read toggles from @Published properties  │
│   - UI binds to @Published                   │
│   - Changes immediately reflected in UI      │
│   - Schedule/remove notifications in real-   │
│     time                                     │
└──────────────────┬───────────────────────────┘
                   ↓
        User makes change
                   ↓
        Save to UserDefaults
                   ↓
┌──────────────────────────────────────────────┐
│   App Backgrounded/Closed                    │
│   - UserDefaults persists data               │
│   - Scheduled notifications remain in system │
│   - No data lost                             │
└──────────────────┬───────────────────────────┘
                   ↓
        App Reopened
                   ↓
        loadSettings() reads UserDefaults
                   ↓
        @Published properties updated
                   ↓
        ProfileView shows saved state
                   ↓
        Notifications rescheduled
                   ↓
        Back to "App Running (Normal Operation)"
```

---

## 🔍 Debug Flow

```
User Reports: "Settings don't save"
                    ↓
        Go to ProfileView
                    ↓
        Click "Export Data"
                    ↓
        View logs in Documents/GoFitLogs
                    ↓
        Search for "🔔 Notification Settings"
                    ↓
        ┌──────────────────────────┐
        │ Check log entry:         │
        │ - Timestamp             │
        │ - All toggle values     │
        │ - Any errors            │
        └──────────┬───────────────┘
                   ↓
        If log shows save:
        ✅ UserDefaults working
        ✅ Issue is likely elsewhere
                   ↓
        If log missing:
        ❌ saveSettings() not called
        ❌ Permission issue
        ❌ Check code changes
```

---

These diagrams show how the notification system flows through your app from user action to persistent storage and back!
