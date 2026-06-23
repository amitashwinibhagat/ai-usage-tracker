//
//  AccountSettingsView.swift
//  Claude Usage - Consolidated Account Settings
//
//  Simplified About/Info page (no monetization)
//

import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var updateManager = UpdateManager.shared
    @State private var showResetConfirmation = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "Account",
                    subtitle: "App information and support."
                )

                versionInfoCard

                supportCard

                linksCard

                footerSection

                Spacer()
            }
            .padding(28)
        }
        .alert("about.reset_confirmation_title".localized, isPresented: $showResetConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("about.reset_confirm".localized, role: .destructive) {
                resetAppData()
            }
        } message: {
            Text("about.reset_confirmation_message".localized)
        }
    }

    // MARK: - Version Info

    private var versionInfoCard: some View {
        SettingsSectionCard(
            title: "App Information",
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("Version")
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("v\(appVersion) (\(buildNumber))")
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                Divider().overlay(AppTheme.Colors.divider)

                HStack {
                    Text("Distribution")
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("Direct macOS (Sparkle)")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                Divider().overlay(AppTheme.Colors.divider)

                HStack {
                    Text("License")
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("Free, no monetization")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                SettingsButton(
                    title: "settings.updates.check_now".localized,
                    icon: "arrow.down.circle",
                    style: .secondary
                ) {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)

                if updateManager.lastCheckOutcome != .idle {
                    updateOutcomeBanner
                }
            }
        }
    }

    // MARK: - Update outcome banner
    //
    // BUG 5 from the click audit: surface the result of the most
    // recent check so the user knows whether Sparkle did anything.

    @ViewBuilder
    private var updateOutcomeBanner: some View {
        let (icon, text, tint) = updateOutcomeDetails
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(AppTheme.Typography.tiny)
            Spacer()
            Button(action: { updateManager.acknowledgeLastCheckOutcome() }) {
                Image(systemName: "xmark")
                    .font(AppTheme.Typography.tiny)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(tint)
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(tint.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var updateOutcomeDetails: (String, String, Color) {
        switch updateManager.lastCheckOutcome {
        case .idle, .checking:
            return ("hourglass", "Checking for updates…", AppTheme.Colors.textMuted)
        case .upToDate:
            return ("checkmark.circle.fill", "You’re on the latest version.", AppTheme.Colors.success)
        case .updateAvailable(let version):
            return ("arrow.down.circle.fill", "Update available: v\(version). Sparkle will install it.", AppTheme.Colors.accent)
        case .failed(let message):
            return ("exclamationmark.triangle.fill", "Update check failed: \(message)", AppTheme.Colors.warning)
        }
    }

    // MARK: - Support

    private var supportCard: some View {
        SettingsSectionCard(
            title: "section.support_title".localized,
            subtitle: "section.support_desc".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                ProductInsightCard(
                    icon: "lock.shield.fill",
                    title: "Private by design",
                    message: "Credentials stay on this Mac. Provider OAuth tokens use Keychain where supported, synced Claude Code credentials stay in the selected local profile, and usage data remains local unless you explicitly export it.",
                    color: AppTheme.Colors.success
                )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
        }
    }

    // MARK: - Links

    private var linksCard: some View {
        SettingsSectionCard(
            title: "about.links".localized,
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                LinkButton(title: "about.send_feedback".localized, icon: "bubble.left.and.text.bubble.right") {
                    if let url = URL(string: "mailto:support@aiusagetracker.com") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Divider().overlay(AppTheme.Colors.divider)

                LinkButton(title: "about.run_setup_wizard".localized, icon: "wand.and.stars") {
                    NotificationCenter.default.post(name: .showSetupWizard, object: nil)
                }

                LinkButton(
                    title: "about.reset_app_data".localized,
                    icon: "trash",
                    tint: AppTheme.Colors.error,
                    iconTint: AppTheme.Colors.error,
                    trailingIcon: nil
                ) {
                    showResetConfirmation = true
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("Free macOS app — all features included")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.textMuted)

            Text("© \(String(Calendar.current.component(.year, from: Date()))) Amit Ashwini Bhagat")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
    }

    // MARK: - Helpers

    private func resetAppData() {
        MigrationService.shared.resetAppData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
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

#Preview {
    AccountSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
