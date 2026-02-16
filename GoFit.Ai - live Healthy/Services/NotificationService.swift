import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notificationsEnabled: Bool = true  // DEFAULT: ON
    @Published var mealRemindersEnabled: Bool = true
    @Published var waterRemindersEnabled: Bool = true
    @Published var workoutRemindersEnabled: Bool = true
    
    private init() {
        loadSettings()
        // Auto-request authorization on first launch (silent request)
        checkAuthorizationStatusAndSchedule()
        // Auto-request if not yet authorized
        requestAuthorizationIfNeeded()
    }
    
    // MARK: - Authorization
    
    /// Silently request authorization on app launch if needed
    private func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                guard let self = self else { return }
                
                // If not determined yet, request permission
                if settings.authorizationStatus == .notDetermined {
                    print("📢 First launch - requesting notification permissions...")
                    self.requestAuthorization()
                }
            }
        }
    }
    
    /// User explicitly requests notifications (from button tap)
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.notificationsEnabled = granted
                // Persist the actual authorization result to UserDefaults
                self.saveSettings()
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleAllNotifications()
                } else {
                    print("❌ Notification permission denied")
                }
                if let error = error {
                    print("⚠️ Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Check authorization status and schedule notifications if already authorized
    private func checkAuthorizationStatusAndSchedule() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                guard let self = self else { return }
                let wasAuthorized = self.notificationsEnabled
                self.notificationsEnabled = settings.authorizationStatus == .authorized
                
                if self.notificationsEnabled && !wasAuthorized {
                    self.scheduleAllNotifications()
                } else if !self.notificationsEnabled && wasAuthorized {
                    // Permission was revoked, clear notifications
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                }
            }
        }
    }
    
    /// Enable ALL notifications (called from settings)
    func enableAllNotifications() {
        notificationsEnabled = true
        mealRemindersEnabled = true
        waterRemindersEnabled = true
        workoutRemindersEnabled = true
        saveSettings()
        scheduleAllNotifications()
    }
    
    /// Disable ALL notifications (called from settings)
    func disableAllNotifications() {
        notificationsEnabled = false
        mealRemindersEnabled = false
        waterRemindersEnabled = false
        workoutRemindersEnabled = false
        saveSettings()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        // Load with proper defaults
        // If never set, all default to true (notifications active)
        let hasLoadedBefore = UserDefaults.standard.object(forKey: "gofit_notif_initialized") != nil
        
        if !hasLoadedBefore {
            // First time - enable all notifications by default
            UserDefaults.standard.set(true, forKey: "gofit_notif_initialized")
            notificationsEnabled = true
            mealRemindersEnabled = true
            waterRemindersEnabled = true
            workoutRemindersEnabled = true
            saveSettings()
        } else {
            // Load saved preferences
            notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
            mealRemindersEnabled = UserDefaults.standard.object(forKey: "mealRemindersEnabled") as? Bool ?? true
            waterRemindersEnabled = UserDefaults.standard.object(forKey: "waterRemindersEnabled") as? Bool ?? true
            workoutRemindersEnabled = UserDefaults.standard.object(forKey: "workoutRemindersEnabled") as? Bool ?? true
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(mealRemindersEnabled, forKey: "mealRemindersEnabled")
        UserDefaults.standard.set(waterRemindersEnabled, forKey: "waterRemindersEnabled")
        UserDefaults.standard.set(workoutRemindersEnabled, forKey: "workoutRemindersEnabled")
        // Synchronize to ensure immediate persistence
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleAllNotifications() {
        guard notificationsEnabled else { return }
        
        // Cancel all existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        if mealRemindersEnabled {
            scheduleMealReminders()
        }
        
        if waterRemindersEnabled {
            scheduleWaterReminders()
        }
        
        if workoutRemindersEnabled {
            scheduleWorkoutReminders()
        }
    }
    
    // MARK: - Meal Reminders
    
    private func scheduleMealReminders() {
        // Breakfast: 8:00 AM
        scheduleMealReminder(hour: 8, minute: 0, mealType: "breakfast", identifier: "meal-breakfast")
        
        // Lunch: 12:30 PM
        scheduleMealReminder(hour: 12, minute: 30, mealType: "lunch", identifier: "meal-lunch")
        
        // Dinner: 7:00 PM
        scheduleMealReminder(hour: 19, minute: 0, mealType: "dinner", identifier: "meal-dinner")
        
        // Snack: 3:00 PM
        scheduleMealReminder(hour: 15, minute: 0, mealType: "snack", identifier: "meal-snack")
    }
    
    private func scheduleMealReminder(hour: Int, minute: Int, mealType: String, identifier: String) {
        // Fetch AI-generated reminder content from backend
        Task {
            do {
                let content = try await fetchAIMealReminder(mealType: mealType)
                createNotification(
                    identifier: identifier,
                    title: content.title,
                    body: content.body,
                    hour: hour,
                    minute: minute,
                    repeats: true
                )
            } catch {
                // Fallback to default message
                createNotification(
                    identifier: identifier,
                    title: "Time to eat! 🍽️",
                    body: "Don't forget your \(mealType). Your body needs fuel to stay healthy!",
                    hour: hour,
                    minute: minute,
                    repeats: true
                )
            }
        }
    }
    
    // MARK: - Water Reminders
    
    private func scheduleWaterReminders() {
        // Schedule water reminders every 2 hours from 8 AM to 8 PM
        for hour in stride(from: 8, through: 20, by: 2) {
            scheduleWaterReminder(hour: hour, identifier: "water-\(hour)")
        }
    }
    
    private func scheduleWaterReminder(hour: Int, identifier: String) {
        Task {
            do {
                let content = try await fetchAIWaterReminder()
                createNotification(
                    identifier: identifier,
                    title: content.title,
                    body: content.body,
                    hour: hour,
                    minute: 0,
                    repeats: true
                )
            } catch {
                // Fallback to default message
                createNotification(
                    identifier: identifier,
                    title: "Stay Hydrated! 💧",
                    body: "Time to drink water! Staying hydrated helps your body function at its best.",
                    hour: hour,
                    minute: 0,
                    repeats: true
                )
            }
        }
    }
    
    // MARK: - Workout Reminders
    
    private func scheduleWorkoutReminders() {
        // Morning workout: 7:00 AM (if user prefers morning workouts)
        scheduleWorkoutReminder(hour: 7, minute: 0, identifier: "workout-morning")
        
        // Evening workout: 6:00 PM (if user prefers evening workouts)
        scheduleWorkoutReminder(hour: 18, minute: 0, identifier: "workout-evening")
    }
    
    private func scheduleWorkoutReminder(hour: Int, minute: Int, identifier: String) {
        Task {
            do {
                let content = try await fetchAIWorkoutReminder()
                createNotification(
                    identifier: identifier,
                    title: content.title,
                    body: content.body,
                    hour: hour,
                    minute: minute,
                    repeats: true
                )
            } catch {
                // Fallback to default message
                createNotification(
                    identifier: identifier,
                    title: "Workout Time! 💪",
                    body: "Time for your workout! Your body will thank you for staying active.",
                    hour: hour,
                    minute: minute,
                    repeats: true
                )
            }
        }
    }
    
    // MARK: - Create Notification
    
    private func createNotification(identifier: String, title: String, body: String, hour: Int, minute: Int, repeats: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule notification \(identifier): \(error.localizedDescription)")
            } else {
                print("✅ Scheduled notification: \(identifier) at \(hour):\(minute)")
            }
        }
    }
    
    // MARK: - AI-Generated Content
    
    private func fetchAIMealReminder(mealType: String) async throws -> (title: String, body: String) {
        guard let token = AuthService.shared.readToken()?.accessToken else {
            throw NSError(domain: "NotificationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(NetworkManager.shared.baseURL.absoluteString)/notifications/meal-reminder")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["mealType": mealType]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "NotificationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch AI reminder"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let title = json["title"] as? String,
           let body = json["body"] as? String {
            return (title, body)
        }
        
        throw NSError(domain: "NotificationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
    }
    
    private func fetchAIWaterReminder() async throws -> (title: String, body: String) {
        guard let token = AuthService.shared.readToken()?.accessToken else {
            throw NSError(domain: "NotificationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(NetworkManager.shared.baseURL.absoluteString)/notifications/water-reminder")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "NotificationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch AI reminder"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let title = json["title"] as? String,
           let body = json["body"] as? String {
            return (title, body)
        }
        
        throw NSError(domain: "NotificationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
    }
    
    private func fetchAIWorkoutReminder() async throws -> (title: String, body: String) {
        guard let token = AuthService.shared.readToken()?.accessToken else {
            throw NSError(domain: "NotificationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(NetworkManager.shared.baseURL.absoluteString)/notifications/workout-reminder")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "NotificationError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch AI reminder"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let title = json["title"] as? String,
           let body = json["body"] as? String {
            return (title, body)
        }
        
        throw NSError(domain: "NotificationError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
    }
    
    // MARK: - Update Settings
    
    func updateMealReminders(_ enabled: Bool) {
        mealRemindersEnabled = enabled
        saveSettings()
        if enabled {
            scheduleMealReminders()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["meal-breakfast", "meal-lunch", "meal-dinner", "meal-snack"])
        }
    }
    
    func updateWaterReminders(_ enabled: Bool) {
        waterRemindersEnabled = enabled
        saveSettings()
        if enabled {
            scheduleWaterReminders()
        } else {
            // Only remove the even-hour identifiers that were actually scheduled
            let identifiers = stride(from: 8, through: 20, by: 2).map { "water-\($0)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func updateWorkoutReminders(_ enabled: Bool) {
        workoutRemindersEnabled = enabled
        saveSettings()
        if enabled {
            scheduleWorkoutReminders()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout-morning", "workout-evening"])
        }
    }
}

