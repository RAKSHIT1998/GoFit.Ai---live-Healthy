#if os(watchOS)
import SwiftUI

@main
struct GoFitWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchDashboardView()
        }
    }
}
#endif
