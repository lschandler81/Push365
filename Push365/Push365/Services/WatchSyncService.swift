//
//  WatchSyncService.swift
//  Push365
//
//  Created by Lee Chandler on 22/01/2026.
//

import SwiftUI
import SwiftData

/// Service to integrate WatchConnectivity with SwiftData on phone
@MainActor
final class WatchSyncService: ObservableObject {
    private let store = ProgressStore()
    private let connectivity = PhoneConnectivityManager.shared
    
    func start(modelContext: ModelContext) {
        // Set up action handler
        connectivity.setActionHandler { [weak self] action in
            await self?.handleWatchAction(action, modelContext: modelContext)
        }
    }
    
    /// Handle action from watch and push back authoritative state
    private func handleWatchAction(_ action: WatchAction, modelContext: ModelContext) async {
        do {
            switch action {
            case .logPushups(let amount, _):
                try store.addLog(amount: amount, date: Date(), modelContext: modelContext)
                
            case .undoLastLog:
                try store.undoLastLog(date: Date(), modelContext: modelContext)
            }
            
            // Push back authoritative state
            await pushCurrentState(modelContext: modelContext)
            
        } catch {
            print("[WatchSync] Failed to handle action: \(error)")
        }
    }
    
    /// Push current day state to watch
    func pushCurrentState(modelContext: ModelContext) async {
        do {
            let today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
            
            let state = WatchDayState(
                dayNumber: today.dayNumber,
                target: today.target,
                completed: today.completed,
                remaining: today.remaining,
                isComplete: today.isComplete,
                canUndo: !today.logs.isEmpty,
                timestamp: Date()
            )
            
            connectivity.sendDayState(state)
            
        } catch {
            print("[WatchSync] Failed to push state: \(error)")
        }
    }
}
