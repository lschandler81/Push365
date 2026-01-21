//
//  StreakCalculator.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import Foundation

/// Pure functions for streak calculation (no SwiftData dependencies)
struct StreakCalculator {
    
    /// Returns start of day for a given date
    /// - Parameters:
    ///   - date: The date to normalize
    ///   - calendar: Calendar to use (defaults to .current)
    /// - Returns: Date normalized to start of day
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /// Calculates the number of days between two dates
    /// - Parameters:
    ///   - a: First date (should be normalized to startOfDay)
    ///   - b: Second date (should be normalized to startOfDay)
    ///   - calendar: Calendar to use (defaults to .current)
    /// - Returns: Number of full days between a and b (positive if b > a)
    static func daysBetween(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.day], from: a, to: b)
        return components.day ?? 0
    }
    
    /// Evaluates whether any days have been missed since last evaluation
    /// and resets currentStreak to 0 if appropriate
    /// - Parameters:
    ///   - today: Today's date (will be normalized)
    ///   - settings: User settings (modified in place)
    ///   - calendar: Calendar to use (defaults to .current)
    static func evaluateMissedDays(today: Date, settings: inout UserSettings, calendar: Calendar = .current) {
        let todayKey = startOfDay(today, calendar: calendar)
        
        // First run: initialize evaluation date
        guard let lastEvaluated = settings.lastStreakEvaluatedDateKey else {
            settings.lastStreakEvaluatedDateKey = todayKey
            return
        }
        
        // Already evaluated today
        if lastEvaluated == todayKey {
            return
        }
        
        // Check if we need to reset streak due to missed days
        if let lastCompleted = settings.lastCompletedDateKey {
            let gap = daysBetween(lastCompleted, todayKey, calendar: calendar)
            // If gap >= 2, it means at least one full day passed without completion
            if gap >= 2 {
                settings.currentStreak = 0
            }
        }
        
        // Update evaluation date
        settings.lastStreakEvaluatedDateKey = todayKey
    }
    
    /// Records a completion for a specific date and updates streak accordingly
    /// - Parameters:
    ///   - date: The date of completion (will be normalized)
    ///   - settings: User settings (modified in place)
    ///   - calendar: Calendar to use (defaults to .current)
    static func recordCompletion(for date: Date, settings: inout UserSettings, calendar: Calendar = .current) {
        let dateKey = startOfDay(date, calendar: calendar)
        
        // Idempotent: if already recorded completion for this day, do nothing
        if let lastCompleted = settings.lastCompletedDateKey, lastCompleted == dateKey {
            return
        }
        
        // Calculate streak
        if let lastCompleted = settings.lastCompletedDateKey {
            let gap = daysBetween(lastCompleted, dateKey, calendar: calendar)
            if gap == 1 {
                // Consecutive day
                settings.currentStreak += 1
            } else {
                // Non-consecutive, start new streak
                settings.currentStreak = 1
            }
        } else {
            // First ever completion
            settings.currentStreak = 1
        }
        
        // Update last completed date
        settings.lastCompletedDateKey = dateKey
        
        // Update longest streak if current exceeds it
        settings.longestStreak = max(settings.longestStreak, settings.currentStreak)
    }
}
