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

        // Standard on-device SwiftData store (no App Groups).
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, avoid silently wiping user data in production.
            print("ModelContainer initialization failed: \(error)")

            #if DEBUG
            // In DEBUG only, recreate the container so development can continue.
            print("DEBUG: Recreating the SwiftData store.")
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to initialize ModelContainer in DEBUG after retry: \(error)")
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
