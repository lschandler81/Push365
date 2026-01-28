import Foundation
import SwiftData
import WatchConnectivity
import WidgetKit

final class PhoneWatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSyncManager()
    private let store = ProgressStore()

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

    func send(snapshot: WidgetSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.isPaired, session.isWatchAppInstalled else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        let payload: [String: Any] = ["snapshot": data]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }

        session.transferUserInfo(payload)
    }

    func sendClearSnapshot() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.isPaired, session.isWatchAppInstalled else { return }

        let payload: [String: Any] = ["clearSnapshot": true]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }

        session.transferUserInfo(payload)
    }

    private func handleLogRequest(amount: Int) {
        DispatchQueue.main.async {
            guard let container = Push365App.createModelContainer() else { return }
            let context = ModelContext(container)

            do {
                try self.store.addLog(amount: amount, date: Date(), modelContext: context)
                if let settings = try? self.store.getOrCreateSettings(modelContext: context),
                   let today = try? self.store.getOrCreateDayRecord(for: Date(), modelContext: context) {
                    let snapshot = WidgetSnapshot(
                        dayNumber: today.dayNumber,
                        target: today.target,
                        completed: today.completed,
                        remaining: today.remaining,
                        isComplete: today.isComplete,
                        timestamp: Date()
                    )
                    WidgetDataStore.save(snapshot)
                    self.send(snapshot: snapshot)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } catch {
                NSLog("❌ PhoneWatchSyncManager handleLogRequest error: \(error.localizedDescription)")
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            NSLog("❌ PhoneWatchSyncManager activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let shouldClear = message["clearSnapshot"] as? Bool, shouldClear {
            WidgetDataStore.clear()
            return
        }
        if let amount = message["logAmount"] as? Int {
            handleLogRequest(amount: amount)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let shouldClear = userInfo["clearSnapshot"] as? Bool, shouldClear {
            WidgetDataStore.clear()
            return
        }
        if let amount = userInfo["logAmount"] as? Int {
            handleLogRequest(amount: amount)
        }
    }
}
