//
//  Typography.swift
//  Claude Usage - Settings Design System
//
//  DEPRECATED: Aliased into AppTheme. Use `AppTheme.Typography.*` for new code.
//

import SwiftUI

enum Typography {
    static let title:           Font = AppTheme.Typography.pageTitle
    static let subtitle:        Font = AppTheme.Typography.subtitle
    static let sectionHeader:   Font = AppTheme.Typography.label
    static let body:            Font = AppTheme.Typography.bodySmall
    static let label:           Font = AppTheme.Typography.small
    static let caption:         Font = AppTheme.Typography.caption
    static let monospacedInput: Font = AppTheme.Typography.monoInput
    static let monospacedValue: Font = AppTheme.Typography.mono
    static let badge:           Font = AppTheme.Typography.badge
}

extension Text {
    func settingsTitle() -> some View { self.font(Typography.title).foregroundColor(AppTheme.Colors.textPrimary) }
    func settingsSubtitle() -> some View { self.font(Typography.subtitle).foregroundColor(AppTheme.Colors.textPrimary) }
    func settingsSectionHeader() -> some View { self.font(Typography.sectionHeader).foregroundColor(AppTheme.Colors.textPrimary) }
    func settingsBody() -> some View { self.font(Typography.body).foregroundColor(AppTheme.Colors.textPrimary) }
    func settingsCaption() -> some View { self.font(Typography.caption).foregroundColor(AppTheme.Colors.textSecondary) }
    func settingsLabel() -> some View { self.font(Typography.label).foregroundColor(AppTheme.Colors.textPrimary) }
}
