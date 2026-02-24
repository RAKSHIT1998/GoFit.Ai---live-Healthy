import Foundation
import WatchConnectivity

@MainActor
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
        activationState = session.activationState

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

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        self.activationState = activationState
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["nutrition"] as? Data {
            decodeNutrition(data)
        }
    }

    private func decodeNutrition(_ data: Data) {
        do {
            let payload = try JSONDecoder().decode(WatchNutritionPayload.self, from: data)
            nutrition = payload
        } catch {
            print("❌ Failed to decode nutrition payload: \(error.localizedDescription)")
        }
    }
}
