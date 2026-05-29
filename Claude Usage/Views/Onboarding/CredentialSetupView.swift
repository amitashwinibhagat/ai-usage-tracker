import SwiftUI

struct CredentialSetupView: View {
    let selectedMethods: Set<OnboardingMethod>
    var onDismiss: () -> Void

    @State private var showingAuthSheet = false
    @State private var apiKeyText = ""
    @State private var claudeAISessionKey: String?
    @State private var isSaving = false
    @State private var savedClaudeAI = false
    @State private var savedCLI = false
    @State private var savedAPI = false
    @State private var errorMessage: String?

    private var needsClaudeAI: Bool { selectedMethods.contains(.claudeAI) }
    private var needsClaudeCode: Bool { selectedMethods.contains(.claudeCode) }
    private var needsAPIConsole: Bool { selectedMethods.contains(.apiConsole) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("onboarding.credentials.title".localized)
                            .font(AppTheme.Typography.pageTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("onboarding.credentials.subtitle".localized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    if needsClaudeAI {
                        claudeAISection
                    }

                    if needsClaudeCode {
                        claudeCodeSection
                    }

                    if needsAPIConsole {
                        apiConsoleSection
                    }

                    if let errorMessage = errorMessage {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(AppTheme.Typography.tiny)
                                .foregroundColor(AppTheme.Colors.error)
                            Text(errorMessage)
                                .font(AppTheme.Typography.tiny)
                                .foregroundColor(AppTheme.Colors.error)
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.error.opacity(0.1))
                        )
                    }

                    Text("onboarding.credentials.add_later".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .padding(AppTheme.Spacing.xl)
            }

            Divider()
                .overlay(AppTheme.Colors.divider)

            HStack {
                Spacer()

                Button(action: saveAndDismiss) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text("onboarding.credentials.start_tracking".localized)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding(AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.sm)
        }
        .frame(width: 420, height: 380)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAuthSheet) {
            ConsoleAuthSheet(
                title: "personal.signin_sheet_title".localized,
                loginURL: URL(string: "https://claude.ai/login")!,
                cookieDomain: "claude.ai",
                onSuccess: { result in
                    showingAuthSheet = false
                    claudeAISessionKey = result.sessionKey
                    savedClaudeAI = true
                },
                onCancel: {
                    showingAuthSheet = false
                }
            )
        }
    }

    // MARK: - Claude.ai Section

    private var claudeAISection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "globe")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.accent)
                Text("onboarding.credentials.claudeai_header".localized)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            if savedClaudeAI {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.success)
                    Text("onboarding.credentials.signed_in".localized)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.success)
                }
            } else {
                Button(action: { showingAuthSheet = true }) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "globe")
                            .font(AppTheme.Typography.small)
                        Text("personal.signin_button".localized)
                            .font(AppTheme.Typography.small)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }

    // MARK: - Claude Code Section

    private var claudeCodeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "apple.terminal.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.success)
                Text("onboarding.credentials.claudecode_header".localized)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            if savedCLI {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.success)
                    Text("onboarding.credentials.cli_ready".localized)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.success)
                }
            } else {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.success)
                    Text("onboarding.credentials.cli_detected_desc".localized)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }

    // MARK: - API Console Section

    private var apiConsoleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.accent)
                Text("onboarding.credentials.apiconsole_header".localized)
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            if savedAPI {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.success)
                    Text("onboarding.credentials.api_key_saved".localized)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.success)
                }
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("personal.label_session_key".localized)
                        .font(AppTheme.Typography.smallMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    SecureField("personal.placeholder_session_key".localized, text: $apiKeyText)
                        .textFieldStyle(.plain)
                        .font(AppTheme.Typography.monoSmall)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.compact)
                                .fill(AppTheme.Colors.inputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.compact)
                                        .strokeBorder(AppTheme.Colors.inputBorder, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }

    // MARK: - Save

    private func saveAndDismiss() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                guard let profileId = ProfileManager.shared.activeProfile?.id else {
                    throw NSError(domain: "CredentialSetup", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "No active profile found"])
                }

                var creds = try ProfileStore.shared.loadProfileCredentials(profileId)
                var profile = ProfileManager.shared.activeProfile ?? Profile(
                    id: profileId,
                    name: "Default",
                    hasCliAccount: false
                )

                if needsClaudeAI, let sessionKey = claudeAISessionKey {
                    creds.claudeSessionKey = sessionKey
                    profile.claudeSessionKey = sessionKey
                }

                if needsAPIConsole && !apiKeyText.isEmpty {
                    creds.apiSessionKey = apiKeyText
                    profile.apiSessionKey = apiKeyText
                }

                if needsClaudeCode {
                    do {
                        try ClaudeCodeSyncService.shared.syncToProfile(profileId)
                        await MainActor.run { savedCLI = true }
                    } catch {
                        LoggingService.shared.logError("Failed to sync CLI credentials: \(error)")
                    }
                }

                try ProfileStore.shared.saveProfileCredentials(profileId, credentials: creds)
                ProfileManager.shared.updateProfile(profile)

                try? StatuslineService.shared.updateScriptsIfInstalled()
                SharedDataStore.shared.saveHasCompletedSetup(true)
                NotificationCenter.default.post(name: .credentialsChanged, object: nil)

                await MainActor.run {
                    isSaving = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    CredentialSetupView(
        selectedMethods: [.claudeAI, .claudeCode],
        onDismiss: {}
    )
}
