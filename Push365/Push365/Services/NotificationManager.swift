//
//  NotificationManager.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    
    private let center = UNUserNotificationCenter.current()
    
    // Identifier for the next morning notification
    private let nextMorningIdentifier = "next-morning-reminder"
    
    // MARK: - Permission
    
    /// Requests notification permission from the user
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules the next morning notification with correct day/target for tomorrow
    /// Should be called on app launch and when settings change
    /// - Parameters:
    ///   - settings: User settings containing notification preferences and start date
    func scheduleNextMorningNotification(settings: UserSettings) {
        guard settings.notificationsEnabled else {
            cancelMorningNotifications()
            return
        }
        
        // Cancel existing morning notification
        cancelMorningNotifications()
        
        let calendar = Calendar.current
        
        // Calculate when the next morning notification should fire
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = settings.morningHour
        components.minute = settings.morningMinute
        
        guard var scheduledDate = calendar.date(from: components) else { return }
        
        // If the time has already passed today, schedule for tomorrow
        if scheduledDate <= Date() {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: scheduledDate) else { return }
            scheduledDate = tomorrow
        }
        
        // Calculate day number and target for the scheduled date
        let dayNumber = DayCalculator.dayNumber(for: scheduledDate, startDate: settings.programStartDate, calendar: calendar)
        let target = calculateTarget(for: scheduledDate, dayNumber: dayNumber, settings: settings, calendar: calendar)
        
        // Build notification content
        let content = UNMutableNotificationContent()
        content.title = "Day \(dayNumber)"
        
        if settings.mode == .strict {
            // Strict mode: show specific target
            content.body = "Your target today is \(target) push-ups."
        } else {
            // Flexible mode: generic message (or calculate target if needed)
            content.body = "Your target today is \(target) push-ups."
            if target != dayNumber {
                content.body += " Adaptive mode keeps your target steady until completed."
            }
        }
        
        content.sound = .default
        
        // Schedule for the specific date/time (non-repeating)
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: nextMorningIdentifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    /// Calculates the target for a given date in flexible mode
    private func calculateTarget(for date: Date, dayNumber: Int, settings: UserSettings, calendar: Calendar) -> Int {
        if settings.mode == .strict {
            return DayCalculator.strictTarget(for: dayNumber)
        }
        
        // Flexible mode logic
        guard let lastCompletionDate = settings.lastCompletedDateKey else {
            return max(1, dayNumber)
        }
        
        let dateKey = DayCalculator.dateKey(for: date, calendar: calendar)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: dateKey) ?? dateKey
        let yesterdayKey = DayCalculator.dateKey(for: yesterday, calendar: calendar)
        let lastCompletionKey = DayCalculator.dateKey(for: lastCompletionDate, calendar: calendar)
        
        let yesterdayWasCompleted = (lastCompletionKey == yesterdayKey)
        
        if yesterdayWasCompleted {
            return max(1, dayNumber)
        } else {
            return max(1, settings.lastCompletedTarget + 1)
        }
    }
    
    /// Schedules notifications for a specific date (used for today's reminder)
    /// - Parameters:
    ///   - date: The date to schedule notifications for
    ///   - settings: User settings containing notification preferences
    ///   - record: Day record containing progress information
    func scheduleNotifications(for date: Date, settings: UserSettings, record: DayRecord) {
        guard settings.notificationsEnabled else {
            // Cancel notifications if disabled
            cancelNotifications(for: date)
            return
        }
        
        // Cancel existing notifications for this date
        cancelNotifications(for: date)
        
        // Schedule reminder only if remaining > 0
        if record.remaining > 0 {
            scheduleReminderNotification(for: date, settings: settings, record: record)
        }
        
        // Always reschedule next morning notification to ensure it's up to date
        scheduleNextMorningNotification(settings: settings)
    }
    
    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Cancels morning notifications
    func cancelMorningNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [nextMorningIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [nextMorningIdentifier])
    }
    
    /// Cancels only the reminder notification for a specific date
    func cancelReminder(for date: Date) {
        let reminderId = makeIdentifier(type: "reminder", date: date)
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        center.removeDeliveredNotifications(withIdentifiers: [reminderId])
    }
    
    /// Fires a completion confirmation notification immediately
    func notifyCompletion(for record: DayRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Day \(record.dayNumber) complete"
        content.body = "Target reached. See you tomorrow."
        content.sound = .default
        
        let identifier = "completion-\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - Private Helpers
    
    private func scheduleReminderNotification(for date: Date, settings: UserSettings, record: DayRecord) {
        let content = UNMutableNotificationContent()
        content.title = "\(record.remaining) remaining"
        content.body = "You can finish before the day ends."
        content.sound = .default
        
        let calendar = Calendar.current
        let identifier = makeIdentifier(type: "reminder", date: date)
        
        // Build the notification time for today
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = settings.reminderHour
        dateComponents.minute = settings.reminderMinute
        
        // Check if this time has already passed today
        if let scheduledDate = calendar.date(from: dateComponents), scheduledDate <= Date() {
            // Time has passed, schedule for tomorrow instead
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                dateComponents.hour = settings.reminderHour
                dateComponents.minute = settings.reminderMinute
            }
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    private func cancelNotifications(for date: Date) {
        let morningId = makeIdentifier(type: "morning", date: date)
        let reminderId = makeIdentifier(type: "reminder", date: date)
        center.removePendingNotificationRequests(withIdentifiers: [morningId, reminderId])
        center.removeDeliveredNotifications(withIdentifiers: [morningId, reminderId])
    }
    
    func cancelTodaysNotifications() {
        cancelNotifications(for: Date())
    }
    
    private func makeIdentifier(type: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return "\(type)-\(dateString)"
    }
}
