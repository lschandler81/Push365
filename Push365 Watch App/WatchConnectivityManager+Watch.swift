//
//  WatchConnectivityManager+Watch.swift
//  Push365 Watch App
//
//  Created by Lee Chandler on 22/01/2026.
//

import Foundation
import WatchConnectivity

/// Watch-side connectivity manager
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var dayState: WatchDayState?
    @Published var isReachable = false
    @Published var isSyncing = false
    
    private let session: WCSession
    private var pendingActions: [WatchAction] = []
    private var optimisticState: WatchDayState?
    
    private override init() {
        self.session = WCSession.default
        super.init()
        
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }
    
    /// Request initial state from phone
    func requestInitialState() {
        session.sendMessage(["request": "initialState"], replyHandler: { [weak self] reply in
            Task { @MainActor [weak self] in
                if let state = WatchDayState.from(reply) {
                    self?.dayState = state
                    self?.optimisticState = state
                }
            }
        })
    }
    
    /// Optimistically log pushups
    func logPushups(_ amount: Int) {
        guard let currentState = dayState, !currentState.isComplete else { return }
        
        // Create action
        let action = WatchAction.logPushups(amount: amount, clientTimestamp: Date())
        pendingActions.append(action)
        
        // Optimistic update
        let cappedAmount = min(amount, currentState.remaining)
        let newCompleted = currentState.completed + cappedAmount
        let newRemaining = max(0, currentState.target - newCompleted)
        let newIsComplete = newCompleted >= currentState.target
        
        optimisticState = WatchDayState(
            dayNumber: currentState.dayNumber,
            target: currentState.target,
            completed: newCompleted,
            remaining: newRemaining,
            isComplete: newIsComplete,
            canUndo: true,
            timestamp: Date()
        )
        dayState = optimisticState
        
        // Send to phone
        sendAction(action)
    }
    
    /// Optimistically undo last log
    func undoLastLog() {
        guard let currentState = dayState, currentState.canUndo else { return }
        
        // Create action
        let action = WatchAction.undoLastLog
        pendingActions.append(action)
        
        // Optimistic update (we don't know exact amount, phone will correct)
        optimisticState = WatchDayState(
            dayNumber: currentState.dayNumber,
            target: currentState.target,
            completed: max(0, currentState.completed - 1), // Estimate
            remaining: min(currentState.target, currentState.remaining + 1),
            isComplete: false,
            canUndo: currentState.completed > 1,
            timestamp: Date()
        )
        dayState = optimisticState
        
        // Send to phone
        sendAction(action)
    }
    
    private func sendAction(_ action: WatchAction) {
        isSyncing = true
        
        guard session.isReachable else {
            // Queue for later
            isSyncing = false
            return
        }
        
        let actionDict = actionToDictionary(action)
        session.sendMessage(actionDict, replyHandler: { [weak self] reply in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isSyncing = false
                
                // Remove from pending
                if let index = self.pendingActions.firstIndex(of: action) {
                    self.pendingActions.remove(at: index)
                }
                
                // Phone will push back authoritative state
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor [weak self] in
                self?.isSyncing = false
                print("[Watch] Failed to send action: \(error.localizedDescription)")
            }
        })
    }
    
    private func retryPendingActions() {
        guard session.isReachable && !pendingActions.isEmpty else { return }
        
        let actionsToRetry = pendingActions
        pendingActions.removeAll()
        
        for action in actionsToRetry {
            sendAction(action)
        }
    }
    
    private func actionToDictionary(_ action: WatchAction) -> [String: Any] {
        switch action {
        case .logPushups(let amount, let clientTimestamp):
            return [
                "type": "logPushups",
                "amount": amount,
                "clientTimestamp": clientTimestamp.timeIntervalSince1970
            ]
        case .undoLastLog:
            return ["type": "undoLastLog"]
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isReachable = session.isReachable
            if activationState == .activated {
                requestInitialState()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if isReachable {
                retryPendingActions()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            // Received authoritative state from phone
            if let state = WatchDayState.from(message) {
                self.dayState = state
                self.optimisticState = state
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            // Background state update
            if let state = WatchDayState.from(applicationContext) {
                self.dayState = state
                self.optimisticState = state
            }
        }
    }
}
