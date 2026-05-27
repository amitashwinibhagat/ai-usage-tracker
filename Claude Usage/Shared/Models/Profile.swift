//
//  Profile.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-07.
//

import Foundation

/// Represents a complete isolated profile with all credentials and settings
struct Profile: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: UUID
    var name: String

    // MARK: - Credentials (stored directly in profile)
    var claudeSessionKey: String?
    var organizationId: String?
    var apiSessionKey: String?
    var apiOrganizationId: String?
    var apiSessionKeyExpiry: Date?
    var cliCredentialsJSON: String?

    // MARK: - CLI Account Sync Metadata
    var hasCliAccount: Bool
    var cliAccountSyncedAt: Date?

    /// Serialized `oauthAccount` object from Claude Code's `.claude.json` config file.
    /// Captured at sync time and re-applied during profile switches so that
    /// Claude Code's `/status` command shows the correct account for the active
    /// profile. Stored as a raw JSON string to preserve unknown/future fields
    /// (emailAddress, accountUuid, organizationName, billingType, etc.).
    var oauthAccountJSON: String?

    // MARK: - Usage Data (Per-Profile)
    var claudeUsage: ClaudeUsage?
    var apiUsage: APIUsage?

    // MARK: - Multi-AI Provider Usage Data (Per-Profile, Pro)
    var codexUsage: CodexUsage?
    var geminiUsage: GeminiUsage?
    var copilotUsage: CopilotUsage?
    var kimiUsage: KimiUsage?
    var deepseekUsage: DeepSeekUsage?
    var glmUsage: GLMUsage?
    var qwenUsage: QwenUsage?
    var minimaxUsage: MiniMaxUsage?

    // MARK: - Multi-AI Provider Credentials (Per-Profile, Pro)
    var codexApiKey: String?
    var codexOrganizationId: String?
    var geminiApiKey: String?
    var geminiProjectId: String?
    var copilotAccessToken: String?
    var copilotUsername: String?
    var kimiApiKey: String?
    var deepseekApiKey: String?
    var glmApiKey: String?
    var qwenApiKey: String?
    var minimaxApiKey: String?
    var minimaxGroupId: String?

    // MARK: - OAuth Connection State (Per-Profile)
    /// Whether Gemini is connected via OAuth (tokens stored in Keychain)
    var geminiOAuthConnected: Bool = false
    /// Whether Copilot is connected via OAuth (tokens stored in Keychain)
    var copilotOAuthConnected: Bool = false

    // MARK: - Appearance Settings (Per-Profile)
    var iconConfig: MenuBarIconConfiguration

    // MARK: - Behavior Settings (Per-Profile)
    var refreshInterval: TimeInterval
    var autoStartSessionEnabled: Bool
    var checkOverageLimitEnabled: Bool

    // MARK: - Notification Settings (Per-Profile)
    var notificationSettings: NotificationSettings

    // MARK: - Session Planning Settings (Per-Profile)
    var sessionPlanningSettings: SessionPlanningSettings?

    // MARK: - Display Configuration
    var isSelectedForDisplay: Bool  // For multi-profile menu bar mode

    // MARK: - Metadata
    var createdAt: Date
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        claudeSessionKey: String? = nil,
        organizationId: String? = nil,
        apiSessionKey: String? = nil,
        apiOrganizationId: String? = nil,
        apiSessionKeyExpiry: Date? = nil,
        cliCredentialsJSON: String? = nil,
        hasCliAccount: Bool = false,
        cliAccountSyncedAt: Date? = nil,
        oauthAccountJSON: String? = nil,
        claudeUsage: ClaudeUsage? = nil,
        apiUsage: APIUsage? = nil,
        codexUsage: CodexUsage? = nil,
        geminiUsage: GeminiUsage? = nil,
        copilotUsage: CopilotUsage? = nil,
        kimiUsage: KimiUsage? = nil,
        deepseekUsage: DeepSeekUsage? = nil,
        glmUsage: GLMUsage? = nil,
        qwenUsage: QwenUsage? = nil,
        minimaxUsage: MiniMaxUsage? = nil,
        codexApiKey: String? = nil,
        codexOrganizationId: String? = nil,
        geminiApiKey: String? = nil,
        geminiProjectId: String? = nil,
        copilotAccessToken: String? = nil,
        copilotUsername: String? = nil,
        kimiApiKey: String? = nil,
        deepseekApiKey: String? = nil,
        glmApiKey: String? = nil,
        qwenApiKey: String? = nil,
        minimaxApiKey: String? = nil,
        minimaxGroupId: String? = nil,
        geminiOAuthConnected: Bool = false,
        copilotOAuthConnected: Bool = false,
        iconConfig: MenuBarIconConfiguration = .default,
        refreshInterval: TimeInterval = 30.0,
        autoStartSessionEnabled: Bool = false,
        checkOverageLimitEnabled: Bool = true,
        notificationSettings: NotificationSettings = NotificationSettings(),
        sessionPlanningSettings: SessionPlanningSettings? = nil,
        isSelectedForDisplay: Bool = true,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.claudeSessionKey = claudeSessionKey
        self.organizationId = organizationId
        self.apiSessionKey = apiSessionKey
        self.apiOrganizationId = apiOrganizationId
        self.apiSessionKeyExpiry = apiSessionKeyExpiry
        self.cliCredentialsJSON = cliCredentialsJSON
        self.hasCliAccount = hasCliAccount
        self.cliAccountSyncedAt = cliAccountSyncedAt
        self.oauthAccountJSON = oauthAccountJSON
        self.claudeUsage = claudeUsage
        self.apiUsage = apiUsage
        self.codexUsage = codexUsage
        self.geminiUsage = geminiUsage
        self.copilotUsage = copilotUsage
        self.kimiUsage = kimiUsage
        self.deepseekUsage = deepseekUsage
        self.glmUsage = glmUsage
        self.qwenUsage = qwenUsage
        self.minimaxUsage = minimaxUsage
        self.codexApiKey = codexApiKey
        self.codexOrganizationId = codexOrganizationId
        self.geminiApiKey = geminiApiKey
        self.geminiProjectId = geminiProjectId
        self.copilotAccessToken = copilotAccessToken
        self.copilotUsername = copilotUsername
        self.kimiApiKey = kimiApiKey
        self.deepseekApiKey = deepseekApiKey
        self.glmApiKey = glmApiKey
        self.qwenApiKey = qwenApiKey
        self.minimaxApiKey = minimaxApiKey
        self.minimaxGroupId = minimaxGroupId
        self.geminiOAuthConnected = geminiOAuthConnected
        self.copilotOAuthConnected = copilotOAuthConnected
        self.iconConfig = iconConfig
        self.refreshInterval = refreshInterval
        self.autoStartSessionEnabled = autoStartSessionEnabled
        self.checkOverageLimitEnabled = checkOverageLimitEnabled
        self.notificationSettings = notificationSettings
        self.sessionPlanningSettings = sessionPlanningSettings
        self.isSelectedForDisplay = isSelectedForDisplay
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    // MARK: - Computed Properties
    var hasClaudeAI: Bool {
        claudeSessionKey != nil && organizationId != nil
    }

    var hasAPIConsole: Bool {
        apiSessionKey != nil && apiOrganizationId != nil
    }

    /// True if profile has credentials that can fetch usage data (Claude.ai, CLI OAuth, or API Console)
    /// Note: System keychain fallback is handled in ClaudeAPIService.getAuthentication() during actual API calls
    var hasUsageCredentials: Bool {
        hasClaudeAI || hasAPIConsole || hasValidCLIOAuth
    }

    /// True if profile has CLI OAuth credentials that are not expired
    var hasValidCLIOAuth: Bool {
        guard let cliJSON = cliCredentialsJSON else { return false }
        return !ClaudeCodeSyncService.shared.isTokenExpired(cliJSON)
    }

    var hasAnyCredentials: Bool {
        hasClaudeAI || hasAPIConsole || cliCredentialsJSON != nil
    }

    // MARK: - Multi-AI Provider Credentials

    var hasCodexCredentials: Bool {
        codexApiKey != nil && !codexApiKey!.isEmpty
    }

    var hasGeminiCredentials: Bool {
        (geminiApiKey != nil && !geminiApiKey!.isEmpty) || geminiOAuthConnected
    }

    var hasCopilotCredentials: Bool {
        (copilotAccessToken != nil && !copilotAccessToken!.isEmpty) || copilotOAuthConnected
    }

    var hasKimiCredentials: Bool {
        kimiApiKey != nil && !kimiApiKey!.isEmpty
    }

    var hasDeepSeekCredentials: Bool {
        deepseekApiKey != nil && !deepseekApiKey!.isEmpty
    }

    var hasGLMCredentials: Bool {
        glmApiKey != nil && !glmApiKey!.isEmpty
    }

    var hasQwenCredentials: Bool {
        qwenApiKey != nil && !qwenApiKey!.isEmpty
    }

    var hasMiniMaxCredentials: Bool {
        minimaxApiKey != nil && !minimaxApiKey!.isEmpty
    }

    /// Returns true if the profile has credentials for any non-Claude provider
    var hasMultiAICredentials: Bool {
        hasCodexCredentials || hasGeminiCredentials || hasCopilotCredentials ||
        hasKimiCredentials || hasDeepSeekCredentials || hasGLMCredentials ||
        hasQwenCredentials || hasMiniMaxCredentials
    }

    /// Returns the set of providers this profile has credentials for
    var configuredProviders: [AIProvider] {
        var providers: [AIProvider] = []
        if hasClaudeAI || hasAPIConsole || hasValidCLIOAuth {
            providers.append(.claude)
        }
        if hasCodexCredentials { providers.append(.codex) }
        if hasGeminiCredentials { providers.append(.gemini) }
        if hasCopilotCredentials { providers.append(.copilot) }
        if hasKimiCredentials { providers.append(.kimi) }
        if hasDeepSeekCredentials { providers.append(.deepseek) }
        if hasGLMCredentials { providers.append(.glm) }
        if hasQwenCredentials { providers.append(.qwen) }
        if hasMiniMaxCredentials { providers.append(.minimax) }
        return providers
    }

    /// Returns usage for a specific provider (if available)
    func usage(for provider: AIProvider) -> (any ProviderUsage)? {
        switch provider {
        case .claude:
            return nil // ClaudeUsage does not conform to ProviderUsage
        case .codex:
            return codexUsage
        case .gemini:
            return geminiUsage
        case .copilot:
            return copilotUsage
        case .kimi:
            return kimiUsage
        case .deepseek:
            return deepseekUsage
        case .glm:
            return glmUsage
        case .qwen:
            return qwenUsage
        case .minimax:
            return minimaxUsage
        }
    }
}

// MARK: - ProfileCredentials (for compatibility)
/// Simple struct for passing credentials around
struct ProfileCredentials {
    var claudeSessionKey: String?
    var organizationId: String?
    var apiSessionKey: String?
    var apiOrganizationId: String?
    var apiSessionKeyExpiry: Date?
    var cliCredentialsJSON: String?

    var hasClaudeAI: Bool {
        claudeSessionKey != nil && organizationId != nil
    }

    var hasAPIConsole: Bool {
        apiSessionKey != nil && apiOrganizationId != nil
    }

    var hasCLI: Bool {
        cliCredentialsJSON != nil
    }
}
