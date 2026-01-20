//
//  DayCalculator.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation

enum DayCalculator {
    
    /// Returns the start-of-day (00:00:00) for the given date in the specified calendar/timezone
    static func dateKey(for date: Date, calendar: Calendar = .current) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /// Computes the day number (1-indexed) since startDate
    /// - Returns: Number of days elapsed + 1, clamped to minimum of 1
    /// - Example: If startDate is Jan 1 and date is Jan 1, returns 1. Jan 2 returns 2, etc.
    static func dayNumber(for date: Date, startDate: Date, calendar: Calendar = .current) -> Int {
        let normalizedDate = dateKey(for: date, calendar: calendar)
        let normalizedStart = dateKey(for: startDate, calendar: calendar)
        
        let components = calendar.dateComponents([.day], from: normalizedStart, to: normalizedDate)
        let daysSince = components.day ?? 0
        
        // Day number is 1-indexed (day 0 = day 1, day 1 = day 2, etc.)
        // Clamp to minimum of 1 if date is before startDate
        return max(1, daysSince + 1)
    }
    
    /// Returns the strict mode target: same as day number
    /// - Parameter dayNumber: The current day number
    /// - Returns: The push-up target for that day (max of 1 and dayNumber)
    static func strictTarget(for dayNumber: Int) -> Int {
        return max(1, dayNumber)
    }
    
    /// Returns today's day number relative to the start date
    static func todayDayNumber(startDate: Date, calendar: Calendar = .current) -> Int {
        return dayNumber(for: Date(), startDate: startDate, calendar: calendar)
    }
    
    /// Returns January 1st at 00:00:00 for the year of the given date
    static func startOfYear(for date: Date, calendar: Calendar = .current) -> Date {
        let year = calendar.component(.year, from: date)
        let components = DateComponents(year: year, month: 1, day: 1)
        return calendar.date(from: components) ?? date
    }
}
