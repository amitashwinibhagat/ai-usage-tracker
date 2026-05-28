//
//  SettingsHeader.swift
//  Claude Usage - Settings Header Component
//
//  Created by Claude Code on 2025-12-21.
//

import SwiftUI

/// Unified header component for all settings tabs (legacy compatibility)
/// NOTE: New code should use SettingsPageHeader from SettingsComponents.swift
struct SettingsHeader: View {
    let title: String
    let subtitle: String
    let icon: String?

    init(title: String, subtitle: String, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            if let icon = icon {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.hero)
                        .foregroundColor(AppTheme.Colors.accentHover)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(title)
                            .font(AppTheme.Typography.pageTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text(subtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.pageTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(AppTheme.Colors.cardElevated.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }
}
