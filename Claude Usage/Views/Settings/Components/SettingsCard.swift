//
//  SettingsCard.swift
//  Claude Usage - Card Container Component
//
//  Created by Claude Code on 2025-12-20.
//

import SwiftUI

/// Modern card container for grouping related settings
/// Provides consistent card styling with optional header and footer
struct SettingsCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let footer: String?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    if let title = title {
                        Text(title)
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.cardPadding)
                .padding(.top, AppTheme.Spacing.cardPadding)
                .padding(.bottom, AppTheme.Spacing.md)
            }

            content
                .padding(.horizontal, AppTheme.Spacing.cardPadding)
                .padding(.top, title == nil && subtitle == nil ? AppTheme.Spacing.cardPadding : 0)
                .padding(.bottom, footer == nil ? AppTheme.Spacing.cardPadding : AppTheme.Spacing.md)

            if let footer = footer {
                Text(footer)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppTheme.Spacing.cardPadding)
                    .padding(.bottom, AppTheme.Spacing.cardPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(AppTheme.Colors.card.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: AppTheme.Shadows.card.x, y: AppTheme.Shadows.card.y)
    }
}

// MARK: - Convenience Modifiers

extension SettingsCard {
    /// Create a card with just a title
    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, subtitle: nil, footer: nil, content: content)
    }

    /// Create a card with title and footer
    init(
        title: String,
        footer: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, subtitle: nil, footer: footer, content: content)
    }
}

// MARK: - Previews

#Preview("Basic Card") {
    SettingsCard {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Card content goes here")
                .font(Typography.body)

            Text("More content")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
}

#Preview("Card with Title") {
    SettingsCard(title: "Notification Settings") {
        VStack(spacing: Spacing.formRowSpacing) {
            SettingToggle(
                title: "Enable notifications",
                description: "Show notifications when usage thresholds are reached",
                isOn: .constant(true)
            )

            SettingToggle(
                title: "Sound alerts",
                description: "Play a sound with notifications",
                isOn: .constant(false)
            )
        }
    }
    .padding()
}

#Preview("Card with Title and Subtitle") {
    SettingsCard(
        title: "API Tracking",
        subtitle: "Configure your console.anthropic.com API tracking settings"
    ) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Session Key")
                .font(Typography.label)
                .foregroundColor(.secondary)

            Text("sk-ant-api03-...")
                .font(Typography.monospacedInput)
                .foregroundColor(.primary)
        }
    }
    .padding()
}

#Preview("Card with Footer") {
    SettingsCard(
        title: "Refresh Interval",
        footer: "Shorter intervals provide more real-time data but may impact battery life"
    ) {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Update every:")
                    .font(Typography.body)

                Spacer()

                Text("5 minutes")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            }

            Slider(value: .constant(5), in: 1...60)
        }
    }
    .padding()
}

#Preview("Multiple Cards") {
    VStack(spacing: Spacing.cardSpacing) {
        SettingsCard(title: "General") {
            SettingToggle(
                title: "Start at login",
                isOn: .constant(true)
            )
        }

        SettingsCard(title: "Appearance") {
            SettingToggle(
                title: "Show percentage in menu bar",
                isOn: .constant(false)
            )
        }

        SettingsCard(
            title: "Advanced",
            footer: "These settings are for advanced users only"
        ) {
            SettingToggle(
                title: "Debug mode",
                badge: .beta,
                isOn: .constant(false)
            )
        }
    }
    .padding()
}
