//
//  UserSettings.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation
import SwiftData

/// Date format preference for displaying dates
enum DateFormatPreference: String, CaseIterable, Identifiable {
    case automatic
    case uk
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .uk:
            return "UK (DD/MM/YYYY)"
        }
    }
}

/// Mode preference for push-up progression
enum ProgressMode: String, CaseIterable {
    case strict
    // Future: case flexible
}

@Model
final class UserSettings {
    var id: UUID
    var createdAt: Date
    
    // Core settings
    var startDate: Date
    var modeRaw: String
    
    // Notifications
    var notificationsEnabled: Bool
    var morningHour: Int
    var morningMinute: Int
    var reminderHour: Int
    var reminderMinute: Int
    
    // Display
    var dateFormatPreferenceRaw: String
    
    // MARK: - Computed Properties
    
    /// Morning notification time as Date (today at specified hour/minute)
    var morningTime: Date {
        get {
            let components = DateComponents(hour: morningHour, minute: morningMinute)
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            morningHour = components.hour ?? 8
            morningMinute = components.minute ?? 0
        }
    }
    
    /// Reminder notification time as Date (today at specified hour/minute)
    var reminderTime: Date {
        get {
            let components = DateComponents(hour: reminderHour, minute: reminderMinute)
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 18
            reminderMinute = components.minute ?? 0
        }
    }
    
    /// Computed property for type-safe date format preference
    var dateFormatPreference: DateFormatPreference {
        get {
            DateFormatPreference(rawValue: dateFormatPreferenceRaw) ?? .automatic
        }
        set {
            dateFormatPreferenceRaw = newValue.rawValue
        }
    }
    
    /// Computed property for type-safe progress mode
    var mode: ProgressMode {
        get {
            ProgressMode(rawValue: modeRaw) ?? .strict
        }
        set {
            modeRaw = newValue.rawValue
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        startDate: Date,
        modeRaw: String = "strict",
        notificationsEnabled: Bool = true,
        morningHour: Int = 8,
        morningMinute: Int = 0,
        reminderHour: Int = 18,
        reminderMinute: Int = 0,
        dateFormatPreferenceRaw: String = "automatic"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startDate = startDate
        self.modeRaw = modeRaw
        self.notificationsEnabled = notificationsEnabled
        self.morningHour = morningHour
        self.morningMinute = morningMinute
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.dateFormatPreferenceRaw = dateFormatPreferenceRaw
    }
}
