//
//  ProgressStore.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation
import SwiftData

@MainActor
final class ProgressStore {
    
    // MARK: - User Settings
    
    /// Fetches existing UserSettings or creates a default one
    /// - Parameter modelContext: The SwiftData model context
    /// - Returns: UserSettings instance (existing or newly created)
    /// - Throws: SwiftData errors
    func getOrCreateSettings(modelContext: ModelContext) throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        let existing = try modelContext.fetch(descriptor)
        
        if let settings = existing.first {
            return settings
        }
        
        // Create default settings
        let today = Calendar.current.startOfDay(for: Date())
        let newSettings = UserSettings(
            startDate: today,
            programStartDate: today,
            modeRaw: "strict",
            notificationsEnabled: true,
            morningHour: 8,
            morningMinute: 0,
            reminderHour: 18,
            reminderMinute: 0,
            dateFormatPreferenceRaw: "automatic"
        )
        
        modelContext.insert(newSettings)
        try modelContext.save()
        
        return newSettings
    }
    
    // MARK: - Day Records
    
    /// Fetches existing DayRecord for a date or creates a new one
    /// - Parameters:
    ///   - date: The date to fetch/create record for
    ///   - modelContext: The SwiftData model context
    /// - Returns: DayRecord instance (existing or newly created)
    /// - Throws: SwiftData errors
    func getOrCreateDayRecord(for date: Date, modelContext: ModelContext) throws -> DayRecord {
        // Get settings to calculate day number and target
        var settings = try getOrCreateSettings(modelContext: modelContext)
        
        // Evaluate missed days and update streak if necessary
        StreakCalculator.evaluateMissedDays(today: date, settings: &settings, calendar: .current)
        try modelContext.save()
        
        // Normalize date to start-of-day
        let dateKey = DayCalculator.dateKey(for: date)
        
        // Try to fetch existing record
        let predicate = #Predicate<DayRecord> { record in
            record.dateKey == dateKey
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        
        if let record = existing.first {
            return record
        }
        
        // Create new record
        let dayNumber = DayCalculator.dayNumber(for: dateKey, startDate: settings.programStartDate)
        let target = DayCalculator.resolvedTarget(for: date, dayNumber: dayNumber, settings: settings)
        
        let newRecord = DayRecord(
            dateKey: dateKey,
            dayNumber: dayNumber,
            target: target,
            completed: 0
        )
        
        modelContext.insert(newRecord)
        try modelContext.save()
        
        return newRecord
    }
    
    // MARK: - Logging
    
    /// Adds a log entry for the specified date
    /// - Parameters:
    ///   - amount: Number of push-ups (will be clamped to remaining capacity)
    ///   - date: The date to log for (defaults to now)
    ///   - modelContext: The SwiftData model context
    /// - Throws: SwiftData errors
    func addLog(amount: Int, date: Date = Date(), modelContext: ModelContext) throws {
        // Get or create the day record
        let record = try getOrCreateDayRecord(for: date, modelContext: modelContext)
        
        // Track completion state before logging
        let wasComplete = record.isComplete
        
        // Calculate remaining capacity
        let remaining = max(0, record.target - record.completed)
        
        // If target already met, do nothing
        guard remaining > 0 else {
            return
        }
        
        // Cap amount to remaining capacity
        let amountToLog = min(max(1, amount), remaining)
        
        // Create log entry
        let logEntry = LogEntry(
            timestamp: Date(),
            amount: amountToLog,
            dayRecord: record
        )
        
        modelContext.insert(logEntry)
        record.logs.append(logEntry)
        
        // Recompute completed
        recomputeCompleted(for: record)
        
        // If day just became complete, record completion for streak and flexible mode
        if !wasComplete && record.isComplete {
            var settings = try getOrCreateSettings(modelContext: modelContext)
            StreakCalculator.recordCompletion(for: date, settings: &settings, calendar: .current)
            
            // Track completion for flexible mode
            let dateKey = DayCalculator.dateKey(for: date)
            settings.lastCompletedTarget = record.target
            settings.lastCompletedDateKey = dateKey
        }
        
        try modelContext.save()
    }
    
    /// Removes the most recent log entry for the specified date
    /// - Parameters:
    ///   - date: The date to undo log for
    ///   - modelContext: The SwiftData model context
    /// - Throws: SwiftData errors
    func undoLastLog(date: Date = Date(), modelContext: ModelContext) throws {
        // Get the day record
        let record = try getOrCreateDayRecord(for: date, modelContext: modelContext)
        
        // Find the most recent log by timestamp
        guard let lastLog = record.logs.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return // No logs to undo
        }
        
        // Remove the log
        if let index = record.logs.firstIndex(where: { $0.id == lastLog.id }) {
            record.logs.remove(at: index)
        }
        modelContext.delete(lastLog)
        
        // Recompute completed
        recomputeCompleted(for: record)
        
        // Note: v1 behavior - we do NOT roll back streak history when undoing.
        // Streak is based on completion events; retroactive changes are not applied.
        // If a day becomes incomplete after undo, the streak remains as-is until
        // the next evaluation or completion event.
        
        try modelContext.save()
    }
    
    // MARK: - Helper Methods
    
    /// Recomputes the completed count by summing all log amounts
    /// - Parameter record: The DayRecord to recompute
    func recomputeCompleted(for record: DayRecord) {
        record.completed = record.logs.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Progress Analytics
    
    /// Fetches all DayRecords sorted by dateKey ascending
    /// - Parameter modelContext: The SwiftData model context
    /// - Returns: Array of all DayRecords sorted by date
    func allRecords(modelContext: ModelContext) throws -> [DayRecord] {
        var descriptor = FetchDescriptor<DayRecord>(
            sortBy: [SortDescriptor(\.dateKey, order: .forward)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }
    
    /// Calculates total push-ups for lifetime and year-to-date
    /// - Parameters:
    ///   - records: Array of DayRecords
    ///   - calendar: Calendar to use for year comparison
    /// - Returns: Tuple of (lifetime, yearToDate) totals
    func totals(records: [DayRecord], calendar: Calendar = .current) -> (lifetime: Int, yearToDate: Int) {
        let currentYear = calendar.component(.year, from: Date())
        
        var lifetime = 0
        var yearToDate = 0
        
        for record in records {
            lifetime += record.completed
            
            let recordYear = calendar.component(.year, from: record.dateKey)
            if recordYear == currentYear {
                yearToDate += record.completed
            }
        }
        
        return (lifetime, yearToDate)
    }
    
    /// Calculates current streak (consecutive completed days ending today or yesterday)
    /// - Parameters:
    ///   - records: Array of DayRecords sorted by dateKey
    ///   - todayKey: Today's dateKey (start of day)
    ///   - calendar: Calendar to use
    /// - Returns: Current streak count
    func currentStreak(records: [DayRecord], todayKey: Date, calendar: Calendar = .current) -> Int {
        guard !records.isEmpty else { return 0 }
        
        // Start from today and work backwards
        var currentDate = todayKey
        var streak = 0
        
        // Check if today exists and is complete
        if let todayRecord = records.first(where: { $0.dateKey == todayKey }) {
            if todayRecord.isComplete {
                streak = 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                // Today exists but incomplete, start from yesterday
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
        } else {
            // No record for today, start from yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // Continue counting backwards
        while let record = records.first(where: { $0.dateKey == currentDate }) {
            if record.isComplete {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Calculates the longest streak in history
    /// - Parameters:
    ///   - records: Array of DayRecords sorted by dateKey
    ///   - calendar: Calendar to use
    /// - Returns: Longest streak count
    func longestStreak(records: [DayRecord], calendar: Calendar = .current) -> Int {
        guard !records.isEmpty else { return 0 }
        
        var maxStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for record in records where record.isComplete {
            if let prevDate = previousDate {
                // Check if this record is consecutive (1 day after previous)
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: prevDate),
                   calendar.isDate(nextDay, inSameDayAs: record.dateKey) {
                    currentStreak += 1
                } else {
                    // Streak broken, start new streak
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                // First completed day
                currentStreak = 1
            }
            
            previousDate = record.dateKey
        }
        
        // Don't forget to check the final streak
        maxStreak = max(maxStreak, currentStreak)
        
        return maxStreak
    }
}
