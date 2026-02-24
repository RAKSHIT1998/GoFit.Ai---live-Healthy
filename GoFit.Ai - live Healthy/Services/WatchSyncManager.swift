import Foundation
import WatchConnectivity

final class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var activationState: WCSessionActivationState = .notActivated

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        Task { @MainActor in
            self.updateStatus(session)
        }
    }

    func sendNutritionUpdate(_ payload: WatchNutritionPayload) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            try session.updateApplicationContext(["nutrition": data])
        } catch {
            print("❌ Failed to send nutrition to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateStatus(session)
        }
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateStatus(session)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let action = message["action"] as? String else { return }
        Task { @MainActor in
            switch action {
            case "openScanner":
                NotificationCenter.default.post(name: .openMealScannerFromWatch, object: nil)
            case "openWaterLog":
                NotificationCenter.default.post(name: .openWaterLogFromWatch, object: nil)
            case "logWater":
                if let amount = message["amount"] as? Double, amount > 0 {
                    WaterIntakeManager.shared.logWater(amount)
                }
            default:
                break
            }
        }
    }

    @MainActor
    private func updateStatus(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        activationState = session.activationState
    }
}

extension Notification.Name {
    static let openMealScannerFromWatch = Notification.Name("openMealScannerFromWatch")
    static let openWaterLogFromWatch = Notification.Name("openWaterLogFromWatch")
}
