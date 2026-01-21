//
//  Push365App.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

@main
struct Push365App: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            UserSettings.self,
            DayRecord.self,
            LogEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, avoid silently wiping user data in production.
            print("ModelContainer initialization failed: \(error)")

            #if DEBUG
            print("DEBUG: Attempting to delete and recreate the SwiftData store.")

            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))

            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to initialize ModelContainer after cleanup: \(error)")
            }
            #else
            // In release builds, fail loudly so we don't destroy a real user's data.
            fatalError("Failed to initialize ModelContainer: \(error)")
            #endif
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var hasCheckedOnboarding = false
    @State private var showMainApp = false
    
    var body: some View {
        Group {
            if !hasCheckedOnboarding {
                // Loading state while checking
                Color(red: 0x1A/255, green: 0x20/255, blue: 0x28/255)
                    .ignoresSafeArea()
            } else if showMainApp {
                MainTabView()
            } else {
                WelcomeView(onComplete: {
                    showMainApp = true
                })
            }
        }
        .task {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        if let userSettings = settings.first {
            showMainApp = userSettings.hasCompletedOnboarding
        } else {
            showMainApp = false
        }
        hasCheckedOnboarding = true
    }
}
