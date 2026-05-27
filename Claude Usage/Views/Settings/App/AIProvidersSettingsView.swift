//
//  AIProvidersSettingsView.swift
//  Claude Usage
//
//  Settings view for managing multi-AI provider credentials.
//

import SwiftUI

struct AIProvidersSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared

    // Sheet states
    @State private var activeSheet: ProviderSheet? = nil

    enum ProviderSheet: Identifiable {
        case codex, gemini, copilot, kimi, deepseek, glm, qwen, minimax
        case geminiOAuth, copilotOAuth
        var id: Int { hashValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                SettingsPageHeader(
                    title: "AI Providers",
                    subtitle: "Track usage across all your AI coding tools"
                )

                if featureFlags.isFree {
                    ProUpsellCard(
                        title: "Multi-AI Tracking (Pro)",
                        message: "Pro users can track Claude, Codex, Gemini, Copilot, Kimi, DeepSeek, GLM, Qwen, and MiniMax usage in one place. Upgrade to see your complete AI spending picture.",
                        actionTitle: "Upgrade to Pro"
                    ) {
                        if let url = LicenseManager.shared.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if let profile = profileManager.activeProfile {
                    // Claude (always available)
                    ProviderCard(
                        provider: .claude,
                        isConnected: profile.hasUsageCredentials,
                        status: profile.hasUsageCredentials ? "Connected" : "Add credentials in Personal Usage",
                        usage: profile.claudeUsage?.sessionTokensUsed
                    )

                    if featureFlags.isProOrHigher {
                        providerSection(profile: profile)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .sheet(item: $activeSheet) { sheet in
            credentialsSheet(for: sheet, profileId: profileManager.activeProfile?.id)
        }
    }

    @ViewBuilder
    private func providerSection(profile: Profile) -> some View {
        // Western providers
        ProviderCard(
            provider: .codex,
            isConnected: profile.hasCodexCredentials,
            status: profile.hasCodexCredentials ? "Connected" : "API key required",
            usage: profile.codexUsage?.tokensUsed
        ) { activeSheet = .codex }

        Divider()

        if profile.geminiOAuthConnected {
            ProviderCard(
                provider: .gemini,
                isConnected: true,
                status: "Signed in with Google",
                usage: profile.geminiUsage?.tokensUsed
            ) { activeSheet = .geminiOAuth }
        } else {
            ProviderCard(
                provider: .gemini,
                isConnected: profile.hasGeminiCredentials,
                status: profile.hasGeminiCredentials ? "Connected via API key" : "Sign in or add API key",
                usage: profile.geminiUsage?.tokensUsed
            ) { activeSheet = .gemini }
        }

        Divider()

        if profile.copilotOAuthConnected {
            ProviderCard(
                provider: .copilot,
                isConnected: true,
                status: "Signed in with GitHub \(profile.copilotUsername ?? "")",
                usage: profile.copilotUsage?.suggestionsAccepted
            ) { activeSheet = .copilotOAuth }
        } else {
            ProviderCard(
                provider: .copilot,
                isConnected: profile.hasCopilotCredentials,
                status: profile.hasCopilotCredentials ? "Connected via token \(profile.copilotUsername ?? "")" : "Sign in or add token",
                usage: profile.copilotUsage?.suggestionsAccepted
            ) { activeSheet = .copilot }
        }

        // Chinese providers
        SectionHeader(title: "Chinese Providers")

        ProviderCard(
            provider: .kimi,
            isConnected: profile.hasKimiCredentials,
            status: profile.hasKimiCredentials ? "Connected" : "API key required",
            usage: profile.kimiUsage?.tokensUsed
        ) { activeSheet = .kimi }

        Divider()

        ProviderCard(
            provider: .deepseek,
            isConnected: profile.hasDeepSeekCredentials,
            status: profile.hasDeepSeekCredentials ? "Connected" : "API key required",
            usage: profile.deepseekUsage?.tokensUsed
        ) { activeSheet = .deepseek }

        Divider()

        ProviderCard(
            provider: .glm,
            isConnected: profile.hasGLMCredentials,
            status: profile.hasGLMCredentials ? "Connected" : "API key required",
            usage: profile.glmUsage?.tokensUsed
        ) { activeSheet = .glm }

        Divider()

        ProviderCard(
            provider: .qwen,
            isConnected: profile.hasQwenCredentials,
            status: profile.hasQwenCredentials ? "Connected" : "API key required",
            usage: profile.qwenUsage?.tokensUsed
        ) { activeSheet = .qwen }

        Divider()

        ProviderCard(
            provider: .minimax,
            isConnected: profile.hasMiniMaxCredentials,
            status: profile.hasMiniMaxCredentials ? "Connected" : "API key required",
            usage: profile.minimaxUsage?.tokensUsed
        ) { activeSheet = .minimax }
    }

    @ViewBuilder
    private func credentialsSheet(for sheet: ProviderSheet, profileId: UUID?) -> some View {
        switch sheet {
        case .codex:
            CodexCredentialsSheet(profileId: profileId)
        case .gemini:
            GeminiCredentialsSheet(profileId: profileId)
        case .copilot:
            CopilotCredentialsSheet(profileId: profileId)
        case .kimi:
            KimiCredentialsSheet(profileId: profileId)
        case .deepseek:
            DeepSeekCredentialsSheet(profileId: profileId)
        case .glm:
            GLMCredentialsSheet(profileId: profileId)
        case .qwen:
            QwenCredentialsSheet(profileId: profileId)
        case .minimax:
            MiniMaxCredentialsSheet(profileId: profileId)
        case .geminiOAuth:
            GeminiOAuthSheet(profileId: profileId)
        case .copilotOAuth:
            CopilotOAuthSheet(profileId: profileId)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.top, 8)
    }
}

// MARK: - Provider Card

struct ProviderCard: View {
    let provider: AIProvider
    let isConnected: Bool
    let status: String
    let usage: Int?
    var onTap: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(provider.brandColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: provider.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(provider.brandColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(provider.displayName)
                            .font(DesignTokens.Typography.bodyMedium)

                        if isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                    }

                    Text(status)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(isConnected ? .secondary : .orange)

                    if let usage = usage, usage > 0 {
                        Text("\(usage.formatted()) used")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: isConnected ? "pencil" : "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(DesignTokens.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(isHovered ? Color.primary.opacity(0.03) : DesignTokens.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .strokeBorder(DesignTokens.Colors.cardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Existing Credential Sheets

struct CodexCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @State private var orgId = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "OpenAI Codex", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "sk-...", text: $apiKey)
                TextFieldRow(title: "Organization ID (optional)", placeholder: "org-...", text: $orgId)
                Link("Get your API key from OpenAI →", destination: URL(string: "https://platform.openai.com/api-keys")!)
            }
        } onSave: {
            ProfileManager.shared.updateCodexCredentials(apiKey: apiKey, organizationId: orgId.isEmpty ? nil : orgId, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

struct GeminiCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @State private var projectId = ""
    @State private var isSigningIn = false
    @State private var authError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Google Gemini")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "AIza...", text: $apiKey)
                TextFieldRow(title: "Project ID (optional)", placeholder: "my-project-123", text: $projectId)
                Link("Get your API key from AI Studio →", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
            }

            Divider()

            VStack(spacing: 8) {
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)

                OAuthSignInButton(
                    provider: .gemini,
                    isLoading: isSigningIn
                ) {
                    startOAuthSignIn()
                }
            }

            if let error = authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)

                Button("Save") {
                    ProfileManager.shared.updateGeminiCredentials(apiKey: apiKey.isEmpty ? nil : apiKey, projectId: projectId.isEmpty ? nil : projectId, for: profileId!)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileId == nil)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func startOAuthSignIn() {
        guard let profileId = profileId else { return }
        isSigningIn = true
        authError = nil

        let config = GoogleOAuthConfiguration()
        OAuthFlowCoordinator.shared.startLogin(
            configuration: config,
            profileId: profileId
        ) { result in
            isSigningIn = false
            switch result {
            case .success:
                ProfileManager.shared.setOAuthConnected(true, provider: .gemini, for: profileId)
                dismiss()
            case .failure(let error):
                if let oauthError = error as? OAuthError, oauthError == OAuthError.userCancelled {
                    // User cancelled, don't show error
                    break
                }
                authError = error.localizedDescription
            }
        }
    }
}

struct CopilotCredentialsSheet: View {
    let profileId: UUID?
    @State private var accessToken = ""
    @State private var username = ""
    @State private var isSigningIn = false
    @State private var authError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("GitHub Copilot")
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "Personal Access Token", placeholder: "ghp_...", text: $accessToken)
                TextFieldRow(title: "GitHub Username", placeholder: "username", text: $username)
                Link("Create a token on GitHub →", destination: URL(string: "https://github.com/settings/tokens")!)
            }

            Divider()

            VStack(spacing: 8) {
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)

                OAuthSignInButton(
                    provider: .copilot,
                    isLoading: isSigningIn
                ) {
                    startOAuthSignIn()
                }
            }

            if let error = authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)

                Button("Save") {
                    ProfileManager.shared.updateCopilotCredentials(accessToken: accessToken.isEmpty ? nil : accessToken, username: username.isEmpty ? nil : username, for: profileId!)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileId == nil)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func startOAuthSignIn() {
        guard let profileId = profileId else { return }
        isSigningIn = true
        authError = nil

        let config = GitHubOAuthConfiguration()
        OAuthFlowCoordinator.shared.startLogin(
            configuration: config,
            profileId: profileId
        ) { result in
            isSigningIn = false
            switch result {
            case .success:
                ProfileManager.shared.setOAuthConnected(true, provider: .copilot, for: profileId)
                dismiss()
            case .failure(let error):
                if let oauthError = error as? OAuthError, oauthError == OAuthError.userCancelled {
                    break
                }
                authError = error.localizedDescription
            }
        }
    }
}

