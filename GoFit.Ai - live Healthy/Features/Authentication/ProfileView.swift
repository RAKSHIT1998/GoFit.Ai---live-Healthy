import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var purchases: PurchaseManager
    @StateObject private var healthKit = HealthKitService.shared
    @StateObject private var notifications = NotificationService.shared

    @State private var showingEditProfile = false
    @State private var showingPaywall = false
    @State private var showingDeleteAccount = false
    @State private var showingExportData = false
    @State private var showingChangePassword = false
    @State private var showingShareProgress = false

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var healthSyncEnabled = true
    @AppStorage("unitsPreference") private var unitsPreference: String = "metric"
    @AppStorage("darkModePreference") private var darkModePreference: String = "system"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false

    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
    }
    
    enum DarkModePreference: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    private var currentUnits: UnitSystem {
        UnitSystem(rawValue: unitsPreference.capitalized) ?? .metric
    }
    
    private var currentDarkMode: DarkModePreference {
        DarkModePreference(rawValue: darkModePreference.capitalized) ?? .system
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.bottom, 24)

                    quickStatsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        accountSection
                        subscriptionSection
                        healthSection
                        preferencesSection
                        privacySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Design.Colors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .overlay(loadingOverlay)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView().environmentObject(auth)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView().environmentObject(purchases)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView().environmentObject(auth)
            }
            .sheet(isPresented: $showingShareProgress) {
                ShareProgressView(
                    calories: "1,450", // TODO: Get actual calories from backend
                    steps: healthKit.todaySteps,
                    activeCalories: healthKit.todayActiveCalories,
                    waterIntake: 0.0, // TODO: Get actual water intake
                    heartRate: healthKit.restingHeartRate > 0 ? healthKit.restingHeartRate : nil
                )
                .environmentObject(auth)
            }
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAccount() }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $showingExportData) {
                // Export data loading sheet
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Exporting your data...")
                            .font(.headline)
                        Text("Please wait")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Data exported successfully!")
                            .font(.headline)
                    }
                }
                .padding(40)
                .interactiveDismissDisabled(isLoading)
            }
            .onAppear {
                // Check current authorization status when view appears
                // This refreshes status if user granted permissions in Settings
                healthKit.checkAuthorizationStatus()
                healthSyncEnabled = healthKit.isAuthorized
                
                // If HealthKit is already authorized, start periodic sync
                if healthKit.isAuthorized {
                    print("✅ HealthKit already authorized on ProfileView appear - starting periodic sync")
                    healthKit.startPeriodicSync()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh authorization status when app comes to foreground
                // This handles cases where user grants permissions in Settings then returns to app
                healthKit.checkAuthorizationStatus()
                healthSyncEnabled = healthKit.isAuthorized
                
                // If HealthKit is now authorized, start periodic sync
                if healthKit.isAuthorized {
                    print("✅ HealthKit permission detected on foreground - starting periodic sync")
                    healthKit.startPeriodicSync()
                }
            }
        }
    }
    
    // MARK: - Health Section
    private var healthSection: some View {
        SettingsSection(title: "Health & Fitness") {
            HStack {
                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .pink,
                    title: "Apple Health",
                    subtitle: healthKit.isAuthorized ? "Connected" : "Not Connected"
                )
                Spacer()
                Toggle("", isOn: $healthSyncEnabled)
                    .labelsHidden()
            }
            .onChange(of: healthSyncEnabled) { oldValue, newValue in
                if newValue {
                    Task {
                        do {
                            print("🔵 Requesting HealthKit authorization from ProfileView...")
                            
                            // First, refresh status in case user granted permissions in Settings
                            healthKit.checkAuthorizationStatus()
                            
                            // If already authorized, skip request and start periodic sync
                            if healthKit.isAuthorized {
                                print("✅ HealthKit already authorized - starting periodic sync")
                                await MainActor.run {
                                    healthSyncEnabled = true
                                }
                                healthKit.startPeriodicSync()
                                try? await healthKit.syncToBackend()
                                return
                            }
                            
                            // Request authorization if not already granted
                            try await healthKit.requestAuthorization()
                            
                            // Re-check authorization status after requesting
                            healthKit.checkAuthorizationStatus()
                            
                            // Update toggle state based on actual authorization
                            await MainActor.run {
                                healthSyncEnabled = healthKit.isAuthorized
                            }
                            
                            // If permission was just granted, start periodic sync
                            if healthKit.isAuthorized {
                                print("✅ HealthKit permission granted in ProfileView - starting periodic sync")
                                healthKit.startPeriodicSync()
                                try? await healthKit.syncToBackend()
                            } else {
                                // Give user option to check Settings
                                await MainActor.run {
                                    errorMessage = "HealthKit authorization was not granted. Please enable it in Settings > Privacy & Security > Health, then return to the app."
                                    showingError = true
                                }
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to connect to Apple Health: \(error.localizedDescription)"
                                showingError = true
                                healthSyncEnabled = false
                            }
                        }
                    }
                } else {
                    // User disabled HealthKit sync
                    // Note: We can't revoke authorization, but we can stop syncing
                    print("ℹ️ User disabled HealthKit sync")
                }
            }

            SettingsRow(
                icon: "applewatch",
                iconColor: .black,
                title: "Apple Watch",
                subtitle: "Sync activity data",
                action: {
                    Task { 
                        try? await healthKit.syncToBackend()
                    }
                }
            )
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    )
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Design.Colors.primaryGradient)
                .frame(width: 100, height: 100)
                .overlay(
                    Text(auth.name.prefix(1).uppercased())
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(auth.name.isEmpty ? "User" : auth.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(auth.email)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Edit Profile") {
                showingEditProfile = true
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.top, 20)
    }

    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(icon: "flame.fill", value: "1,450", label: "Calories", color: .orange)
                StatCard(icon: "figure.walk", value: "\(healthKit.todaySteps)", label: "Steps", color: .green)
                StatCard(icon: "timer", value: "12h", label: "Fasting", color: .purple)
            }
            
            // Share Progress Button
            Button {
                showingShareProgress = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.title3)
                    Text("Share My Progress")
                        .font(Design.Typography.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Design.Colors.primaryGradient)
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        SettingsSection(title: "Account") {
            SettingsRow(
                icon: "person.fill",
                iconColor: .blue,
                title: "Personal Information",
                action: { showingEditProfile = true }
            )

            SettingsRow(
                icon: "lock.fill",
                iconColor: .red,
                title: "Change Password",
                action: { showingChangePassword = true }
            )

            HStack {
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    subtitle: notifications.notificationsEnabled ? "Enabled" : "Disabled"
                )
                Spacer()
                Toggle("", isOn: $notifications.notificationsEnabled)
                    .labelsHidden()
            }
            .onChange(of: notifications.notificationsEnabled) { oldValue, newValue in
                if newValue {
                    notifications.requestAuthorization()
                } else {
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                }
                // Persist the notification preference to UserDefaults
                notifications.saveSettings()
            }
            
            if notifications.notificationsEnabled {
                VStack(spacing: 12) {
                    HStack {
                        SettingsRow(
                            icon: "fork.knife",
                            iconColor: .green,
                            title: "Meal Reminders",
                            subtitle: "Breakfast, lunch, dinner"
                        )
                        Spacer()
                        Toggle("", isOn: $notifications.mealRemindersEnabled)
                            .labelsHidden()
                    }
                    .onChange(of: notifications.mealRemindersEnabled) { oldValue, newValue in
                        notifications.updateMealReminders(newValue)
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "drop.fill",
                            iconColor: .blue,
                            title: "Water Reminders",
                            subtitle: "Stay hydrated"
                        )
                        Spacer()
                        Toggle("", isOn: $notifications.waterRemindersEnabled)
                            .labelsHidden()
                    }
                    .onChange(of: notifications.waterRemindersEnabled) { oldValue, newValue in
                        notifications.updateWaterReminders(newValue)
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "figure.run",
                            iconColor: .purple,
                            title: "Workout Reminders",
                            subtitle: "Stay active"
                        )
                        Spacer()
                        Toggle("", isOn: $notifications.workoutRemindersEnabled)
                            .labelsHidden()
                    }
                    .onChange(of: notifications.workoutRemindersEnabled) { oldValue, newValue in
                        notifications.updateWorkoutReminders(newValue)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }

    // MARK: - Subscription
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription") {
            if purchases.hasActiveSubscription {
                Text("Premium Active")
                    .font(.headline)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    SettingsRow(
                        icon: "crown.fill",
                        iconColor: .yellow,
                        title: "Upgrade to Premium",
                        subtitle: "Unlock all features",
                        showChevron: true
                    )
                }
            }

            SettingsRow(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "Restore Purchases",
                action: {
                    Task {
                        isLoading = true
                        try? await purchases.restorePurchases()
                        isLoading = false
                    }
                }
            )
        }
    }


    // MARK: - Preferences
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            Menu {
                Button("Metric") {
                    unitsPreference = "metric"
                }
                Button("Imperial") {
                    unitsPreference = "imperial"
                }
            } label: {
                SettingsRow(
                    icon: "ruler.fill",
                    iconColor: .blue,
                    title: "Units",
                    subtitle: currentUnits.rawValue,
                    showChevron: true
                )
            }

            Menu {
                Button("System") {
                    darkModePreference = "system"
                    updateColorScheme()
                }
                Button("Light") {
                    darkModePreference = "light"
                    updateColorScheme()
                }
                Button("Dark") {
                    darkModePreference = "dark"
                    updateColorScheme()
                }
            } label: {
                SettingsRow(
                    icon: "moon.fill",
                    iconColor: .indigo,
                    title: "Dark Mode",
                    subtitle: currentDarkMode.rawValue,
                    showChevron: true
                )
            }
        }
    }

    // MARK: - Privacy
    private var privacySection: some View {
        SettingsSection(title: "Privacy & Data") {
            SettingsRow(
                icon: "square.and.arrow.up.fill",
                iconColor: .blue,
                title: "Export Data",
                action: { 
                    showingExportData = true
                    exportData()
                }
            )

            SettingsRow(
                icon: "trash.fill",
                iconColor: .red,
                title: "Delete Account",
                action: { showingDeleteAccount = true }
            )

            Button(role: .destructive) {
                auth.logout()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Actions
    private func deleteAccount() {
        isLoading = true
        Task {
            do {
                let _: EmptyResponse = try await NetworkManager.shared.request(
                    "auth/account",
                    method: "DELETE",
                    body: nil
                )
                
                await MainActor.run {
                    isLoading = false
                    auth.logout()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func exportData() {
        isLoading = true
        showingExportData = true
        Task {
            do {
                // Use dictionary request method for export data
                let exportData = try await NetworkManager.shared.requestDictionary(
                    "auth/export",
                    method: "GET",
                    body: nil
                )
                
                // Convert to JSON string
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                // Create file and share
                await MainActor.run {
                    isLoading = false
                    showingExportData = false
                    shareData(jsonString: jsonString)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showingExportData = false
                    errorMessage = "Failed to export data: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func shareData(jsonString: String) {
        let activityVC = UIActivityViewController(
            activityItems: [jsonString],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func updateColorScheme() {
        // Color scheme is handled by the app's environment
        // The preference is stored and can be read by the root view
        NotificationCenter.default.post(name: NSNotification.Name("ColorSchemeChanged"), object: nil)
    }
}
