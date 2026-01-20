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
    private let notificationManager = NotificationManager()
    
    private var userSettings: UserSettings? {
        // Return existing settings if found
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            if let userSettings {
                List {
                    Section("Notifications") {
                        Toggle("Enable Notifications", isOn: Binding(
                            get: { userSettings.notificationsEnabled },
                            set: { newValue in
                                userSettings.notificationsEnabled = newValue
                                handleNotificationToggle(enabled: newValue, settings: userSettings)
                            }
                        ))
                        
                        if userSettings.notificationsEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Morning: \(formatTime(hour: userSettings.morningHour, minute: userSettings.morningMinute))")
                                    .font(DSFont.subheadline)
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                Text("Reminder: \(formatTime(hour: userSettings.reminderHour, minute: userSettings.reminderMinute))")
                                    .font(DSFont.subheadline)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                        }
                    }
                    
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
                                .font(DSFont.caption)
                                .foregroundStyle(DSColor.textSecondary)
                            
                            Text(DateDisplayFormatter.shortDateString(for: Date(), preference: userSettings.dateFormatPreference))
                                .font(DSFont.body)
                                .foregroundStyle(DSColor.textPrimary)
                        }
                    }
                }
                .navigationTitle("Settings")
            } else {
                ProgressView()
                    .task {
                        // Initialize settings on first load
                        try? await Task {
                            _ = try progressStore.getOrCreateSettings(modelContext: modelContext)
                        }.value
                    }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func handleNotificationToggle(enabled: Bool, settings: UserSettings) {
        if enabled {
            // Reschedule today's notifications
            Task {
                do {
                    let today = try progressStore.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
                    notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
                } catch {
                    print("Error scheduling notifications: \(error)")
                }
            }
        } else {
            // Cancel all notifications
            notificationManager.cancelAllNotifications()
        }
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        let components = DateComponents(hour: hour, minute: minute)
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, DayRecord.self, LogEntry.self], inMemory: true)
}
