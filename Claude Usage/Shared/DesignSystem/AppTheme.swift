//
//  AppTheme.swift
//  Claude Usage — Unified Design System
//
//  Single source of truth for all design tokens.
//  Dark-first premium aesthetic with explicit hex values.
//

import SwiftUI

// MARK: - Unified Design System

/// Centralized design system for the entire app.
/// Replaces legacy `SettingsColors`, `Typography`, `Spacing`, and `DesignTokens`.
enum AppTheme {

    // MARK: - Colors

    enum Colors {
        // MARK: Background
        static let background       = Color(hex: "#0F1117")!
        static let backgroundDeep   = Color(hex: "#11131A")!
        static let sidebar          = Color(hex: "#1A1D26")!
        static let card             = Color(hex: "#1E212B")!
        static let cardElevated     = Color(hex: "#252836")!
        static let elevated         = Color(hex: "#2A2D3A")!
        static let overlay          = Color(hex: "#000000")!.opacity(0.5)

        // MARK: Border
        static let borderSubtle     = Color(hex: "#2E3142")!
        static let borderActive     = Color(hex: "#3D4260")!
        static let divider          = Color(hex: "#2A2D3A")!

        // MARK: Text
        static let textPrimary      = Color(hex: "#E8EAF0")!
        static let textSecondary    = Color(hex: "#8B8FA3")!
        static let textMuted        = Color(hex: "#5A5F75")!
        static let textInverse      = Color(hex: "#0F1117")!

        // MARK: Accent
        static let accent           = Color(hex: "#6366F1")!   // Indigo
        static let accentHover      = Color(hex: "#818CF8")!
        static let accentMuted      = Color(hex: "#6366F1")!.opacity(0.15)

        // MARK: Status
        static let success          = Color.adaptiveGreen
        static let error            = Color(hex: "#EF4444")!
        static let warning          = Color(hex: "#F59E0B")!
        static let info             = Color(hex: "#3B82F6")!
        static let caution          = Color(hex: "#EAB308")!

        // MARK: Usage Indicators
        static let usageLow         = Color(hex: "#22C55E")!
        static let usageMedium      = Color(hex: "#EAB308")!
        static let usageHigh        = Color(hex: "#F97316")!
        static let usageCritical    = Color(hex: "#EF4444")!

        // MARK: Input
        static let inputBackground  = Color(hex: "#1A1D26")!
        static let inputBorder      = Color(hex: "#2E3142")!
        static let inputBorderFocus = Color(hex: "#6366F1")!
        static let inputPlaceholder = Color(hex: "#5A5F75")!

        // MARK: Feature Badges
        static let proBadge         = Color(hex: "#A855F7")!   // Purple
        static let betaBadge        = Color(hex: "#F59E0B")!   // Amber
        static let teamBadge        = Color(hex: "#3B82F6")!   // Blue
        static let newBadge         = Color(hex: "#22C55E")!   // Green
    }

    // MARK: - Typography
    // Comprehensive scale covering all sizes used across the app.

    enum Typography {
        // MARK: Display
        static let display        = Font.system(size: 48)
        static let hero           = Font.system(size: 24, weight: .bold)

        // MARK: Headings
        static let pageTitle      = Font.system(size: 20, weight: .semibold)
        static let sectionTitle   = Font.system(size: 18, weight: .semibold)
        static let cardTitle      = Font.system(size: 16, weight: .semibold)
        static let subtitle       = Font.system(size: 14, weight: .semibold)

        // MARK: Body
        static let body           = Font.system(size: 14, weight: .regular)
        static let bodyMedium     = Font.system(size: 14, weight: .medium)
        static let bodySmall      = Font.system(size: 13, weight: .regular)
        static let label          = Font.system(size: 13, weight: .medium)
        static let labelBold      = Font.system(size: 13, weight: .bold)
        static let small          = Font.system(size: 12, weight: .regular)
        static let smallMedium    = Font.system(size: 12, weight: .medium)
        static let smallSemibold  = Font.system(size: 12, weight: .semibold)

        // MARK: Caption / Micro
        static let caption        = Font.system(size: 11, weight: .regular)
        static let captionMedium  = Font.system(size: 11, weight: .medium)
        static let captionSemibold = Font.system(size: 11, weight: .semibold)
        static let tiny           = Font.system(size: 10, weight: .regular)
        static let tinyMedium     = Font.system(size: 10, weight: .medium)
        static let tinySemibold   = Font.system(size: 10, weight: .semibold)
        static let micro          = Font.system(size: 9, weight: .regular)
        static let microMedium    = Font.system(size: 9, weight: .medium)
        static let microSemibold  = Font.system(size: 9, weight: .semibold)
        static let badge          = Font.system(size: 9, weight: .bold)
        static let nano           = Font.system(size: 8, weight: .regular)
        static let nanoMedium     = Font.system(size: 8, weight: .medium)
        static let nanoSemibold   = Font.system(size: 8, weight: .semibold)
        static let nanoBold       = Font.system(size: 8, weight: .bold)
        static let pico           = Font.system(size: 7, weight: .regular)