// MARK: - OAuth Management Sheets

struct GeminiOAuthSheet: View {
    let profileId: UUID?
    @State private var isDisconnecting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Google Gemini")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Signed in with Google")
                    .font(DesignTokens.Typography.bodyMedium)
            }

            Text("Your Google account is connected. Usage data is fetched via OAuth.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Button("Disconnect Google Account") {
                disconnect()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isDisconnecting)

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 400)
    }

    private func disconnect() {
        guard let profileId = profileId else { return }
        isDisconnecting = true
        ProfileManager.shared.disconnectOAuth(provider: .gemini, for: profileId)
        isDisconnecting = false
        dismiss()
    }
}

struct CopilotOAuthSheet: View {
    let profileId: UUID?
    @State private var isDisconnecting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("GitHub Copilot")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Signed in with GitHub")
                    .font(DesignTokens.Typography.bodyMedium)
            }

            Text("Your GitHub account is connected. Usage data is fetched via OAuth.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Button("Disconnect GitHub Account") {
                disconnect()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isDisconnecting)

            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 400)
    }

    private func disconnect() {
        guard let profileId = profileId else { return }
        isDisconnecting = true
        ProfileManager.shared.disconnectOAuth(provider: .copilot, for: profileId)
        isDisconnecting = false
        dismiss()
    }
}

