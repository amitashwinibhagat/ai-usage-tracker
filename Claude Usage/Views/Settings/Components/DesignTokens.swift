//
//  DesignTokens.swift
//  Claude Usage - Centralized Design System
//
//  DEPRECATED: Aliased into AppTheme. Use `AppTheme.*` for new code.
//

import SwiftUI

enum DesignTokens {
    enum Typography {
        static let pageTitle     = AppTheme.Typography.pageTitle
        static let pageSubtitle  = AppTheme.Typography.bodySmall
        static let sectionTitle  = AppTheme.Typography.label
        static let sectionSubtitle = AppTheme.Typography.caption
        static let body          = AppTheme.Typography.small
        static let bodyMedium    = AppTheme.Typography.bodySmall
        static let caption       = AppTheme.Typography.caption
        static let tiny          = AppTheme.Typography.caption
        static let monospaced    = AppTheme.Typography.monoInput
        static let monospacedSmall = AppTheme.Typography.monoSmall
        static let captionMono   = AppTheme.Typography.monoSmall
    }

    enum Spacing {
        static let section:      CGFloat = AppTheme.Spacing.lg
        static let cardPadding:  CGFloat = AppTheme.Spacing.cardPadding
        static let medium:       CGFloat = AppTheme.Spacing.mdCompact
        static let small:        CGFloat = AppTheme.Spacing.sm
        static let extraSmall:   CGFloat = AppTheme.Spacing.xs
        static let iconText:     CGFloat = AppTheme.Spacing.iconText
        static let iconFrame:    CGFloat = 20
    }

    enum Radius {
        static let card:  CGFloat = AppTheme.Radius.small
        static let small: CGFloat = AppTheme.Radius.compact
        static let tiny:  CGFloat = AppTheme.Radius.tiny
    }

    enum Icons {
        static let standard: CGFloat = 14
        static let small:    CGFloat = 12
        static let tiny:     CGFloat = 10
    }

    enum StatusDot {
        static let standard: CGFloat = 8
        static let small:    CGFloat = 6
    }

    enum Colors {
        static let cardBackground = AppTheme.Colors.card
        static let cardBorder     = AppTheme.Colors.borderSubtle
        static let inputBackground = AppTheme.Colors.card
        static let success        = AppTheme.Colors.success
        static let error          = AppTheme.Colors.error
        static let warning        = AppTheme.Colors.warning
        static let accent         = AppTheme.Colors.accent
    }
}
