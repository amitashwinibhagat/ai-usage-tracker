//
//  SettingsColors.swift
//  Claude Usage - Settings Design System
//
//  DEPRECATED: Aliased into AppTheme. Use `AppTheme.Colors.*` for new code.
//

import SwiftUI

enum SettingsColors {
    static let success = AppTheme.Colors.success
    static let error   = AppTheme.Colors.error
    static let warning = AppTheme.Colors.warning
    static let info    = AppTheme.Colors.info
    static let caution = AppTheme.Colors.caution

    static let primary   = AppTheme.Colors.accent
    static let secondary = AppTheme.Colors.textSecondary

    static let cardBackground = AppTheme.Colors.card
    static let inputBackground = AppTheme.Colors.card
    static let border = AppTheme.Colors.borderSubtle

    static let featureIcon = AppTheme.Colors.accent
    static let betaBadge   = AppTheme.Colors.betaBadge
    static let proBadge    = AppTheme.Colors.proBadge

    static let usageLow      = AppTheme.Colors.usageLow
    static let usageMedium   = AppTheme.Colors.usageMedium
    static let usageHigh     = AppTheme.Colors.usageHigh
    static let usageCritical = AppTheme.Colors.usageCritical

    static func lightOverlay(_ color: Color, opacity: Double = 0.1) -> Color { color.opacity(opacity) }
    static func borderColor(_ color: Color, opacity: Double = 0.3) -> Color { color.opacity(opacity) }
}
