import SwiftUI

// Legacy SettingsView - now redirects to ProfileView
// Keeping for backward compatibility
struct SettingsView: View {
    var body: some View {
        ProfileView()
    }
}
