import Foundation
import WatchConnectivity

extension Notification.Name {
    static let watchSnapshotUpdated = Notification.Name("watchSnapshotUpdated")
}

final class WatchSyncReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchSyncReceiver()

    private override init() {
        super.init()
        activateSessionIfPossible()
    }

    private func activateSessionIfPossible() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func handlePayload(_ payload: [String: Any]) {
        if let shouldClear = payload["clearSnapshot"] as? Bool, shouldClear {
            WidgetDataStore.clear()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .watchSnapshotUpdated, object: nil)
            }
            return
        }
        guard let data = payload["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return
        }
        WidgetDataStore.save(snapshot)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .watchSnapshotUpdated, object: nil)
        }
    }

    func sendLog(amount: Int) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.isCompanionAppInstalled else { return }

        let payload: [String: Any] = ["logAmount": amount]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }

        session.transferUserInfo(payload)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            NSLog("❌ WatchSyncReceiver activation error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handlePayload(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handlePayload(userInfo)
    }
}
