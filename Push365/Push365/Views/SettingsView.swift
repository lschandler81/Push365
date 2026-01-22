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
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            if let userSettings {
                ScrollView {
                    VStack(spacing: 20) {
                        // Notifications Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(DSFont.sectionHeader)
                                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            Toggle("Enable Notifications", isOn: Binding(
                                get: { userSettings.notificationsEnabled },
                                set: { newValue in
                                    userSettings.notificationsEnabled = newValue
                                    handleNotificationToggle(enabled: newValue, settings: userSettings)
                                }
                            ))
                            .tint(DSColor.accent)
                            .font(DSFont.button)
                            .foregroundStyle(DSColor.textPrimary)
                            
                            if userSettings.notificationsEnabled {
                                Divider()
                                    .background(DSColor.textSecondary.opacity(0.2))
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.orange.opacity(0.9))
                                            .frame(width: 28)
                                        
                                        Text("Morning")
                                            .font(DSFont.subheadline)
                                            .foregroundStyle(DSColor.textSecondary)
                                        
                                        Spacer()
                                        
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { userSettings.morningTime },
                                                set: { newTime in
                                                    userSettings.morningTime = newTime
                                                    handleTimeChange(settings: userSettings)
                                                }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .labelsHidden()
                                        .tint(DSColor.accent)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.blue.opacity(0.8))
                                            .frame(width: 28)
                                        
                                        Text("Reminder")
                                            .font(DSFont.subheadline)
                                            .foregroundStyle(DSColor.textSecondary)
                                        
                                        Spacer()
                                        
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { userSettings.reminderTime },
                                                set: { newTime in
                                                    userSettings.reminderTime = newTime
                                                    handleTimeChange(settings: userSettings)
                                                }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .labelsHidden()
                                        .tint(DSColor.accent)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.card)
                                .fill(DSColor.surface)
                        )
                        .padding(.horizontal, 20)
                        
                        // Progress Mode Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Progress Mode")
                                .font(DSFont.sectionHeader)
                                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Progress Mode", selection: Binding(
                                    get: { userSettings.mode },
                                    set: { newMode in
                                        userSettings.mode = newMode
                                        try? modelContext.save()
                                    }
                                )) {
                                    ForEach(ProgressMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(userSettings.mode.shortDescription)
                                        .font(DSFont.caption)
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("Changes apply from tomorrow.")
                                        .font(DSFont.caption)
                                        .foregroundStyle(DSColor.textSecondary.opacity(0.5))
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.card)
                                .fill(DSColor.surface)
                        )
                        .padding(.horizontal, 20)
                        
                        // Display Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Display")
                                .font(DSFont.sectionHeader)
                                .foregroundStyle(DSColor.textSecondary.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            // Date Format Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date Format")
                                    .font(DSFont.subheadline)
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                Menu {
                                    ForEach(DateFormatPreference.allCases) { preference in
                                        Button(action: {
                                            userSettings.dateFormatPreference = preference
                                        }) {
                                            HStack {
                                                Text(preference.displayName)
                                                if userSettings.dateFormatPreference == preference {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(userSettings.dateFormatPreference.displayName)
                                            .font(DSFont.button)
                                            .foregroundStyle(DSColor.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DSColor.textSecondary)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(DSColor.background)
                                    )
                                }
                            }
                            
                            Divider()
                                .background(DSColor.textSecondary.opacity(0.2))
                            
                            // Preview
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview")
                                    .font(DSFont.caption)
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                Text(DateDisplayFormatter.shortDateString(for: Date(), preference: userSettings.dateFormatPreference))
                                    .font(DSFont.button)
                                    .foregroundStyle(DSColor.textPrimary)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: DSRadius.card)
                                .fill(DSColor.surface)
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                }
                .background(DSColor.background.ignoresSafeArea())
                .navigationTitle("Settings")
                .toolbarColorScheme(.dark, for: .navigationBar)
            } else {
                ProgressView()
                    .tint(DSColor.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DSColor.background)
                    .task {
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
            Task {
                do {
                    let today = try progressStore.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
                    notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
                } catch {
                    print("Error scheduling notifications: \(error)")
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
        }
    }
    
    private func handleTimeChange(settings: UserSettings) {
        do {
            try modelContext.save()
            Task {
                do {
                    let today = try progressStore.getOrCreateDayRecord(for: Date(), modelContext: modelContext)
                    notificationManager.scheduleNotifications(for: Date(), settings: settings, record: today)
                } catch {
                    print("Error rescheduling notifications: \(error)")
                }
            }
        } catch {
            print("Error saving settings: \(error)")
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
