//
//  SupportView.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-30.
//

import SwiftUI
import AppKit

/// Support and upgrade view for the direct-distribution product.
struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "Support",
                    subtitle: "Get help, request improvements, and upgrade when Claude tracking becomes part of your daily workflow."
                )

                ProductInsightCard(
                    icon: "lock.shield.fill",
                    title: "Private by design",
                    message: "Credentials stay on this Mac. Provider OAuth tokens use Keychain where supported, synced Claude Code credentials stay in the selected local profile, and usage data remains local unless you explicitly export it.",
                    color: AppTheme.Colors.success
                )

                SettingsContentCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        SupportValueRow(
                            icon: "sparkles",
                            color: AppTheme.Colors.proBadge,
                            title: "Upgrade for planning features",
                            message: "Pro adds forecasting, exports, multi-provider tracking, custom thresholds, and unlimited profiles."
                        )

                        SupportValueRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            color: AppTheme.Colors.info,
                            title: "Need help or want a feature?",
                            message: "Use feedback from the About page or contact support with the exact provider/profile that is not behaving as expected."
                        )

                        SupportValueRow(
                            icon: "arrow.triangle.2.circlepath",
                            color: AppTheme.Colors.warning,
                            title: "Keep the app updated",
                            message: "Direct distribution lets the app ship fixes quickly without App Store review delays."
                        )
                    }
                }

                SettingsContentCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Claude Usage Pro")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Spacer()

                            Text("$4.99/mo")
                                .font(AppTheme.Typography.statMedium)
                                .foregroundColor(AppTheme.Colors.accentHover)
                        }

                        Text("Use the free tier for basic Claude tracking. Upgrade when profiles, forecasting, exports, or multi-AI visibility become work-critical.")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        SettingsButton.primary(title: "Upgrade to Pro", icon: "arrow.up.circle.fill") {
                            if let url = LicenseManager.shared.proCheckoutURL {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct SupportValueRow: View {
    let icon: String
    let color: Color
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.smallSemibold)
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(message)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    SupportView()
        .frame(width: 520, height: 600)
}