// MARK: - OAuth Sign In Button

struct OAuthSignInButton: View {
    let provider: AIProvider
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: provider == .gemini ? "g.circle.fill" : "cat.fill")
                        .font(.system(size: 14))
                }

                Text("Sign in with \(provider == .gemini ? "Google" : "GitHub")")
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(provider == .gemini ? Color(red: 0.26, green: 0.52, blue: 0.96) : Color(red: 0.2, green: 0.2, blue: 0.2))
        .disabled(isLoading)
    }
}

// MARK: - New Credential Sheets

struct KimiCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "Kimi (Moonshot AI)", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "sk-...", text: $apiKey)
                Link("Get your API key from Moonshot →", destination: URL(string: "https://platform.moonshot.cn")!)
            }
        } onSave: {
            ProfileManager.shared.updateKimiCredentials(apiKey: apiKey, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

struct DeepSeekCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "DeepSeek", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "sk-...", text: $apiKey)
                Link("Get your API key from DeepSeek →", destination: URL(string: "https://platform.deepseek.com")!)
            }
        } onSave: {
            ProfileManager.shared.updateDeepSeekCredentials(apiKey: apiKey, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

struct GLMCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "GLM (Zhipu AI)", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "", text: $apiKey)
                Link("Get your API key from Zhipu AI →", destination: URL(string: "https://open.bigmodel.cn")!)
            }
        } onSave: {
            ProfileManager.shared.updateGLMCredentials(apiKey: apiKey, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

struct QwenCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "Qwen (Alibaba DashScope)", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "sk-...", text: $apiKey)
                Link("Get your API key from DashScope →", destination: URL(string: "https://dashscope.aliyun.com")!)
            }
        } onSave: {
            ProfileManager.shared.updateQwenCredentials(apiKey: apiKey, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

struct MiniMaxCredentialsSheet: View {
    let profileId: UUID?
    @State private var apiKey = ""
    @State private var groupId = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CredentialSheet(title: "MiniMax", profileId: profileId, dismiss: dismiss) {
            VStack(alignment: .leading, spacing: 12) {
                SecureFieldRow(title: "API Key", placeholder: "", text: $apiKey)
                TextFieldRow(title: "Group ID (optional)", placeholder: "", text: $groupId)
                Link("Get your API key from MiniMax →", destination: URL(string: "https://www.minimaxi.com")!)
            }
        } onSave: {
            ProfileManager.shared.updateMiniMaxCredentials(apiKey: apiKey, groupId: groupId.isEmpty ? nil : groupId, for: profileId!)
        } isValid: { !apiKey.isEmpty }
    }
}

// MARK: - Reusable Sheet Components

struct CredentialSheet<Content: View>: View {
    let title: String
    let profileId: UUID?
    let dismiss: DismissAction
    @ViewBuilder let content: Content
    let onSave: () -> Void
    let isValid: () -> Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))

            content

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)

                Button("Save") {
                    onSave()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileId == nil || !isValid())
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct SecureFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct TextFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Number formatter

extension Int {
    fileprivate var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
