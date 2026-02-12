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
    @StateObject private var purchaseManager = PurchaseManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var hadExistingStore = false

    init() {
        let storeURL = Self.defaultStoreURL()
        hadExistingStore = FileManager.default.fileExists(atPath: storeURL.path)
        _modelContainer = State(initialValue: Self.createModelContainer())
        _ = PhoneWatchSyncManager.shared
        if _modelContainer.wrappedValue == nil {
            // Error occurred - will be shown in UI
        }
    }

    static func defaultStoreURL() -> URL {
        let schema = Schema([
            UserSettings.self,
            DayRecord.self,
            LogEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return modelConfiguration.url
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
            // Schema migration issue - delete and recreate store

            // Get the default store URL
            let storeURL = modelConfiguration.url
            do {
                // Remove the existing store files
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: storeURL.path) {
                    try fileManager.removeItem(at: storeURL)
                }

                // Try creating container again with fresh store
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                return nil
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                SplashGateView()
                    .preferredColorScheme(.dark)
                    .modelContainer(container)
                    .environmentObject(purchaseManager)
                    .task {
                        await purchaseManager.refreshEntitlements()
                        runLegacySupporterMigrationIfNeeded()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            Task {
                                await purchaseManager.refreshEntitlements()
                                runLegacySupporterMigrationIfNeeded()
                            }
                        }
                    }
            } else {
                DataLoadErrorView(onRetry: {
                    modelContainer = Self.createModelContainer()
                })
                .preferredColorScheme(.dark)
            }
        }
    }

    private func runLegacySupporterMigrationIfNeeded() {
        let defaults = UserDefaults.standard
        let migrationKey = "legacyMigrationComplete"
        let supporterKey = "isSupporter"
        
        guard hadExistingStore else { return }
        guard defaults.bool(forKey: migrationKey) == false else { return }
        
        if defaults.bool(forKey: supporterKey) == false {
            defaults.set(true, forKey: supporterKey)
        }
        defaults.set(true, forKey: migrationKey)
        purchaseManager.isSupporter = defaults.bool(forKey: supporterKey)
    }
}

// MARK: - Splash Gate

struct SplashGateView: View {
    @State private var showSplash = true
    @State private var splashOpacity = 0.0

    // Timing
    private let fadeInDuration: Double = 0.35
    private let holdDuration: Double = 1.5
    private let fadeOutDuration: Double = 0.30

    var body: some View {
        ZStack {
            // While the splash is showing, use a pure black background so a black-backed logo blends in.
            // Once we switch to the app, the normal views handle their own background.
            if showSplash {
                Color.black.ignoresSafeArea()
            }

            if showSplash {
                SplashView()
                    .opacity(splashOpacity)
            } else {
                RootView()
            }
        }
        .onAppear {
            // Start hidden then fade in
            splashOpacity = 0
            withAnimation(.easeOut(duration: fadeInDuration)) {
                splashOpacity = 1
            }

            // Hold, then fade out, then switch
            let fadeOutStart = fadeInDuration + holdDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutStart) {
                withAnimation(.easeIn(duration: fadeOutDuration)) {
                    splashOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Root View

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

// MARK: - Data Load Error View

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
