//
//  SharedDesignSystem.swift
//  Push365
//
//  Created by Lee Chandler on 22/01/2026.
//

import SwiftUI

/// Shared design tokens for both iOS and watchOS
struct SharedDesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        static let accent = Color(red: 0.0, green: 0.7, blue: 1.0) // Vibrant blue
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let background = Color.black
        static let surface = Color.white.opacity(0.08)
        static let surfaceElevated = Color.white.opacity(0.12)
    }
    
    // MARK: - Fonts (Watch-compatible)
    
    struct Fonts {
        static func title(size: CGFloat = 20) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func body(size: CGFloat = 16) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        
        static func caption(size: CGFloat = 12) -> Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let full: CGFloat = 1000
    }
}

// Convenience aliases
typealias DSColor = SharedDesignSystem.Colors
typealias DSFont = SharedDesignSystem.Fonts
typealias DSSpacing = SharedDesignSystem.Spacing
typealias DSRadius = SharedDesignSystem.Radius
