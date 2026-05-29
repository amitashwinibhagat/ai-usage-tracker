//
//  CredentialsSettingsView.swift
//  Claude Usage - Consolidated Credentials Settings
//
//  Merges: PersonalUsageView, APIBillingView, CLIAccountView, AIProvidersSettingsView
//

import SwiftUI

struct CredentialsSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared
    @State private var activeSheet: ProviderSheet?
    @State private var selectedProvider: AIProvider?

    enum ProviderSheet: Identifiable {
        case codex, gemini, copilot, kimi, deepseek, glm, qwen, minimax
        case geminiOAuth, copilotOAuth
        var id: Int { hashValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "Credentials",
                    subtitle: "Manage Claude.ai, API Console, and provider credentials for usage tracking."
                )

                ProductInsightCard(
                    icon: "lock.shield.fill",
                    title: "Credentials stay on this Mac",
                    message: "Provider OAuth tokens use Keychain where supported. Usage data remains local unless you explicitly export it.",
                    color: AppTheme.Colors.success
                )

                if let profile = profileManager.activeProfile {
                    claudeSection(profile: profile)

                    Divider().overlay(AppTheme.Colors.divider).padding(.vertical, AppTheme.Spacing.sm)

                    otherProvidersSection(profile: profile)
                } else {
                    Text("No active profile")
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }

                Spacer()
            }
            .padding(28)
        }
        .sheet(item: $activeSheet) { sheet in
            credentialsSheet(for: sheet, profileId: profileManager.activeProfile?.id)
        }
    }

    // MARK: - Claude Section

    @ViewBuilder
    private func claudeSection(profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AIProvider.claude.brandColor.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: "hexagon.fill")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AIProvider.claude.brandColor)
                }
                Text("Claude")
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                if profile.hasUsageCredentials {
                    Circle()
                        .fill(AppTheme.Colors.success)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.success)
                }
            }

            PersonalUsageView()

            Divider().overlay(AppTheme.Colors.divider)

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text("section.api_console_title".localized)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.top, AppTheme.Spacing.sm)

            APIBillingView()

            Divider().overlay(AppTheme.Colors.divider)

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "terminal.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text("section.cli_account_title".localized)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.top, AppTheme.Spacing.sm)

            CLIAccountView()
        }
    }

    // MARK: - Other Providers Section

    @ViewBuilder
    private func otherProvidersSection(profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "cpu.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text("Other Providers")
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                if featureFlags.isFree {
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
                ProUpsellCard(
                    title: "Multi-AI Tracking (Pro)",
                    message: "Track Claude, Codex, Gemini, Copilot, Kimi, DeepSeek, GLM, Qwen, and MiniMax together so your next provider choice is obvious.",
                    actionTitle: "Upgrade to Pro"
                ) {
                    if let url = LicenseManager.shared.proCheckoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            } else {
                ForEach(AIProvider.visibleProviders.filter { $0 != .claude }) { provider in
                    providerRow(provider: provider, profile: profile)
                }
            }
        }
    }

    @ViewBuilder
    private func providerRow(provider: AIProvider, profile: Profile) -> some View {
        let connected = isConnected(provider, profile: profile)

        Button(action: {
            if !featureFlags.isFree || provider.isFreeTier {
                openProviderSheet(provider: provider, profile: profile)
            } else if let url = LicenseManager.shared.proCheckoutURL {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(provider.brandColor.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: provider.icon)
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(provider.brandColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(provider.shortName)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if provider.requiresPro && featureFlags.isFree {
                            Text("PRO")
                                .font(AppTheme.Typography.badge)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.proBadge.opacity(0.22))
                                )
                        }
                    }

                    Text(provider.description)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Circle()
                    .fill(connected ? AppTheme.Colors.success : AppTheme.Colors.textMuted.opacity(0.35))
                    .frame(width: 8, height: 8)

                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
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
        }
        .buttonStyle(.plain)
    }

    private func isConnected(_ provider: AIProvider, profile: Profile) -> Bool {
        switch provider {
        case .claude:
            return profile.hasUsageCredentials
        case .codex:
            return profile.hasCodexCredentials
        case .gemini:
            return profile.hasGeminiCredentials || profile.geminiOAuthConnected
        case .copilot:
            return profile.hasCopilotCredentials || profile.copilotOAuthConnected
        case .kimi:
            return profile.hasKimiCredentials
        case .deepseek:
            return profile.hasDeepSeekCredentials
        case .glm:
            return profile.hasGLMCredentials
        case .qwen:
            return profile.hasQwenCredentials
        case .minimax:
            return profile.hasMiniMaxCredentials
        }
    }

    private func openProviderSheet(provider: AIProvider, profile: Profile) {
        switch provider {
        case .claude:
            break
        case .codex:
            activeSheet = .codex
        case .gemini:
            activeSheet = profile.geminiOAuthConnected ? .geminiOAuth : .gemini
        case .copilot:
            activeSheet = profile.copilotOAuthConnected ? .copilotOAuth : .copilot
        case .kimi:
            activeSheet = .kimi
        case .deepseek:
            activeSheet = .deepseek
        case .glm:
            activeSheet = .glm
        case .qwen:
            activeSheet = .qwen
        case .minimax:
            activeSheet = .minimax
        }
    }

    @ViewBuilder
    private func credentialsSheet(for sheet: ProviderSheet, profileId: UUID?) -> some View {
        if let profileId = profileId {
            switch sheet {
            case .codex:
                CodexCredentialsSheet(profileId: profileId)
            case .gemini:
                GeminiCredentialsSheet(profileId: profileId)
            case .copilot:
                CopilotCredentialsSheet(profileId: profileId)
            case .geminiOAuth:
                GeminiOAuthSheet(profileId: profileId)
            case .copilotOAuth:
                CopilotOAuthSheet(profileId: profileId)
            case .kimi, .deepseek, .glm, .qwen, .minimax:
                UnavailableProviderView(provider: providerForSheet(sheet))
            }
        }
    }

    private func providerForSheet(_ sheet: ProviderSheet) -> AIProvider {
        switch sheet {
        case .codex: return .codex
        case .gemini, .geminiOAuth: return .gemini
        case .copilot, .copilotOAuth: return .copilot
        case .kimi: return .kimi
        case .deepseek: return .deepseek
        case .glm: return .glm
        case .qwen: return .qwen
        case .minimax: return .minimax
        }
    }
}

// The credential sheet types (CodexCredentialsSheet, GeminiCredentialsSheet,
// CopilotCredentialsSheet, GeminiOAuthSheet, CopilotOAuthSheet) are defined
// in AIProvidersSettingsView.swift and reused here.

private struct UnavailableProviderView: View {
    let provider: AIProvider
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text(provider.displayName)
                    .font(AppTheme.Typography.pageTitle)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }

            Text("Full usage API integration for \(provider.displayName) is coming soon. Credential storage is available now.")
                .font(AppTheme.Typography.small)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
        .frame(width: 500, height: 300)
    }
}

#Preview {
    CredentialsSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
