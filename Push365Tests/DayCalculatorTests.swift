//
//  DayCalculatorTests.swift
//  Push365Tests
//
//  Created by Lee Chandler on 20/01/2026.
//

import Testing
import Foundation
@testable import Push365

struct DayCalculatorTests {
    
    // MARK: - Test Helpers
    
    /// Creates a calendar with a specific timezone for consistent testing
    func makeCalendar(tzIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: tzIdentifier) ?? .current
        return calendar
    }
    
    /// Creates a date from components using the specified calendar
    func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, calendar: Calendar) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }
    
    // MARK: - Basic Day Number Tests
    
    @Test func startDateReturnsDay1() {
        let calendar = makeCalendar(tzIdentifier: "America/New_York")
        let startDate = makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        
        let result = DayCalculator.dayNumber(for: startDate, startDate: startDate, calendar: calendar)
        
        #expect(result == 1)
    }
    
    @Test func nextDayReturnsDay2() {
        let calendar = makeCalendar(tzIdentifier: "America/New_York")
        let startDate = makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        let nextDay = makeDate(year: 2024, month: 1, day: 2, calendar: calendar)
        
        let result = DayCalculator.dayNumber(for: nextDay, startDate: startDate, calendar: calendar)
        
        #expect(result == 2)
    }
    
    @Test func dateBeforeStartClampsToOne() {
        let calendar = makeCalendar(tzIdentifier: "America/New_York")
        let startDate = makeDate(year: 2024, month: 1, day: 10, calendar: calendar)
        let beforeStart = makeDate(year: 2024, month: 1, day: 5, calendar: calendar)
        
        let result = DayCalculator.dayNumber(for: beforeStart, startDate: startDate, calendar: calendar)
        
        #expect(result == 1)
    }
    
    @Test func day365IsCorrect() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        let startDate = makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        let day365 = makeDate(year: 2024, month: 12, day: 31, calendar: calendar) // 2024 is a leap year
        
        let result = DayCalculator.dayNumber(for: day365, startDate: startDate, calendar: calendar)
        
        #expect(result == 366) // Leap year has 366 days
    }
    
    // MARK: - DST Tests
    
    @Test func dstSpringForwardBoundary() {
        // DST in America/Los_Angeles starts on March 10, 2024 at 2:00 AM (jumps to 3:00 AM)
        let calendar = makeCalendar(tzIdentifier: "America/Los_Angeles")
        let startDate = makeDate(year: 2024, month: 3, day: 9, calendar: calendar)
        let beforeDST = makeDate(year: 2024, month: 3, day: 9, calendar: calendar)
        let afterDST = makeDate(year: 2024, month: 3, day: 10, calendar: calendar)
        
        let day1 = DayCalculator.dayNumber(for: beforeDST, startDate: startDate, calendar: calendar)
        let day2 = DayCalculator.dayNumber(for: afterDST, startDate: startDate, calendar: calendar)
        
        #expect(day1 == 1)
        #expect(day2 == 2)
        #expect(day2 - day1 == 1) // Should increment by exactly 1 day
    }
    
    @Test func dstFallBackBoundary() {
        // DST in America/Los_Angeles ends on November 3, 2024 at 2:00 AM (falls back to 1:00 AM)
        let calendar = makeCalendar(tzIdentifier: "America/Los_Angeles")
        let startDate = makeDate(year: 2024, month: 11, day: 2, calendar: calendar)
        let beforeDST = makeDate(year: 2024, month: 11, day: 2, calendar: calendar)
        let afterDST = makeDate(year: 2024, month: 11, day: 3, calendar: calendar)
        
        let day1 = DayCalculator.dayNumber(for: beforeDST, startDate: startDate, calendar: calendar)
        let day2 = DayCalculator.dayNumber(for: afterDST, startDate: startDate, calendar: calendar)
        
        #expect(day1 == 1)
        #expect(day2 == 2)
        #expect(day2 - day1 == 1) // Should increment by exactly 1 day
    }
    
    // MARK: - Leap Year Tests
    
    @Test func leapDayHandling() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        let startDate = makeDate(year: 2024, month: 2, day: 28, calendar: calendar)
        let leapDay = makeDate(year: 2024, month: 2, day: 29, calendar: calendar)
        let dayAfterLeap = makeDate(year: 2024, month: 3, day: 1, calendar: calendar)
        
        let day1 = DayCalculator.dayNumber(for: startDate, startDate: startDate, calendar: calendar)
        let day2 = DayCalculator.dayNumber(for: leapDay, startDate: startDate, calendar: calendar)
        let day3 = DayCalculator.dayNumber(for: dayAfterLeap, startDate: startDate, calendar: calendar)
        
        #expect(day1 == 1) // Feb 28
        #expect(day2 == 2) // Feb 29 (leap day)
        #expect(day3 == 3) // Mar 1
    }
    
    @Test func nonLeapYearFebruaryEnd() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        let startDate = makeDate(year: 2023, month: 2, day: 28, calendar: calendar)
        let dayAfter = makeDate(year: 2023, month: 3, day: 1, calendar: calendar)
        
        let day1 = DayCalculator.dayNumber(for: startDate, startDate: startDate, calendar: calendar)
        let day2 = DayCalculator.dayNumber(for: dayAfter, startDate: startDate, calendar: calendar)
        
        #expect(day1 == 1) // Feb 28
        #expect(day2 == 2) // Mar 1 (no Feb 29 in 2023)
    }
    
    // MARK: - dateKey Tests
    
    @Test func dateKeyReturnsStartOfDay() {
        let calendar = makeCalendar(tzIdentifier: "America/New_York")
        // Create a date with specific time (3:45 PM)
        let dateWithTime = makeDate(year: 2024, month: 6, day: 15, hour: 15, minute: 45, calendar: calendar)
        
        let startOfDay = DayCalculator.dateKey(for: dateWithTime, calendar: calendar)
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startOfDay)
        
        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test func dateKeyHandlesDifferentTimezones() {
        // Same instant in time, different timezones
        let utcCalendar = makeCalendar(tzIdentifier: "UTC")
        let tokyoCalendar = makeCalendar(tzIdentifier: "Asia/Tokyo")
        
        // Create UTC midnight on Jan 1, 2024
        let utcDate = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0, calendar: utcCalendar)
        
        let utcKey = DayCalculator.dateKey(for: utcDate, calendar: utcCalendar)
        let tokyoKey = DayCalculator.dateKey(for: utcDate, calendar: tokyoCalendar)
        
        // UTC midnight = 9 AM JST, so Tokyo's start of day should be different
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: utcKey)
        let tokyoComponents = tokyoCalendar.dateComponents([.year, .month, .day], from: tokyoKey)
        
        // Both should be start of day in their respective timezones
        #expect(utcComponents.year == 2024)
        #expect(utcComponents.month == 1)
        #expect(utcComponents.day == 1)
        
        #expect(tokyoComponents.year == 2024)
        #expect(tokyoComponents.month == 1)
        #expect(tokyoComponents.day == 1)
    }
    
    // MARK: - Strict Target Tests
    
    @Test func strictTargetReturnsCorrectValues() {
        #expect(DayCalculator.strictTarget(for: 1) == 1)
        #expect(DayCalculator.strictTarget(for: 10) == 10)
        #expect(DayCalculator.strictTarget(for: 365) == 365)
        #expect(DayCalculator.strictTarget(for: 0) == 1) // Clamps to 1
        #expect(DayCalculator.strictTarget(for: -5) == 1) // Clamps to 1
    }
    
    // MARK: - Start of Year Tests
    
    @Test func startOfYearReturnsJanuary1st() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        let someDate = makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        
        let jan1 = DayCalculator.startOfYear(for: someDate, calendar: calendar)
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: jan1)
        
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test func startOfYearWorksAcrossYears() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        
        let date2023 = makeDate(year: 2023, month: 12, day: 31, calendar: calendar)
        let date2024 = makeDate(year: 2024, month: 1, day: 15, calendar: calendar)
        
        let jan1_2023 = DayCalculator.startOfYear(for: date2023, calendar: calendar)
        let jan1_2024 = DayCalculator.startOfYear(for: date2024, calendar: calendar)
        
        let components2023 = calendar.dateComponents([.year, .month, .day], from: jan1_2023)
        let components2024 = calendar.dateComponents([.year, .month, .day], from: jan1_2024)
        
        #expect(components2023.year == 2023)
        #expect(components2023.month == 1)
        #expect(components2023.day == 1)
        
        #expect(components2024.year == 2024)
        #expect(components2024.month == 1)
        #expect(components2024.day == 1)
    }
    
    // MARK: - Edge Cases
    
    @Test func multipleMonthsProgression() {
        let calendar = makeCalendar(tzIdentifier: "UTC")
        let startDate = makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        
        // Test several dates throughout the year
        let testCases: [(month: Int, day: Int, expectedDay: Int)] = [
            (1, 1, 1),      // Jan 1
            (1, 31, 31),    // Jan 31
            (2, 1, 32),     // Feb 1
            (2, 29, 60),    // Feb 29 (leap year)
            (3, 1, 61),     // Mar 1
            (12, 31, 366)   // Dec 31 (leap year)
        ]
        
        for testCase in testCases {
            let date = makeDate(year: 2024, month: testCase.month, day: testCase.day, calendar: calendar)
            let result = DayCalculator.dayNumber(for: date, startDate: startDate, calendar: calendar)
            #expect(result == testCase.expectedDay, "Failed for \(testCase.month)/\(testCase.day): expected \(testCase.expectedDay), got \(result)")
        }
    }
    
    @Test func timeOfDayDoesNotAffectDayNumber() {
        let calendar = makeCalendar(tzIdentifier: "America/New_York")
        let startDate = makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        
        // Same day, different times
        let midnight = makeDate(year: 2024, month: 1, day: 5, hour: 0, minute: 0, calendar: calendar)
        let noon = makeDate(year: 2024, month: 1, day: 5, hour: 12, minute: 0, calendar: calendar)
        let almostMidnight = makeDate(year: 2024, month: 1, day: 5, hour: 23, minute: 59, calendar: calendar)
        
        let result1 = DayCalculator.dayNumber(for: midnight, startDate: startDate, calendar: calendar)
        let result2 = DayCalculator.dayNumber(for: noon, startDate: startDate, calendar: calendar)
        let result3 = DayCalculator.dayNumber(for: almostMidnight, startDate: startDate, calendar: calendar)
        
        #expect(result1 == 5)
        #expect(result2 == 5)
        #expect(result3 == 5)
        #expect(result1 == result2)
        #expect(result2 == result3)
    }
}