        // MARK: Stats
        static let statLarge      = Font.system(size: 28, weight: .bold)
        static let statMedium     = Font.system(size: 18, weight: .semibold)

        // MARK: Monospaced
        static let mono           = Font.system(size: 13, design: .monospaced)
        static let monoMedium     = Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall      = Font.system(size: 11, design: .monospaced)
        static let monoTiny       = Font.system(size: 10, weight: .semibold, design: .monospaced)
        static let monoInput      = Font.system(size: 12, design: .monospaced)
        static let monoCaption    = Font.system(size: 11, weight: .medium, design: .monospaced)

        // MARK: Rounded (for badges/buttons)
        static let roundedSemibold   = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let roundedMedium     = Font.system(size: 11, weight: .medium, design: .rounded)
        static let roundedSmall      = Font.system(size: 10, weight: .medium, design: .rounded)
        static let roundedTiny       = Font.system(size: 9, weight: .medium, design: .rounded)
        static let roundedNano       = Font.system(size: 7, design: .rounded)
    }

    // MARK: - Spacing (8px base grid)

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48

        // Semantic aliases
        static let section:       CGFloat = 24
        static let sectionCompact: CGFloat = 20
        static let cardPadding:   CGFloat = 16
        static let content:       CGFloat = 24
        static let contentLarge:  CGFloat = 28
        static let compact:       CGFloat = 16
        static let iconText:      CGFloat = 8
        static let buttonRow:     CGFloat = 10
        static let input:         CGFloat = 12
        static let inputPadding:  CGFloat = 12
        static let mdCompact:     CGFloat = 12
    }

    // MARK: - Radius

    enum Radius {
        static let micro:    CGFloat = 2
        static let tiny:     CGFloat = 4
        static let compact:  CGFloat = 6
        static let small:    CGFloat = 8
        static let standard: CGFloat = 12
        static let large:    CGFloat = 16
        static let pill:     CGFloat = 999
    }

    // MARK: - Shadows

    enum Shadows {
        static let card = ShadowStyle(
            color: Color(hex: "#000000")!.opacity(0.15),
            radius: 8,
            x: 0,
            y: 2
        )
        static let elevated = ShadowStyle(
            color: Color(hex: "#000000")!.opacity(0.25),
            radius: 12,
            x: 0,
            y: 4
        )
        static let glow = ShadowStyle(
            color: Colors.accent.opacity(0.3),
            radius: 8,
            x: 0,
            y: 0
        )
        static let modal = ShadowStyle(
            color: Color(hex: "#000000")!.opacity(0.15),
            radius: 15,
            x: 0,
            y: 5
        )
    }

    // MARK: - Component Modifiers

    /// Standard card background + border
    static func cardBackground(
        elevated: Bool = false
    ) -> some ViewModifier {
        CardBackgroundModifier(elevated: elevated)
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers

struct CardBackgroundModifier: ViewModifier {
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .fill(AppTheme.Colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
            )
            .shadow(
                color: elevated ? AppTheme.Shadows.elevated.color : AppTheme.Shadows.card.color,
                radius: elevated ? AppTheme.Shadows.elevated.radius : AppTheme.Shadows.card.radius,
                x: elevated ? AppTheme.Shadows.elevated.x : AppTheme.Shadows.card.x,
                y: elevated ? AppTheme.Shadows.elevated.y : AppTheme.Shadows.card.y
            )
    }
}

struct AppThemeCardModifier: ViewModifier {
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.cardPadding)
            .modifier(CardBackgroundModifier(elevated: elevated))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card styling with AppTheme
    func appThemeCard(elevated: Bool = false) -> some View {
        self.modifier(AppThemeCardModifier(elevated: elevated))
    }

    /// Apply standard content padding
    func appThemePadding() -> some View {
        self.padding(AppTheme.Spacing.content)
    }

    /// Apply compact padding
    func appThemeCompactPadding() -> some View {
        self.padding(AppTheme.Spacing.compact)
    }
}

// MARK: - Text Extensions

extension Text {
    func appThemePageTitle() -> some View {
        self.font(AppTheme.Typography.pageTitle)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }

    func appThemeCardTitle() -> some View {
        self.font(AppTheme.Typography.cardTitle)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }

    func appThemeBody() -> some View {
        self.font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }

    func appThemeLabel() -> some View {
        self.font(AppTheme.Typography.label)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }

    func appThemeCaption() -> some View {
        self.font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Colors.textMuted)
    }
}
