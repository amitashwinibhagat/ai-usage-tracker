//
//  AccountSettingsView.swift
//  Claude Usage - Consolidated Account Settings
//
//  Merges: ProFeaturesView, SupportView, AboutView
//

import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared
    @State private var showingActivationSheet = false
    @State private var activationKey = ""
    @State private var activationError: String?
    @State private var isActivating = false
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
                    subtitle: "Manage your license, subscription, and app information."
                )

                ProductInsightCard(
                    icon: "target",
                    title: "Built for avoiding surprise limits",
                    message: "Pro is designed around the moments that cost time: hitting a session cap mid-work, losing track across profiles, or not knowing which AI account still has capacity.",
                    color: AppTheme.Colors.proBadge
                )

                tierStatusCard

                if featureFlags.isFree {
                    pricingCard
                }

                if featureFlags.isFree {
                    activationCard
                }

                versionInfoCard

                supportCard

                linksCard

                footerSection

                Spacer()
            }
            .padding(28)
        }
        .sheet(isPresented: $showingActivationSheet) {
            LicenseActivationSheet(
                licenseKey: $activationKey,
                error: $activationError,
                isActivating: $isActivating,
                onActivate: {
                    Task {
                        isActivating = true
                        activationError = nil
                        let success = await licenseManager.activateLicense(activationKey)
                        isActivating = false
                        if success {
                            showingActivationSheet = false
                            activationKey = ""
                        }
                    }
                },
                onCancel: {
                    showingActivationSheet = false
                    activationKey = ""
                    activationError = nil
                }
            )
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

    // MARK: - Tier Status

    private var tierStatusCard: some View {
        SettingsContentCard {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill((featureFlags.isFree ? AppTheme.Colors.warning : AppTheme.Colors.success).opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: featureFlags.isFree ? "lock.fill" : "checkmark.seal.fill")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(featureFlags.isFree ? AppTheme.Colors.warning : AppTheme.Colors.success)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Current plan")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .textCase(.uppercase)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(licenseManager.currentTier.displayName)
                            .font(AppTheme.Typography.sectionTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if !featureFlags.isFree {
                            Text("PRO")
                                .font(AppTheme.Typography.badge)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.proBadge.opacity(0.22))
                                )
                        }
                    }

                    if featureFlags.isFree {
                        Text("Free is enough for basic Claude tracking. Upgrade when you need forecasting, exports, multi-provider visibility, or more than two profiles.")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("You have access to all Pro features. Thank you for supporting development!")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                if featureFlags.isFree {
                    SettingsButton.primary(title: "Upgrade", icon: "arrow.up.circle.fill") {
                        if let url = licenseManager.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .frame(width: 132)
                }
            }
        }
    }

    // MARK: - Pricing

    private var pricingCard: some View {
        SettingsContentCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Upgrade when usage becomes work-critical")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Monthly for flexibility, annual for the best value.")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Text("$4.99/mo")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundColor(AppTheme.Colors.accentHover)
                }

                Text("$39.99/year saves 33% compared with monthly billing.")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.success)

                SettingsButton.primary(title: "Upgrade Now", icon: "arrow.up.circle.fill") {
                    if let url = licenseManager.proCheckoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Activation

    private var activationCard: some View {
        SettingsContentCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Already have a license?")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Enter your license key to activate Pro features.")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                SettingsButton(
                    title: "Activate License",
                    icon: "key.fill",
                    style: .secondary
                ) {
                    showingActivationSheet = true
                }
            }
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
                    Text("Closed-source commercial")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                SettingsButton(
                    title: "settings.updates.check_now".localized,
                    icon: "arrow.down.circle",
                    style: .secondary
                ) {
                    UpdateManager.shared.checkForUpdates()
                }
                .disabled(!UpdateManager.shared.canCheckForUpdates)
            }
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
        }
    }

    // MARK: - Links

    private var linksCard: some View {
        SettingsSectionCard(
            title: "about.links".localized,
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                LinkButton(title: "Upgrade to Pro", icon: "star.fill") {
                    if let url = LicenseManager.shared.proCheckoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }

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
            Text("Closed-source commercial macOS app")
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
        NSApplication.shared.terminate(nil)
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
