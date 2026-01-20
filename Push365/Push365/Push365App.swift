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
        do {
            modelContainer = try ModelContainer(
                for: UserSettings.self, DayRecord.self, LogEntry.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
