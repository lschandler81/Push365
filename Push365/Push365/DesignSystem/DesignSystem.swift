//
//  DesignSystem.swift
//  Push365
//
//  Created by Lee Chandler on 20/01/2026.
//

import SwiftUI

// MARK: - Colors

enum DSColor {
    /// Primary action blue - #2F6FE4 (light), lighter variant (dark)
    static let primary = Color("DSPrimary")
    
    /// Accent color (alias for primary)
    static let accent = Color("DSPrimary")
    
    /// Success/completion green - #4FAE8A (light), darker variant (dark)
    static let success = Color("DSSuccess")
    
    /// Main background - #F7F8FA (light), #0F1115 (dark)
    static let background = Color("DSBackground")
    
    /// Grouped/secondary background - #EFF1F4 (light), between bg and surface (dark)
    static let groupedBackground = Color("DSGroupedBackground")
    
    /// Card/surface background - #FFFFFF (light), #1A1D23 (dark)
    static let surface = Color("DSSurface")
    
    /// Overlay background (alias for surface)
    static let overlay = Color("DSSurface")
    
    /// Primary text color - #1C1E21 (light), #E5E7EB (dark)
    static let textPrimary = Color("DSTextPrimary")
    
    /// Secondary text color - #6B7280 (light), #9CA3AF (dark)
    static let textSecondary = Color("DSTextSecondary")
    
    /// Destructive/undo actions - #C25555 (light), softer variant (dark)
    static let destructive = Color("DSDestructive")
}

// MARK: - Typography

enum DSFont {
    /// Large day number display (e.g., "Day 20")
    static let dayTitle = Font.system(size: 44, weight: .semibold, design: .default)
    
    /// Target number display
    static let targetNumber = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Section headers
    static let sectionHeader = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// Regular body text
    static let body = Font.body
    
    /// Button labels
    static let button = Font.system(size: 17, weight: .medium, design: .default)
    
    /// Small caption text
    static let caption = Font.caption
    
    /// Subheadline
    static let subheadline = Font.subheadline
    
    /// Large stats/numbers
    static let largeNumber = Font.system(size: 42, weight: .bold, design: .default)
    
    /// Medium stats/numbers
    static let mediumNumber = Font.system(size: 28, weight: .semibold, design: .default)
}

// MARK: - Spacing

enum DSSpacing {
    /// Small spacing - 8pt
    static let s: CGFloat = 8
    
    /// Medium spacing - 16pt
    static let m: CGFloat = 16
    
    /// Large spacing - 24pt
    static let l: CGFloat = 24
    
    /// Extra large spacing - 32pt
    static let xl: CGFloat = 32
}

// MARK: - Radius

enum DSRadius {
    /// Card corner radius - 16pt
    static let card: CGFloat = 16
    
    /// Button corner radius - 12pt
    static let button: CGFloat = 12
    
    /// Pill/capsule radius - 20pt
    static let pill: CGFloat = 20
    
    /// Small elements - 8pt
    static let small: CGFloat = 8
}

// MARK: - Shadow

enum DSShadow {
    /// Standard card shadow
    static func card(color: Color = .black.opacity(0.1)) -> some View {
        EmptyView()
            .shadow(color: color, radius: 10, x: 0, y: 5)
    }
}
