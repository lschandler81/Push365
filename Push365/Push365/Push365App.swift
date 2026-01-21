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
            // If migration fails, delete the store and recreate
            print("ModelContainer initialization failed, attempting to delete and recreate: \(error)")
            
            // Delete the store files
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            
            // Try again
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to initialize ModelContainer after cleanup: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
