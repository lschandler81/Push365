//
//  HomeView.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    
    private let progressStore = ProgressStore()
    
    private var userSettings: UserSettings? {
        // Return existing settings if found
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let userSettings {
                    // Header with formatted date
                    VStack(spacing: 4) {
                        Text(DateDisplayFormatter.headerString(for: Date(), preference: userSettings.dateFormatPreference))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Home Screen")
                            .font(.title)
                    }
                    
                    // Sample date display
                    Text("Today: \(DateDisplayFormatter.shortDateString(for: Date(), preference: userSettings.dateFormatPreference))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Loading...")
                }
            }
            .navigationTitle("Push365")
            .task {
                // Initialize settings on first load
                if settings.isEmpty {
                    _ = try? progressStore.getOrCreateSettings(modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
