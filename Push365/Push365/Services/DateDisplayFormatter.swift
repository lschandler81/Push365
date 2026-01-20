//
//  DateDisplayFormatter.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation

enum DateDisplayFormatter {
    
    /// Returns a header-style date string (e.g., "Tue 20 Jan")
    /// - Parameters:
    ///   - date: The date to format
    ///   - preference: The user's date format preference
    /// - Returns: Formatted date string in the pattern "EEE d MMM"
    static func headerString(for date: Date, preference: DateFormatPreference) -> String {
        let locale = localeForPreference(preference)
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }
    
    /// Returns a short date string (e.g., "20/01/2026" for UK, locale-specific for automatic)
    /// - Parameters:
    ///   - date: The date to format
    ///   - preference: The user's date format preference
    /// - Returns: Formatted date string
    static func shortDateString(for date: Date, preference: DateFormatPreference) -> String {
        switch preference {
        case .automatic:
            // Use the device's locale with numeric date format
            return date.formatted(date: .numeric, time: .omitted)
            
        case .uk:
            // Force UK format (dd/MM/yyyy)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_GB")
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Returns the appropriate locale based on user preference
    private static func localeForPreference(_ preference: DateFormatPreference) -> Locale {
        switch preference {
        case .automatic:
            return .current
        case .uk:
            return Locale(identifier: "en_GB")
        }
    }
}
