//
//  GoFitAiApp.swift
//  GoFit.Ai - live Healthy
//

import SwiftUI
import SwiftData

@main
struct GoFitAiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("darkModePreference") private var darkModePreference: String = "system"
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // Initialize notification service
                    _ = NotificationService.shared
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private var colorScheme: ColorScheme? {
        switch darkModePreference.lowercased() {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}
