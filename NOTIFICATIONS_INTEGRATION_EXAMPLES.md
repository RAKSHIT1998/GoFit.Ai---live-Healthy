# Notifications Integration Examples

## Overview
This guide shows practical examples of how to integrate and use the notification system throughout the GoFit app.

---

## 1. Basic Usage in Views

### Example: Checking if Notifications Are Enabled
```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            if notifications.notificationsEnabled {
                Text("📢 You have notifications enabled")
                    .foregroundColor(.green)
            } else {
                Text("🔇 Notifications are disabled")
                    .foregroundColor(.gray)
            }
        }
    }
}
```

### Example: Disable Notifications on Logout
```swift
struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        Button("Logout") {
            // Clear notifications when user logs out
            NotificationService.shared.disableAllNotifications()
            
            // Then logout
            auth.logout()
        }
    }
}
```

### Example: Bind Toggle to Notification Setting
```swift
struct SettingsView: View {
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notifications.notificationsEnabled)
                .onChange(of: notifications.notificationsEnabled) { _, newValue in
                    if newValue {
                        notifications.requestAuthorization()
                        notifications.scheduleAllNotifications()
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
        }
    }
}
```

---

## 2. Post-Action Notifications

### Example: Show Notification After Logging Meal

```swift
struct MealLoggingView: View {
    @State private var mealName = ""
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            TextField("Meal Name", text: $mealName)
            
            Button("Log Meal") {
                // Save meal
                saveMeal(mealName)
                
                // Check if next meal reminder should be pushed
                if notifications.mealRemindersEnabled {
                    // Could show immediate confirmation notification
                    let content = UNMutableNotificationContent()
                    content.title = "✅ Meal Logged!"
                    content.body = "Great job logging \(mealName)"
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: "meal-logged-\(UUID().uuidString)",
                        content: content,
                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    )
                    
                    try? UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }
    
    private func saveMeal(_ name: String) {
        // Implementation
    }
}
```

### Example: Notification After Workout Completion

```swift
struct WorkoutCompleteView: View {
    let workout: WorkoutSession
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            Text("🎉 Workout Complete!")
            Text("Great job! You burned \(Int(workout.caloriesBurned)) calories")
            
            Button("Done") {
                if notifications.workoutRemindersEnabled {
                    scheduleNextWorkoutReminder()
                }
            }
        }
    }
    
    private func scheduleNextWorkoutReminder() {
        // Get next workout time
        let nextWorkoutTime = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        )!
        
        // Schedule reminder
        NotificationService.shared.scheduleWorkoutReminders()
    }
}
```

---

## 3. Conditional Behavior Based on Notification Status

### Example: Different App Behavior

```swift
struct DailyCheckInView: View {
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            if notifications.mealRemindersEnabled {
                // Show detailed meal tracking if reminders are on
                DetailedMealTrackingView()
            } else {
                // Show simplified view if reminders are off
                SimpleMealLoggingView()
            }
            
            if notifications.waterRemindersEnabled {
                WaterIntakeWidget()
            }
            
            if notifications.workoutRemindersEnabled {
                WorkoutSuggestionCard()
            }
        }
    }
}
```

### Example: Prompt to Enable Notifications

```swift
struct OnboardingView: View {
    @State private var showNotificationPrompt = false
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            if !notifications.notificationsEnabled {
                VStack(spacing: 12) {
                    Text("📢 Want Personalized Reminders?")
                        .font(.headline)
                    Text("Get reminders for meals, water, and workouts tailored to your goals.")
                    
                    Button("Enable Notifications") {
                        notifications.enableAllNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Maybe Later") {
                        // Do nothing
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}
```

---

## 4. Notification Preferences in Different Contexts

### Example: Restrict Reminders During Sleep

```swift
struct AdvancedNotificationSettings: View {
    @StateObject private var notifications = NotificationService.shared
    @State private var doNotDisturbStart = Date()
    @State private var doNotDisturbEnd = Date()
    
    var body: some View {
        Form {
            Section("Reminder Preferences") {
                Toggle("Meal Reminders", isOn: $notifications.mealRemindersEnabled)
                Toggle("Water Reminders", isOn: $notifications.waterRemindersEnabled)
                Toggle("Workout Reminders", isOn: $notifications.workoutRemindersEnabled)
            }
            
            Section("Quiet Hours") {
                DatePicker("Start", selection: $doNotDisturbStart, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $doNotDisturbEnd, displayedComponents: .hourAndMinute)
            }
        }
        .onChange(of: notifications.mealRemindersEnabled) { _, newValue in
            if newValue {
                notifications.scheduleMealReminders()
            } else {
                notifications.updateMealReminders(false)
            }
        }
    }
}
```

### Example: Frequency Control

