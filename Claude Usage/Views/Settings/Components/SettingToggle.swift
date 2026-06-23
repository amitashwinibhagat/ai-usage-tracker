//
//  SettingToggle.swift
//  Claude Usage - Unified Toggle Component
//
//  Created by Claude Code on 2025-12-20.
//

import SwiftUI

/// Unified toggle component for settings
/// Provides consistent styling with optional description and badges
struct SettingToggle: View {
    let title: String
    let description: String?
    let badge: BadgeType?
    @Binding var isOn: Bool

    enum BadgeType {
        case beta
        case new

        var text: String {
            switch self {
            case .beta: return "BETA"
            case .new: return "NEW"
            }
        }

        var color: Color {
            switch self {
            case .beta: return AppTheme.Colors.betaBadge
            case .new: return AppTheme.Colors.newBadge
            }
        }
    }

    init(
        title: String,
        description: String? = nil,
        badge: BadgeType? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.badge = badge
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(title)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if let badge = badge {
                        BadgeView(badge: badge)
                    }
                }

                if let description = description {
                    Text(description)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: AppTheme.Spacing.cardPadding)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AppTheme.Colors.accent)
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.backgroundDeep.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        var label = title
        if let badge = badge {
            label += ", \(badge.text)"
        }
        if let description = description {
            label += ". \(description)"
        }
        return label
    }
}

/// Badge component for toggle labels
private struct BadgeView: View {
    let badge: SettingToggle.BadgeType

    var body: some View {
        Text(badge.text)
            .font(AppTheme.Typography.badge)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(badge.color.opacity(0.22))
            )
            .overlay(
                Capsule()
                    .strokeBorder(badge.color.opacity(0.45), lineWidth: 0.5)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("Basic Toggle") {
    SettingToggle(
        title: "Enable notifications",
        isOn: .constant(true)
    )
    .padding()
}

#Preview("Toggle with Description") {
    SettingToggle(
        title: "Start at login",
        description: "Automatically launch Claude Usage when you log in to your Mac",
        isOn: .constant(false)
    )
    .padding()
}

#Preview("Toggle with Beta Badge") {
    SettingToggle(
        title: "Advanced features",
        description: "Enable experimental features that may be unstable",
        badge: .beta,
        isOn: .constant(true)
    )
    .padding()
}

#Preview("Toggle with New Badge") {
    SettingToggle(
        title: "API usage tracking",
        description: "Track your API usage from console.anthropic.com",
        badge: .new,
        isOn: .constant(true)
    )
    .padding()
}
