//
//  StreakCalculatorTests.swift
//  Push365Tests
//
//  Created by Lee Chandler on 21/01/2026.
//

import XCTest
@testable import Push365

final class StreakCalculatorTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        // Use fixed calendar with Europe/London timezone
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
    }
    
    // MARK: - Helper Methods
    
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }
    
    private func makeSettings() -> UserSettings {
        return UserSettings(
            startDate: makeDate(year: 2026, month: 1, day: 1),
            currentStreak: 0,
            longestStreak: 0,
            lastCompletedDateKey: nil,
            lastStreakEvaluatedDateKey: nil
        )
    }
    
    // MARK: - Tests
    
    func testStartOfDay() {
        let date = makeDate(year: 2026, month: 1, day: 15, hour: 14)
        let startOfDay = StreakCalculator.startOfDay(date, calendar: calendar)
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startOfDay)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }
    
    func testDaysBetween() {
        let day1 = makeDate(year: 2026, month: 1, day: 15)
        let day2 = makeDate(year: 2026, month: 1, day: 18)
        
        let startDay1 = StreakCalculator.startOfDay(day1, calendar: calendar)
        let startDay2 = StreakCalculator.startOfDay(day2, calendar: calendar)
        
        let diff = StreakCalculator.daysBetween(startDay1, startDay2, calendar: calendar)
        XCTAssertEqual(diff, 3)
    }
    
    func testFirstCompletionCreatesStreakOfOne() {
        var settings = makeSettings()
        let date = makeDate(year: 2026, month: 1, day: 15)
        
        StreakCalculator.recordCompletion(for: date, settings: &settings, calendar: calendar)
        
        XCTAssertEqual(settings.currentStreak, 1)
        XCTAssertEqual(settings.longestStreak, 1)
        XCTAssertNotNil(settings.lastCompletedDateKey)
    }
    
    func testConsecutiveDaysIncrementStreak() {
        var settings = makeSettings()
        
        let day1 = makeDate(year: 2026, month: 1, day: 15)
        let day2 = makeDate(year: 2026, month: 1, day: 16)
        let day3 = makeDate(year: 2026, month: 1, day: 17)
        
        StreakCalculator.recordCompletion(for: day1, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 1)
        
        StreakCalculator.recordCompletion(for: day2, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 2)
        
        StreakCalculator.recordCompletion(for: day3, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 3)
        XCTAssertEqual(settings.longestStreak, 3)
    }
    
    func testMissingDayThenCompletingResetsToOne() {
        var settings = makeSettings()
        
        let day1 = makeDate(year: 2026, month: 1, day: 15)
        let day2 = makeDate(year: 2026, month: 1, day: 16)
        let day4 = makeDate(year: 2026, month: 1, day: 18) // Skip day 17
        
        StreakCalculator.recordCompletion(for: day1, settings: &settings, calendar: calendar)
        StreakCalculator.recordCompletion(for: day2, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 2)
        XCTAssertEqual(settings.longestStreak, 2)
        
        // Day 18 (skipped day 17, so gap = 2)
        StreakCalculator.recordCompletion(for: day4, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 1)
        XCTAssertEqual(settings.longestStreak, 2) // Longest remains 2
    }
    
    func testEvaluateMissedDaysResetsCurrentStreak() {
        var settings = makeSettings()
        
        let day1 = makeDate(year: 2026, month: 1, day: 15)
        let day2 = makeDate(year: 2026, month: 1, day: 16)
        
        // Complete two days
        StreakCalculator.recordCompletion(for: day1, settings: &settings, calendar: calendar)
        StreakCalculator.recordCompletion(for: day2, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 2)
        
        // Set evaluation date to day 16
        settings.lastStreakEvaluatedDateKey = StreakCalculator.startOfDay(day2, calendar: calendar)
        
        // Now evaluate on day 19 (gap of 3 days from last completion on day 16)
        let day5 = makeDate(year: 2026, month: 1, day: 19)
        StreakCalculator.evaluateMissedDays(today: day5, settings: &settings, calendar: calendar)
        
        // Should reset because gap >= 2
        XCTAssertEqual(settings.currentStreak, 0)
        XCTAssertEqual(settings.longestStreak, 2) // Longest unchanged
    }
    
    func testEvaluateMissedDaysIdempotent() {
        var settings = makeSettings()
        let today = makeDate(year: 2026, month: 1, day: 15)
        
        StreakCalculator.evaluateMissedDays(today: today, settings: &settings, calendar: calendar)
        let firstEvaluationDate = settings.lastStreakEvaluatedDateKey
        
        StreakCalculator.evaluateMissedDays(today: today, settings: &settings, calendar: calendar)
        let secondEvaluationDate = settings.lastStreakEvaluatedDateKey
        
        XCTAssertEqual(firstEvaluationDate, secondEvaluationDate)
    }
    
    func testRecordCompletionIdempotent() {
        var settings = makeSettings()
        let date = makeDate(year: 2026, month: 1, day: 15)
        
        StreakCalculator.recordCompletion(for: date, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 1)
        
        // Record again for same day
        StreakCalculator.recordCompletion(for: date, settings: &settings, calendar: calendar)
        XCTAssertEqual(settings.currentStreak, 1) // Should not increment
    }
    
    func testLongestStreakTracksMaximum() {
        var settings = makeSettings()
        
        // Build a streak of 5
        for day in 1...5 {
            let date = makeDate(year: 2026, month: 1, day: day)
            StreakCalculator.recordCompletion(for: date, settings: &settings, calendar: calendar)
        }
        XCTAssertEqual(settings.currentStreak, 5)
        XCTAssertEqual(settings.longestStreak, 5)
        
        // Miss a day and start new streak of 2
        let date7 = makeDate(year: 2026, month: 1, day: 7)
        let date8 = makeDate(year: 2026, month: 1, day: 8)
        StreakCalculator.recordCompletion(for: date7, settings: &settings, calendar: calendar)
        StreakCalculator.recordCompletion(for: date8, settings: &settings, calendar: calendar)
        
        XCTAssertEqual(settings.currentStreak, 2)
        XCTAssertEqual(settings.longestStreak, 5) // Longest remains 5
    }
}