```swift
struct NotificationFrequencySettings: View {
    @StateObject private var notifications = NotificationService.shared
    @State private var mealReminderFrequency = "all"
    @State private var waterReminderFrequency = "every2h"
    
    var body: some View {
        Form {
            Section("Meal Reminders") {
                Picker("Frequency", selection: $mealReminderFrequency) {
                    Text("All meals").tag("all")
                    Text("Lunch & Dinner only").tag("some")
                    Text("Once a day").tag("once")
                }
            }
            
            Section("Water Reminders") {
                Picker("Frequency", selection: $waterReminderFrequency) {
                    Text("Every 1 hour").tag("every1h")
                    Text("Every 2 hours").tag("every2h")
                    Text("Every 4 hours").tag("every4h")
                }
            }
        }
        .onChange(of: mealReminderFrequency) { _, newValue in
            updateMealFrequency(newValue)
        }
        .onChange(of: waterReminderFrequency) { _, newValue in
            updateWaterFrequency(newValue)
        }
    }
    
    private func updateMealFrequency(_ frequency: String) {
        // Re-schedule meals with new frequency
        if frequency == "all" {
            notifications.updateMealReminders(true)
        } else if frequency == "some" {
            // Custom scheduling
            NotificationService.shared.scheduleMealReminders()
        }
    }
    
    private func updateWaterFrequency(_ frequency: String) {
        // Re-schedule water with new frequency
        if frequency == "every2h" {
            notifications.updateWaterReminders(true)
        } else {
            // Custom scheduling
            NotificationService.shared.scheduleWaterReminders()
        }
    }
}
```

---

## 5. Analytics and Logging

### Example: Track Notification Engagement

```swift
struct NotificationAnalytics: View {
    @State private var notificationStats: [String: Int] = [:]
    @StateObject private var notifications = NotificationService.shared
    
    var body: some View {
        VStack {
            Text("Notification Status")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Master")
                    Text("Meals")
                    Text("Water")
                    Text("Workouts")
                }
                
                VStack(alignment: .leading) {
                    Text(notifications.notificationsEnabled ? "✅ ON" : "❌ OFF")
                    Text(notifications.mealRemindersEnabled ? "✅ ON" : "❌ OFF")
                    Text(notifications.waterRemindersEnabled ? "✅ ON" : "❌ OFF")
                    Text(notifications.workoutRemindersEnabled ? "✅ ON" : "❌ OFF")
                }
            }
        }
        .onAppear {
            logNotificationStatus()
        }
    }
    
    private func logNotificationStatus() {
        AppLogger.shared.storage("""
        📊 Notification Status Check:
        - Overall: \(notifications.notificationsEnabled ? "ON" : "OFF")
        - Meals: \(notifications.mealRemindersEnabled ? "ON" : "OFF")
        - Water: \(notifications.waterRemindersEnabled ? "ON" : "OFF")
        - Workouts: \(notifications.workoutRemindersEnabled ? "ON" : "OFF")
        """)
    }
}
```

### Example: Export Notification Preferences

```swift
struct ExportNotificationPreferences {
    @StateObject private var notifications = NotificationService.shared
    
    func exportAsJSON() -> Data? {
        let preferences: [String: Any] = [
            "notificationsEnabled": notifications.notificationsEnabled,
            "mealRemindersEnabled": notifications.mealRemindersEnabled,
            "waterRemindersEnabled": notifications.waterRemindersEnabled,
            "workoutRemindersEnabled": notifications.workoutRemindersEnabled,
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        return try? JSONSerialization.data(withJSONObject: preferences)
    }
}
```

---

## 6. Testing Notifications

### Example: Manual Notification Trigger

```swift
struct NotificationTestView: View {
    var body: some View {
        VStack(spacing: 12) {
            Button("Test Meal Notification") {
                sendTestNotification(
                    title: "Breakfast Time! 🥞",
                    body: "Time for a healthy breakfast. What will you have?"
                )
            }
            
            Button("Test Water Notification") {
                sendTestNotification(
                    title: "Time for a drink! 💧",
                    body: "Stay hydrated - drink some water!"
                )
            }
            
            Button("Test Workout Notification") {
                sendTestNotification(
                    title: "Let's move! 💪",
                    body: "Ready for your morning workout?"
                )
            }
        }
    }
    
    private func sendTestNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send test notification: \(error)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }
}
```

---

## 7. Best Practices

### ✅ DO
```swift
// Request permission before critical notification
if NotificationService.shared.notificationsEnabled {
    // Send notification
}

// Update all notifications together
NotificationService.shared.enableAllNotifications()

// Log important notification changes
AppLogger.shared.storage("User enabled meal reminders")

// Test on real device (simulator sometimes doesn't show notifications)
// Use Xcode's notification simulator: Debug → Simulate Push Notification
```

### ❌ DON'T
```swift
// Don't assume notifications are authorized
// Always check NotificationService.notificationsEnabled

// Don't schedule duplicate notifications
// Check existing scheduled notifications first

// Don't ignore notification errors
// Log and handle failures gracefully

// Don't send notifications too frequently
// Respect quiet hours and user preferences
```

---

## 8. Integration Checklist

- [ ] Import `NotificationService` where needed
- [ ] Use `@StateObject private var notifications = NotificationService.shared`
- [ ] Bind UI toggles to notification properties
- [ ] Handle `onChange` events for notification updates
- [ ] Check `notificationsEnabled` before showing notification-related UI
- [ ] Log notification changes via `AppLogger`
- [ ] Test on physical device
- [ ] Verify notifications appear at correct times
- [ ] Test disable/enable cycle
- [ ] Verify settings persist after restart

---

## Summary

The notification system is designed to be:
- **Easy to use** - Simple API with sensible defaults
- **Flexible** - Control individual reminder types
- **Reliable** - Persistent settings, works offline
- **User-respecting** - Easy to disable, logs all changes
- **Observable** - Published properties for reactive updates

Use these examples as templates for integrating notifications throughout your app!
