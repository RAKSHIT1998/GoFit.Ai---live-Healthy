#if os(watchOS)
import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var nutrition: WatchNutritionPayload = .empty
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
            self.activationState = session.activationState
        }

        if let data = session.receivedApplicationContext["nutrition"] as? Data {
            decodeNutrition(data)
        }
    }

    func openScannerOnPhone() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": "openScanner"], replyHandler: nil, errorHandler: nil)
    }

    func openWaterLogOnPhone() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": "openWaterLog"], replyHandler: nil, errorHandler: nil)
    }

    func logWater(amount: Double) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": "logWater", "amount": amount], replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.activationState = activationState
        }
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["nutrition"] as? Data {
            Task { @MainActor in
                self.decodeNutrition(data)
            }
        }
    }

    @MainActor
    private func decodeNutrition(_ data: Data) {
        do {
            let payload = try JSONDecoder().decode(WatchNutritionPayload.self, from: data)
            nutrition = payload
        } catch {
            print("❌ Failed to decode nutrition payload: \(error.localizedDescription)")
        }
    }
}
#endif
