//
//  LogEntry.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation
import SwiftData

@Model
final class LogEntry {
    var id: UUID
    
    /// When this log entry was created
    var timestamp: Date
    
    /// Number of push-ups in this log entry
    var amount: Int
    
    /// Parent day record (optional inverse relationship)
    var dayRecord: DayRecord?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        amount: Int,
        dayRecord: DayRecord? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.dayRecord = dayRecord
    }
}
