//
//  WatchConnectivityManager.swift
//  Push365
//
//  Created by Lee Chandler on 22/01/2026.
//

import Foundation
import WatchConnectivity

/// Phone-side connectivity manager
@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()
    
    @Published var isReachable = false
    @Published var isWatchAppInstalled = false
    
    private let session: WCSession
    private var actionHandler: ((WatchAction) async -> Void)?
    
    private override init() {
        self.session = WCSession.default
        super.init()
        
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }
    
    func setActionHandler(_ handler: @escaping (WatchAction) async -> Void) {
        self.actionHandler = handler
    }
    
    /// Send current day state to watch
    func sendDayState(_ state: WatchDayState) {
        guard session.isReachable else {
            // Queue for later if watch not reachable
            try? session.updateApplicationContext(state.toDictionary())
            return
        }
        
        session.sendMessage(state.toDictionary(), replyHandler: nil) { error in
            print("[Phone] Failed to send day state: \(error.localizedDescription)")
            // Fallback to application context
            try? self.session.updateApplicationContext(state.toDictionary())
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isReachable = session.isReachable
            isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            guard let action = WatchAction.from(message) else {
                replyHandler(["error": "Invalid action"])
                return
            }
            
            // Process action
            await actionHandler?(action)
            
            // Reply with success (watch will get updated state via sendDayState)
            replyHandler(["success": true])
        }
    }
}

// MARK: - Watch Actions

enum WatchAction: Codable {
    case logPushups(amount: Int, timestamp: Date)
    case undoLastLog(timestamp: Date)
    
    func toDictionary() -> [String: Any] {
        switch self {
        case .logPushups(let amount, let timestamp):
            return [
                "action": "log",
                "amount": amount,
                "timestamp": timestamp.timeIntervalSince1970
            ]
        case .undoLastLog(let timestamp):
            return [
                "action": "undo",
                "timestamp": timestamp.timeIntervalSince1970
            ]
        }
    }
    
    static func from(_ dict: [String: Any]) -> WatchAction? {
        guard let actionType = dict["action"] as? String,
              let timestampInterval = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        
        switch actionType {
        case "log":
            guard let amount = dict["amount"] as? Int else { return nil }
            return .logPushups(amount: amount, timestamp: timestamp)
        case "undo":
            return .undoLastLog(timestamp: timestamp)
        default:
            return nil
        }
    }
}

// MARK: - Watch Day State

struct WatchDayState: Codable {
    let dayNumber: Int
    let target: Int
    let completed: Int
    let remaining: Int
    let isComplete: Bool
    let canUndo: Bool
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "dayNumber": dayNumber,
            "target": target,
            "completed": completed,
            "remaining": remaining,
            "isComplete": isComplete,
            "canUndo": canUndo,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    static func from(_ dict: [String: Any]) -> WatchDayState? {
        guard let dayNumber = dict["dayNumber"] as? Int,
              let target = dict["target"] as? Int,
              let completed = dict["completed"] as? Int,
              let remaining = dict["remaining"] as? Int,
              let isComplete = dict["isComplete"] as? Bool,
              let canUndo = dict["canUndo"] as? Bool,
              let timestampInterval = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        
        return WatchDayState(
            dayNumber: dayNumber,
            target: target,
            completed: completed,
            remaining: remaining,
            isComplete: isComplete,
            canUndo: canUndo,
            timestamp: Date(timeIntervalSince1970: timestampInterval)
        )
    }
}
