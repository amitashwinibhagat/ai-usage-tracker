//
//  SettingsDesignSystem.swift
//  Claude Usage - Settings Design System
//
//  DEPRECATED: Card modifier delegates to AppTheme. Use `.appThemeCard()` for new code.
//

import SwiftUI

enum SettingsDesignSystem {
    static func cardStyle() -> some ShapeStyle { AppTheme.Colors.card }
    static func cardShape() -> some Shape { RoundedRectangle(cornerRadius: AppTheme.Radius.standard) }
    static func inputFieldStyle() -> some ShapeStyle { AppTheme.Colors.inputBackground }
    static func inputFieldShape() -> some Shape { RoundedRectangle(cornerRadius: AppTheme.Radius.small) }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .fill(AppTheme.Colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
            )
    }
}

extension View {
    func settingsCard() -> some View { self.modifier(CardModifier()) }
}
