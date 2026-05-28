//
//  ProFeaturesView.swift
//  Claude Usage
//
//  Settings view for Pro/Team features with locked-state previews.
//

import SwiftUI

struct ProFeaturesView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared
    @State private var showingActivationSheet = false
    @State private var activationKey = ""
    @State private var activationError: String?
    @State private var isActivating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
                SettingsPageHeader(
                    title: "Pro Features",
                    subtitle: "Turn raw Claude limits into planning, forecasting, and cost visibility."
                )

                ProductInsightCard(
                    icon: "target",
                    title: "Built for avoiding surprise limits",
                    message: "Pro is designed around the moments that cost time: hitting a session cap mid-work, losing track across profiles, or not knowing which AI account still has capacity.",
                    color: AppTheme.Colors.proBadge
                )

                tierStatusCard

                featureGrid

                // Pricing Info (for free users)
                if featureFlags.isFree {
                    pricingCard
                }

                // Activation Section (for free users)
                if featureFlags.isFree {
                    activationCard
                }

                Spacer()
            }
            .padding()
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
    }

    // MARK: - Tier Status Card

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

                    Text(licenseManager.currentTier.displayName)
                        .font(AppTheme.Typography.sectionTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

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

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("What Pro unlocks")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("Customer outcomes")
                    .font(AppTheme.Typography.badge)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                FeatureRow(
                    icon: "person.2.fill",
                    title: "Unlimited Profiles",
                    description: "Track every Claude account, client workspace, and API key without juggling menus.",
                    isLocked: !featureFlags.isAvailable(featureFlags.unlimitedProfiles)
                )

                FeatureRow(
                    icon: "flame.fill",
                    title: "Burn Rate Predictor",
                    description: "Know if your current work session will hit the cap before it interrupts you.",
                    isLocked: !featureFlags.isAvailable(featureFlags.burnRatePredictor)
                )

                FeatureRow(
                    icon: "dollarsign.circle.fill",
                    title: "Cost Transparency",
                    description: "Understand the API-equivalent value of your Claude usage and savings.",
                    isLocked: !featureFlags.isAvailable(featureFlags.costTransparency)
                )

                FeatureRow(
                    icon: "bell.badge.fill",
                    title: "Smart Notifications",
                    description: "Get practical guidance when limits, pace, or reset timing need attention.",
                    isLocked: !featureFlags.isAvailable(featureFlags.smartNotifications)
                )

                FeatureRow(
                    icon: "chart.bar.xaxis",
                    title: "Usage History Export",
                    description: "Export evidence for billing, reimbursements, client work, or usage audits.",
                    isLocked: !featureFlags.isAvailable(featureFlags.usageHistoryExport)
                )

                FeatureRow(
                    icon: "cpu.fill",
                    title: "Multi-AI Tracking",
                    description: "See Claude, Codex, Gemini, Copilot, and more from one menu bar view.",
                    isLocked: !featureFlags.isAvailable(featureFlags.multiAI)
                )

                FeatureRow(
                    icon: "paintbrush.fill",
                    title: "Advanced Icon Styles",
                    description: "Premium visual styles for menu bar",
                    isLocked: !featureFlags.isAvailable(featureFlags.advancedIconStyles)
                )

                FeatureRow(
                    icon: "bell.and.waves.left.and.right.fill",
                    title: "Custom Thresholds",
                    description: "Set your own notification percentages",
                    isLocked: !featureFlags.isAvailable(featureFlags.customThresholds)
                )
            }
        }
    }

    // MARK: - Pricing Card

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
                    .font(AppTheme.Typography.smallMedium)
                    .foregroundColor(AppTheme.Colors.success)

                SettingsButton.primary(title: "Upgrade Now", icon: "arrow.up.circle.fill") {
                    if let url = licenseManager.proCheckoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Activation Card

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
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isLocked: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill((isLocked ? AppTheme.Colors.warning : AppTheme.Colors.success).opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: isLocked ? "lock.fill" : icon)
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(isLocked ? AppTheme.Colors.warning : AppTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if isLocked {
                        Text("PRO")
                            .font(AppTheme.Typography.badge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppTheme.Colors.proBadge.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }

                Text(description)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "checkmark")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.success)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(isHovered ? AppTheme.Colors.cardElevated : AppTheme.Colors.card.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - License Activation Sheet

struct LicenseActivationSheet: View {
    @Binding var licenseKey: String
    @Binding var error: String?
    @Binding var isActivating: Bool
    let onActivate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Activate Pro License")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("License Key")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isActivating)

                Text("Enter the license key from your purchase confirmation email.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                if let error = error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .disabled(isActivating)

                Button("Activate") {
                    onActivate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.isEmpty || isActivating)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
