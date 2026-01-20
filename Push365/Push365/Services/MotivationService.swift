//
//  MotivationService.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import Foundation

struct MotivationService {
    
    func getMotivationalMessage() -> String {
        return "Stay motivated!"
    }
    
    func getDailyQuote() -> String {
        return ""
    }
    
    /// Returns a motivational line based on the current day number
    /// - Parameter dayNumber: The current day in the challenge (1-365)
    /// - Returns: A motivational message
    func line(forDay dayNumber: Int) -> String {
        let messages = [
            "One day at a time. You've got this!",
            "Consistency is key. Keep pushing!",
            "Every rep counts. Stay strong!",
            "Building strength, one day at a time.",
            "Progress over perfection. Keep going!",
            "You're stronger than you think.",
            "Small steps lead to big changes.",
            "Commitment builds character."
        ]
        
        // Rotate through messages based on day number
        let index = (dayNumber - 1) % messages.count
        return messages[index]
    }
}
