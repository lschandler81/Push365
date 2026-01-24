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
    
    /// Computes the day number (1-indexed) since programStartDate
    /// - Returns: Number of days elapsed + 1, clamped to minimum of 1
    /// - Example: If programStartDate is Jan 1 and date is Jan 1, returns 1. Jan 2 returns 2, etc.
    static func dayNumber(for date: Date, startDate: Date, calendar: Calendar = .current) -> Int {
        let normalizedDate = dateKey(for: date, calendar: calendar)
        let normalizedStart = dateKey(for: startDate, calendar: calendar)
        
        let components = calendar.dateComponents([.day], from: normalizedStart, to: normalizedDate)
        let daysSince = components.day ?? 0
        
        // Day number is 1-indexed (day 0 = day 1, day 1 = day 2, etc.)
        // Clamp to minimum of 1 if date is before programStartDate
        return max(1, daysSince + 1)
    }
    
    /// Returns the strict mode target: same as day number
    /// - Parameter dayNumber: The current day number
    /// - Returns: The push-up target for that day (max of 1 and dayNumber)
    static func strictTarget(for dayNumber: Int) -> Int {
        return max(1, dayNumber)
    }
    
    /// Resolves the target for a given date based on the current progress mode
    /// - Parameters:
    ///   - date: The date to calculate target for
    ///   - dayNumber: The day number (1-indexed)
    ///   - settings: UserSettings containing mode and completion history
    ///   - calendar: Calendar for date calculations
    /// - Returns: The resolved target for this day
    static func resolvedTarget(for date: Date, dayNumber: Int, settings: UserSettings, calendar: Calendar = .current) -> Int {
        let baseline = max(1, dayNumber)
        
        // Strict mode: target always equals day number
        if settings.mode == .strict {
            print("[Target] mode=\(settings.modeRaw) day=\(dayNumber) lastTarget=\(settings.lastCompletedTarget) lastDate=\(String(describing: settings.lastCompletedDateKey)) => target=\(baseline)")
            return baseline
        }
        
        // Flexible mode
        guard let lastCompletionDate = settings.lastCompletedDateKey else {
            // No completion history - use baseline
            print("[Target] mode=\(settings.modeRaw) day=\(dayNumber) lastTarget=\(settings.lastCompletedTarget) lastDate=nil => target=\(baseline)")
            return baseline
        }
        
        // Check if yesterday was completed
        let today = dateKey(for: date, calendar: calendar)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdayKey = dateKey(for: yesterday, calendar: calendar)
        let lastCompletionKey = dateKey(for: lastCompletionDate, calendar: calendar)
        
        let yesterdayWasCompleted = (lastCompletionKey == yesterdayKey)
        
        let target: Int
        if yesterdayWasCompleted {
            // Yesterday completed - increase to baseline
            target = baseline
        } else {
            // Yesterday NOT completed - repeat last completed target + 1
            target = max(1, settings.lastCompletedTarget + 1)
        }
        
        print("[Target] mode=\(settings.modeRaw) day=\(dayNumber) lastTarget=\(settings.lastCompletedTarget) lastDate=\(String(describing: settings.lastCompletedDateKey)) yesterdayCompleted=\(yesterdayWasCompleted) => target=\(target)")
        return target
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
