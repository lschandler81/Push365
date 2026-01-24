//
//  Push365App.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct Push365App: App {
    @State private var modelContainer: ModelContainer?
    @State private var initError: Error?
    
    @State private var logObserver: NSObjectProtocol?
    @State private var snapshotObserver: NSObjectProtocol?
    
    private let phoneSync = PhoneSyncManager.shared
    
    init() {
        _modelContainer = State(initialValue: Self.createModelContainer())
        if _modelContainer.wrappedValue == nil {
            // Error occurred - will be shown in UI
        }
        
        phoneSync.activate()
        
        let center = NotificationCenter.default
        
        logObserver = center.addObserver(forName: .watchRequestedLog, object: nil, queue: .main) { notification in
            guard let amount = notification.userInfo?["amount"] as? Int else { return }
            
            if let container = Self.createModelContainer() {
                let context = ModelContext(container)
                let store = ProgressStore()
                do {
                    try store.addLog(amount: amount, date: Date(), modelContext: context)
                    let settings = try store.getOrCreateSettings(modelContext: context)
                    let today = try store.getOrCreateDayRecord(for: Date(), modelContext: context)
                    let snapshot = DaySnapshot(
                        dayNumber: today.dayNumber,
                        target: today.target,
                        completed: today.completed,
                        remaining: today.remaining,
                        isComplete: today.isComplete,
                        timestamp: Date()
                    )
                    PhoneSyncManager.shared.send(snapshot: snapshot)
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    print("Watch log request error: \(error)")
                }
            }
        }
        
        snapshotObserver = center.addObserver(forName: .watchRequestedSnapshot, object: nil, queue: .main) { _ in
            if let container = Self.createModelContainer() {
                let context = ModelContext(container)
                let store = ProgressStore()
                do {
                    let settings = try store.getOrCreateSettings(modelContext: context)
                    let today = try store.getOrCreateDayRecord(for: Date(), modelContext: context)
                    let snapshot = DaySnapshot(
                        dayNumber: today.dayNumber,
                        target: today.target,
                        completed: today.completed,
                        remaining: today.remaining,
                        isComplete: today.isComplete,
                        timestamp: Date()
                    )
                    PhoneSyncManager.shared.send(snapshot: snapshot)
                } catch {
                    print("Snapshot request error: \(error)")
                }
            }
        }
        
        // Send initial snapshot to watch on launch
        sendSnapshotToWatch()
    }
    
    private func sendSnapshotToWatch() {
        guard let container = Self.createModelContainer() else { return }
        
        let context = ModelContext(container)
        let store = ProgressStore()
        do {
            let today = try store.getOrCreateDayRecord(for: Date(), modelContext: context)
            let snapshot = DaySnapshot(
                dayNumber: today.dayNumber,
                target: today.target,
                completed: today.completed,
                remaining: today.remaining,
                isComplete: today.isComplete,
                timestamp: Date()
            )
            PhoneSyncManager.shared.send(snapshot: snapshot)
        } catch {
            print("Error sending snapshot to watch: \(error)")
        }
    }
    
    static func createModelContainer() -> ModelContainer? {
        let schema = Schema([
            UserSettings.self,
            DayRecord.self,
            LogEntry.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer initialization failed: \(error)")

            // Schema migration issue - delete and recreate store
            print("Attempting to reset data store due to schema migration...")
            
            // Get the default store URL
            let storeURL = modelConfiguration.url
            do {
                // Remove the existing store files
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                    print("Removed old data store at: \(storeURL.path)")
                }
                
                // Try creating container again with fresh store
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Failed to reset and recreate store: \(error)")
                return nil
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                RootView()
                    .preferredColorScheme(.dark)
                    .modelContainer(container)
            } else {
                DataLoadErrorView(onRetry: {
                    modelContainer = Self.createModelContainer()
                })
                .preferredColorScheme(.dark)
            }
        }
    }
}

struct DataLoadErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            // Dark background matching app theme
            Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange.opacity(0.8))
                
                VStack(spacing: 12) {
                    Text("Unable to Load Data")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    
                    Text("We couldn't initialize the app's storage. This may be due to a corrupted database or insufficient storage space.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0x4D/255, green: 0xA3/255, blue: 0xFF/255))
                        )
                }
                .padding(.horizontal, 48)
                .padding(.top, 12)
            }
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    
    var body: some View {
        Group {
            if let userSettings = settings.first, userSettings.hasCompletedOnboarding {
                MainTabView()
            } else {
                WelcomeView(onComplete: {
                    // Onboarding completion is handled by settings update
                })
            }
        }
    }
}
