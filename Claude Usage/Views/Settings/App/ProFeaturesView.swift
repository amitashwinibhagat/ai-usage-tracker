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
                    subtitle: "Unlock advanced tracking, predictions, and multi-AI support"
                )

                // Current Tier Badge
                tierStatusCard

                // Feature Grid
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
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: featureFlags.isFree ? "lock.fill" : "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(featureFlags.isFree ? .orange : .green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan: \(licenseManager.currentTier.displayName)")
                        .font(DesignTokens.Typography.sectionTitle)

                    if featureFlags.isFree {
                        Text("Upgrade to Pro for unlimited profiles, burn rate predictions, cost transparency, and more.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("You have access to all Pro features. Thank you for supporting development!")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.cardPadding)
        }
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Features")
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundColor(.secondary)

            VStack(spacing: DesignTokens.Spacing.small) {
                FeatureRow(
                    icon: "person.2.fill",
                    title: "Unlimited Profiles",
                    description: "Track all your Claude accounts and API keys",
                    isLocked: !featureFlags.isAvailable(featureFlags.unlimitedProfiles)
                )

                FeatureRow(
                    icon: "flame.fill",
                    title: "Burn Rate Predictor",
                    description: "'You'll hit the limit in 23 min at current pace'",
                    isLocked: !featureFlags.isAvailable(featureFlags.burnRatePredictor)
                )

                FeatureRow(
                    icon: "dollarsign.circle.fill",
                    title: "Cost Transparency",
                    description: "See API-equivalent cost for your usage",
                    isLocked: !featureFlags.isAvailable(featureFlags.costTransparency)
                )

                FeatureRow(
                    icon: "bell.badge.fill",
                    title: "Smart Notifications",
                    description: "Contextual alerts with actionable next steps",
                    isLocked: !featureFlags.isAvailable(featureFlags.smartNotifications)
                )

                FeatureRow(
                    icon: "chart.bar.xaxis",
                    title: "Usage History Export",
                    description: "JSON/CSV export for billing reconciliation",
                    isLocked: !featureFlags.isAvailable(featureFlags.usageHistoryExport)
                )

                FeatureRow(
                    icon: "cpu.fill",
                    title: "Multi-AI Tracking",
                    description: "Claude + Codex + Gemini + Copilot in one menu bar",
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                HStack {
                    Text("Upgrade to Pro")
                        .font(DesignTokens.Typography.sectionTitle)

                    Spacer()

                    Text("$4.99/mo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(SettingsColors.primary)
                }

                HStack(spacing: DesignTokens.Spacing.small) {
                    Text("or $39.99/year (33% off)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                SettingsButton(
                    title: "Upgrade Now",
                    icon: "arrow.up.circle.fill",
                    style: .primary
                ) {
                    if let url = licenseManager.proCheckoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(DesignTokens.Spacing.cardPadding)
        }
    }

    // MARK: - Activation Card

    private var activationCard: some View {
        SettingsContentCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                Text("Already have a license?")
                    .font(DesignTokens.Typography.sectionTitle)

                Text("Enter your license key to activate Pro features.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)

                SettingsButton(
                    title: "Activate License",
                    icon: "key.fill",
                    style: .secondary
                ) {
                    showingActivationSheet = true
                }
            }
            .padding(DesignTokens.Spacing.cardPadding)
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
        HStack(spacing: DesignTokens.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(isLocked ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: isLocked ? "lock.fill" : icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isLocked ? .orange : .green)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)

                    if isLocked {
                        Text("PRO")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple)
                            .cornerRadius(3)
                    }
                }

                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.cardPadding)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .opacity(isLocked ? 0.7 : 1.0)
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
