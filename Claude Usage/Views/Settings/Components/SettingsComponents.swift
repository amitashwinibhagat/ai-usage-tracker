//
//  SettingsCard2.swift
//  Claude Usage - Reusable Settings Card Component
//
//  A consistent, reusable card container for all settings sections
//  (Named SettingsCard2 to avoid conflict with SettingsSection enum)
//

import SwiftUI

/// Reusable card container for settings sections
/// Provides consistent header, divider, content layout with proper styling
struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill)
                    .fill(AppTheme.Colors.accent)
                    .frame(width: 3, height: 28)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppTheme.Spacing.cardPadding)

            Divider()
                .overlay(AppTheme.Colors.divider)

            content
                .padding(AppTheme.Spacing.cardPadding)
        }
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

/// Simpler version without header - just a content card
struct SettingsContentCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.cardPadding)
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

/// Page header component - reusable across all settings tabs
struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(AppTheme.Typography.pageTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("Settings")
                    .font(AppTheme.Typography.badge)
                    .foregroundColor(AppTheme.Colors.accentHover)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.accentMuted)
                    )
            }

            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.cardPadding)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.cardElevated.opacity(0.96), AppTheme.Colors.card.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - Product Insight Card

/// Compact product-led guidance card for explaining why a setting matters.
struct ProductInsightCard: View {
    let icon: String
    let title: String
    let message: String
    var color: Color = AppTheme.Colors.info

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.smallSemibold)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.13))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(message)
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(color.opacity(0.22), lineWidth: 0.5)
        )
    }
}

// MARK: - Credential Status Content

struct CredentialStatusContent: View {
    let title: String
    let message: String
    var detail: String? = nil
    let isConnected: Bool
    var removeAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: isConnected ? "checkmark.seal.fill" : "link.badge.plus")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(message)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail {
                    Text(detail)
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let removeAction {
                SettingsButton.destructive(title: "common.remove".localized, icon: "trash", action: removeAction)
                    .fixedSize()
            }
        }
    }

    private var statusColor: Color {
        isConnected ? AppTheme.Colors.success : AppTheme.Colors.warning
    }
}

// MARK: - Bullet Point Helper

/// A simple bullet point view for displaying lists
struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
            Text("•")
                .foregroundColor(AppTheme.Colors.accentHover)
            Text(text)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            SettingsPageHeader(
                title: "Example Settings",
                subtitle: "This is how the page header looks"
            )

            SettingsSectionCard(
                title: "Example Section",
                subtitle: "This is a subtitle description"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content goes here")
                    Toggle("Some Toggle", isOn: .constant(true))
                }
            }

            SettingsContentCard {
                Text("Simple content card without header")
            }
        }
        .padding()
    }
    .frame(width: 500, height: 600)
}
