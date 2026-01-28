//
//  DayRecord.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation
import SwiftData

@Model
final class DayRecord {
    var id: UUID
    
    /// Normalized start-of-day date (used as unique key)
    var dateKey: Date
    
    /// Day number relative to start date (1-indexed)
    var dayNumber: Int
    
    /// Target push-ups for this day
    var target: Int
    
    /// Total completed push-ups
    var completed: Int
    
    /// Whether this day was completed as a Recovery Day
    var isProtocolDay: Bool
    
    /// Log entries for this day
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.dayRecord)
    var logs: [LogEntry]
    
    // MARK: - Computed Properties
    
    /// Remaining push-ups to reach target
    var remaining: Int {
        max(0, target - completed)
    }
    
    /// Whether the day's target has been met
    var isComplete: Bool {
        completed >= target
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        dateKey: Date,
        dayNumber: Int,
        target: Int,
        completed: Int = 0,
        isProtocolDay: Bool = false,
        logs: [LogEntry] = []
    ) {
        self.id = id
        self.dateKey = dateKey
        self.dayNumber = dayNumber
        self.target = target
        self.completed = completed
        self.isProtocolDay = isProtocolDay
        self.logs = logs
    }
}
