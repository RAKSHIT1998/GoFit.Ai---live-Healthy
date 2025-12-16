import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var purchases: PurchaseManager
    @StateObject private var healthKit = HealthKitService.shared

    @State private var showingEditProfile = false
    @State private var showingPaywall = false
    @State private var showingDeleteAccount = false
    @State private var showingExportData = false
    @State private var showingChangePassword = false

    @State private var notificationsEnabled = true
    @State private var healthSyncEnabled = true
    @State private var units: UnitSystem = .metric
    @State private var isLoading = false

    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
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
            .background(Color(.systemGroupedBackground))
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
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAccount() }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Export Data", isPresented: $showingExportData) {
                Button("OK") { exportData() }
            } message: {
                Text("Your data export will be emailed to you.")
            }
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
        HStack(spacing: 12) {
            StatCard(icon: "flame.fill", value: "1,450", label: "Calories", color: .orange)
            StatCard(icon: "figure.walk", value: "\(healthKit.todaySteps)", label: "Steps", color: .green)
            StatCard(icon: "timer", value: "12h", label: "Fasting", color: .purple)
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
                    title: "Notifications"
                )
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
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

    // MARK: - Health (FIXED onChange)
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
            // ✅ iOS 17 FIX
            .onChange(of: healthSyncEnabled) {
                if healthSyncEnabled {
                    Task {
                        try? await healthKit.requestAuthorization()
                    }
                }
            }

            SettingsRow(
                icon: "applewatch",
                iconColor: .black,
                title: "Apple Watch",
                subtitle: "Sync activity data",
                action: {
                    Task { try? await healthKit.syncToBackend() }
                }
            )
        }
    }

    // MARK: - Preferences
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            SettingsRow(
                icon: "ruler.fill",
                iconColor: .blue,
                title: "Units",
                subtitle: units.rawValue,
                showChevron: true,
                action: {
                    units = units == .metric ? .imperial : .metric
                }
            )

            SettingsRow(
                icon: "moon.fill",
                iconColor: .indigo,
                title: "Dark Mode",
                subtitle: "System"
            )
        }
    }

    // MARK: - Privacy
    private var privacySection: some View {
        SettingsSection(title: "Privacy & Data") {
            SettingsRow(
                icon: "square.and.arrow.up.fill",
                iconColor: .blue,
                title: "Export Data",
                action: { showingExportData = true }
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
            auth.logout()
            isLoading = false
        }
    }

    private func exportData() {
        isLoading = true
        Task {
            isLoading = false
        }
    }
}
