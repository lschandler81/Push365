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
    
    // MARK: - Permission
    
    /// Requests notification permission from the user
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules notifications for a specific date
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
        
        // Schedule morning notification
        scheduleMorningNotification(for: date, settings: settings, record: record)
        
        // Schedule reminder only if remaining > 0
        if record.remaining > 0 {
            scheduleReminderNotification(for: date, settings: settings, record: record)
        }
    }
    
    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private Helpers
    
    private func scheduleMorningNotification(for date: Date, settings: UserSettings, record: DayRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! 💪"
        content.body = "Day \(record.dayNumber) — \(record.target) push-ups today. Let's get started!"
        content.sound = .default
        
        let identifier = makeIdentifier(type: "morning", date: date)
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = settings.morningHour
        dateComponents.minute = settings.morningMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling morning notification: \(error)")
            }
        }
    }
    
    private func scheduleReminderNotification(for date: Date, settings: UserSettings, record: DayRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Don't Forget! 👊"
        content.body = "You've got \(record.remaining) push-ups left today. Finish strong!"
        content.sound = .default
        
        let identifier = makeIdentifier(type: "reminder", date: date)
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = settings.reminderHour
        dateComponents.minute = settings.reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder notification: \(error)")
            }
        }
    }
    
    private func cancelNotifications(for date: Date) {
        let morningId = makeIdentifier(type: "morning", date: date)
        let reminderId = makeIdentifier(type: "reminder", date: date)
        center.removePendingNotificationRequests(withIdentifiers: [morningId, reminderId])
    }
    
    private func makeIdentifier(type: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return "\(type)-\(dateString)"
    }
}
