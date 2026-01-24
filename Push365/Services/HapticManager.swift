//
//  HapticManager.swift
//  Push365
//
//  Created by Lee Chandler on 21/01/2026.
//

import Foundation

#if canImport(UIKit)
import UIKit
import AudioToolbox

enum HapticManager {
    /// Light impact haptic (for quick actions like logging push-ups)
    static func lightImpact() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            // Fallback: system sound for testing confirmation
            AudioServicesPlaySystemSound(1519)
        }
    }
    
    /// Medium impact haptic (for undo actions)
    static func mediumImpact() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            // Fallback: system sound for testing confirmation
            AudioServicesPlaySystemSound(1520)
        }
    }
    
    /// Success notification haptic (for completing the day)
    static func success() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
            // Fallback: system sound for testing confirmation
            AudioServicesPlaySystemSound(1521)
        }
    }
}
#else
enum HapticManager {
    static func lightImpact() {}
    static func mediumImpact() {}
    static func success() {}
}
#endif
