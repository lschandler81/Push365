#if false
//
//  WatchSyncService.swift
//  Push365
//
//  Bridges WatchConnectivity ↔ SwiftData (phone is source of truth)
//

import Foundation
import Combine
import SwiftData

@MainActor
final class WatchSyncService: ObservableObject {

    private let store = ProgressStore()
    private let connectivity = PhoneConnectivityManager.shared
    private var isStarted = false

    func start(modelContext: ModelContext) {
        guard !isStarted else { return }
        isStarted = true

        connectivity.setActionHandler { [weak self] action in
            guard let self else { return }
            await self.handleWatchAction(action, modelContext: modelContext)
        }
        
        connectivity.setStateProvider { [weak self] () async -> WatchDayState? in
            guard let self else { return nil }
            return await self.getCurrentState(modelContext: modelContext)
        }
    }

    private func handleWatchAction(_ action: WatchAction, modelContext: ModelContext) async {
        do {
            switch action {
            case .logPushups(let amount, _):
                try store.addLog(amount: amount, date: Date(), modelContext: modelContext)

            case .undoLastLog:
                try store.undoLastLog(date: Date(), modelContext: modelContext)
            }

            await pushCurrentState(modelContext: modelContext)

        } catch {
            print("[WatchSyncService] Failed to handle action \(action): \(error)")
        }
    }

    func pushCurrentState(modelContext: ModelContext) async {
        if let state = await getCurrentState(modelContext: modelContext) {
            connectivity.sendDayState(state)
        }
    }
    
    private func getCurrentState(modelContext: ModelContext) async -> WatchDayState? {
        do {
            let today = try store.getOrCreateDayRecord(for: Date(), modelContext: modelContext)

            return WatchDayState(
                dayNumber: today.dayNumber,
                target: today.target,
                completed: today.completed,
                remaining: today.remaining,
                isComplete: today.isComplete,
                canUndo: !today.logs.isEmpty,
                timestamp: Date()
            )

        } catch {
            print("[WatchSyncService] Failed to get current state: \(error)")
            return nil
        }
    }
}
#endif
