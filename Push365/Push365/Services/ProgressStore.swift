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
        let defaultStartDate = DayCalculator.startOfYear(for: Date())
        let newSettings = UserSettings(
            startDate: defaultStartDate,
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
        let settings = try getOrCreateSettings(modelContext: modelContext)
        
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
        let dayNumber = DayCalculator.dayNumber(for: dateKey, startDate: settings.startDate)
        let target = DayCalculator.strictTarget(for: dayNumber)
        
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
    ///   - amount: Number of push-ups (will be clamped to minimum of 1)
    ///   - date: The date to log for (defaults to now)
    ///   - modelContext: The SwiftData model context
    /// - Throws: SwiftData errors
    func addLog(amount: Int, date: Date = Date(), modelContext: ModelContext) throws {
        // Clamp amount to minimum of 1
        let validAmount = max(1, amount)
        
        // Get or create the day record
        let record = try getOrCreateDayRecord(for: date, modelContext: modelContext)
        
        // Create log entry
        let logEntry = LogEntry(
            timestamp: Date(),
            amount: validAmount,
            dayRecord: record
        )
        
        modelContext.insert(logEntry)
        record.logs.append(logEntry)
        
        // Recompute completed
        recomputeCompleted(for: record)
        
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
        
        try modelContext.save()
    }
    
    // MARK: - Helper Methods
    
    /// Recomputes the completed count by summing all log amounts
    /// - Parameter record: The DayRecord to recompute
    func recomputeCompleted(for record: DayRecord) {
        record.completed = record.logs.reduce(0) { $0 + $1.amount }
    }
}
