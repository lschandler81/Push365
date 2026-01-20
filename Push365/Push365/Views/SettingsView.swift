//
//  SettingsView.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    
    private let progressStore = ProgressStore()
    
    private var userSettings: UserSettings? {
        // Return existing settings if found
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            if let userSettings {
                List {
                    Section("Display") {
                        Picker("Date Format", selection: Binding(
                            get: { userSettings.dateFormatPreference },
                            set: { userSettings.dateFormatPreference = $0 }
                        )) {
                            ForEach(DateFormatPreference.allCases) { preference in
                                Text(preference.displayName)
                                    .tag(preference)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current format:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(DateDisplayFormatter.shortDateString(for: Date(), preference: userSettings.dateFormatPreference))
                                .font(.body)
                        }
                    }
                }
                .navigationTitle("Settings")
            } else {
                ProgressView()
                    .task {
                        // Initialize settings on first load
                        _ = try? progressStore.getOrCreateSettings(modelContext: modelContext)
                    }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
