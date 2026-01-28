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
enum ProgressMode: String, Codable, CaseIterable, Identifiable {
    case strict
    case flexible
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .strict:
            return "Standard Mode"
        case .flexible:
            return "Adaptive Mode"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .strict:
            return "Your target increases by one every day, no matter what."
        case .flexible:
            return "Your target increases when you complete the previous day."
        }
    }
}

@Model
final class UserSettings {
    var id: UUID
    var createdAt: Date
    
    // Core settings
    var startDate: Date
    var programStartDate: Date
    var trackingStartDate: Date?
    var modeRaw: String
    
    // Notifications
    var notificationsEnabled: Bool
    var morningHour: Int
    var morningMinute: Int
    var reminderHour: Int
    var reminderMinute: Int
    
    // Display
    var dateFormatPreferenceRaw: String
    
    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDateKey: Date?
    var lastStreakEvaluatedDateKey: Date?
    
    // Flexible mode tracking
    var lastCompletedTarget: Int
    
    // Recovery Days (limited fallback option to preserve continuity)
    var protocolDaysUsed: Int
    var protocolDayLimit: Int
    
    // Onboarding
    var hasCompletedOnboarding: Bool
    
    // User profile (optional)
    var firstName: String?
    var displayName: String? // Deprecated - migrated to firstName
    var dateOfBirth: Date?
    
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
            ProgressMode(rawValue: modeRaw) ?? .flexible
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
        programStartDate: Date? = nil,
        trackingStartDate: Date? = nil,
        modeRaw: String = "flexible",
        notificationsEnabled: Bool = true,
        morningHour: Int = 8,
        morningMinute: Int = 0,
        reminderHour: Int = 18,
        reminderMinute: Int = 0,
        dateFormatPreferenceRaw: String = "automatic",
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDateKey: Date? = nil,
        lastStreakEvaluatedDateKey: Date? = nil,
        lastCompletedTarget: Int = 0,
        protocolDaysUsed: Int = 0,
        protocolDayLimit: Int = 5,
        hasCompletedOnboarding: Bool = false,
        firstName: String? = nil,
        displayName: String? = nil,
        dateOfBirth: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startDate = startDate
        self.programStartDate = programStartDate ?? startDate
        self.trackingStartDate = trackingStartDate
        self.modeRaw = modeRaw
        self.notificationsEnabled = notificationsEnabled
        self.morningHour = morningHour
        self.morningMinute = morningMinute
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.dateFormatPreferenceRaw = dateFormatPreferenceRaw
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDateKey = lastCompletedDateKey
        self.lastStreakEvaluatedDateKey = lastStreakEvaluatedDateKey
        self.lastCompletedTarget = lastCompletedTarget
        self.protocolDaysUsed = protocolDaysUsed
        self.protocolDayLimit = protocolDayLimit
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.firstName = firstName
        self.displayName = displayName
        self.dateOfBirth = dateOfBirth
        
        // Migrate displayName to firstName if needed
        if self.firstName == nil && displayName != nil {
            self.firstName = displayName
        }
    }
}
