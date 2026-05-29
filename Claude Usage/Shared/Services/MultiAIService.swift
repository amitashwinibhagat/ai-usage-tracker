//
//  MultiAIService.swift
//  Claude Usage
//
//  Coordinates fetching usage from all configured AI providers.
//

import Foundation

/// Result of fetching usage from all providers for a profile
struct MultiAIUsageResult {
    let profileId: UUID
    let claudeUsage: ClaudeUsage?
    let codexUsage: CodexUsage?
    let geminiUsage: GeminiUsage?
    let copilotUsage: CopilotUsage?
    let kimiUsage: KimiUsage?
    let deepseekUsage: DeepSeekUsage?
    let glmUsage: GLMUsage?
    let qwenUsage: QwenUsage?
    let minimaxUsage: MiniMaxUsage?
    let errors: [AIProvider: Error]

    /// Multi-AI usage data as a dictionary (excludes Claude)
    var allUsage: [AIProvider: any ProviderUsage] {
        var result: [AIProvider: any ProviderUsage] = [:]
        if let u = codexUsage { result[.codex] = u }
        if let u = geminiUsage { result[.gemini] = u }
        if let u = copilotUsage { result[.copilot] = u }
        if let u = kimiUsage { result[.kimi] = u }
        if let u = deepseekUsage { result[.deepseek] = u }
        if let u = glmUsage { result[.glm] = u }
        if let u = qwenUsage { result[.qwen] = u }
        if let u = minimaxUsage { result[.minimax] = u }
        return result
    }

    /// Total estimated cost across all providers
    var totalEstimatedCost: Double {
        var total: Double = 0
        if let cost = claudeUsage?.costUsed { total += cost / 100.0 }
        if let cost = codexUsage?.estimatedCost { total += cost }
        if let cost = geminiUsage?.estimatedCost { total += cost }
        if let cost = copilotUsage?.estimatedCost { total += cost }
        if let cost = kimiUsage?.estimatedCost { total += cost }
        if let cost = deepseekUsage?.estimatedCost { total += cost }
        if let cost = glmUsage?.estimatedCost { total += cost }
        if let cost = qwenUsage?.estimatedCost { total += cost }
        if let cost = minimaxUsage?.estimatedCost { total += cost }
        return total
    }

    /// Number of providers with valid usage data
    var activeProviderCount: Int {
        allUsage.values.filter { $0.isValid }.count
    }

    /// Whether any provider has data
    var hasData: Bool {
        activeProviderCount > 0
    }
}

/// Coordinates multi-AI usage fetching
@MainActor
final class MultiAIService {
    static let shared = MultiAIService()

    private let codexService = CodexAPIService.shared
    private let geminiService = GeminiAPIService.shared
    private let copilotService = CopilotAPIService.shared
    private let kimiService = KimiAPIService.shared
    private let deepseekService = DeepSeekAPIService.shared
    private let glmService = GLMAPIService.shared
    private let qwenService = QwenAPIService.shared
    private let minimaxService = MiniMaxAPIService.shared

    private init() {}

    // MARK: - Public API

    /// Fetches usage from all configured providers for a profile
    func fetchAllUsage(for profile: Profile) async -> MultiAIUsageResult {
        var errors: [AIProvider: Error] = [:]

        // Fetch Codex usage
        var codexUsage: CodexUsage?
        if profile.hasCodexCredentials, let apiKey = profile.codexApiKey {
            do {
                let credentials = CodexCredentials(apiKey: apiKey, organizationId: profile.codexOrganizationId)
                codexUsage = try await codexService.fetchUsage(credentials: credentials)
                ProfileManager.shared.saveCodexUsage(codexUsage!, for: profile.id)
            } catch {
                errors[.codex] = error
                LoggingService.shared.logError("Failed to fetch Codex usage: \(error.localizedDescription)")
            }
        }

        // Fetch Gemini usage
        var geminiUsage: GeminiUsage?
        if profile.hasGeminiCredentials {
            do {
                let oauthToken = OAuthTokenStore.shared.load(provider: .gemini, profileId: profile.id)
                let credentials = GeminiCredentials(
                    apiKey: profile.geminiApiKey,
                    projectId: profile.geminiProjectId,
                    oauthAccessToken: oauthToken?.accessToken
                )
                geminiUsage = try await geminiService.fetchUsage(credentials: credentials)
                ProfileManager.shared.saveGeminiUsage(geminiUsage!, for: profile.id)
            } catch {
                errors[.gemini] = error
                LoggingService.shared.logError("Failed to fetch Gemini usage: \(error.localizedDescription)")
            }
        }

        // Fetch Copilot usage
        var copilotUsage: CopilotUsage?
        if profile.hasCopilotCredentials {
            do {
                let oauthToken = OAuthTokenStore.shared.load(provider: .copilot, profileId: profile.id)
                let credentials = CopilotCredentials(
                    accessToken: profile.copilotAccessToken,
                    username: profile.copilotUsername,
                    oauthAccessToken: oauthToken?.accessToken
                )
                copilotUsage = try await copilotService.fetchUsage(credentials: credentials)
                ProfileManager.shared.saveCopilotUsage(copilotUsage!, for: profile.id)
            } catch {
                errors[.copilot] = error
                LoggingService.shared.logError("Failed to fetch Copilot usage: \(error.localizedDescription)")
            }
        }

        // Fetch Kimi usage
        var kimiUsage: KimiUsage?
        if profile.hasKimiCredentials, let apiKey = profile.kimiApiKey {
            do {
                let credentials = KimiCredentials(apiKey: apiKey)
                kimiUsage = try await kimiService.fetchUsage(credentials: credentials)
                if let usage = kimiUsage {
                    ProfileManager.shared.saveKimiUsage(usage, for: profile.id)
                }
            } catch {
                errors[.kimi] = error
                LoggingService.shared.logError("Failed to fetch Kimi usage: \(error.localizedDescription)")
            }
        }

        // Fetch DeepSeek usage
        var deepseekUsage: DeepSeekUsage?
        if profile.hasDeepSeekCredentials, let apiKey = profile.deepseekApiKey {
            do {
                let credentials = DeepSeekCredentials(apiKey: apiKey)
                deepseekUsage = try await deepseekService.fetchUsage(credentials: credentials)
                if let usage = deepseekUsage {
                    ProfileManager.shared.saveDeepSeekUsage(usage, for: profile.id)
                }
            } catch {
                errors[.deepseek] = error
                LoggingService.shared.logError("Failed to fetch DeepSeek usage: \(error.localizedDescription)")
            }
        }

        // Fetch GLM usage
        var glmUsage: GLMUsage?
        if profile.hasGLMCredentials, let apiKey = profile.glmApiKey {
            do {
                let credentials = GLMCredentials(apiKey: apiKey)
                glmUsage = try await glmService.fetchUsage(credentials: credentials)
                if let usage = glmUsage {
                    ProfileManager.shared.saveGLMUsage(usage, for: profile.id)
                }
            } catch {
                errors[.glm] = error
                LoggingService.shared.logError("Failed to fetch GLM usage: \(error.localizedDescription)")
            }
        }

        // Fetch Qwen usage
        var qwenUsage: QwenUsage?
        if profile.hasQwenCredentials, let apiKey = profile.qwenApiKey {
            do {
                let credentials = QwenCredentials(apiKey: apiKey)
                qwenUsage = try await qwenService.fetchUsage(credentials: credentials)
                if let usage = qwenUsage {
                    ProfileManager.shared.saveQwenUsage(usage, for: profile.id)
                }
            } catch {
                errors[.qwen] = error
                LoggingService.shared.logError("Failed to fetch Qwen usage: \(error.localizedDescription)")
            }
        }

        // Fetch MiniMax usage
        var minimaxUsage: MiniMaxUsage?
        if profile.hasMiniMaxCredentials, let apiKey = profile.minimaxApiKey {
            do {
                let credentials = MiniMaxCredentials(apiKey: apiKey, groupId: profile.minimaxGroupId)
                minimaxUsage = try await minimaxService.fetchUsage(credentials: credentials)
                if let usage = minimaxUsage {
                    ProfileManager.shared.saveMiniMaxUsage(usage, for: profile.id)
                }
            } catch {
                errors[.minimax] = error
                LoggingService.shared.logError("Failed to fetch MiniMax usage: \(error.localizedDescription)")
            }
        }

        return MultiAIUsageResult(
            profileId: profile.id,
            claudeUsage: profile.claudeUsage,
            codexUsage: codexUsage,
            geminiUsage: geminiUsage,
            copilotUsage: copilotUsage,
            kimiUsage: kimiUsage,
            deepseekUsage: deepseekUsage,
            glmUsage: glmUsage,
            qwenUsage: qwenUsage,
            minimaxUsage: minimaxUsage,
            errors: errors
        )
    }

    /// Fetches usage for a single non-Claude provider
    func fetchUsage(for provider: AIProvider, profile: Profile) async -> (any ProviderUsage)? {
        switch provider {
        case .claude:
            return nil
        case .codex:
            guard let apiKey = profile.codexApiKey else { return nil }
            let credentials = CodexCredentials(apiKey: apiKey, organizationId: profile.codexOrganizationId)
            return try? await codexService.fetchUsage(credentials: credentials)
        case .gemini:
            guard profile.hasGeminiCredentials else { return nil }
            let oauthToken = OAuthTokenStore.shared.load(provider: .gemini, profileId: profile.id)
            let credentials = GeminiCredentials(
                apiKey: profile.geminiApiKey,
                projectId: profile.geminiProjectId,
                oauthAccessToken: oauthToken?.accessToken
            )
            return try? await geminiService.fetchUsage(credentials: credentials)
        case .copilot:
            guard profile.hasCopilotCredentials else { return nil }
            let oauthToken = OAuthTokenStore.shared.load(provider: .copilot, profileId: profile.id)
            let credentials = CopilotCredentials(
                accessToken: profile.copilotAccessToken,
                username: profile.copilotUsername,
                oauthAccessToken: oauthToken?.accessToken
            )
            return try? await copilotService.fetchUsage(credentials: credentials)
        case .kimi:
            guard let apiKey = profile.kimiApiKey else { return nil }
            let credentials = KimiCredentials(apiKey: apiKey)
            return try? await kimiService.fetchUsage(credentials: credentials)
        case .deepseek:
            guard let apiKey = profile.deepseekApiKey else { return nil }
            let credentials = DeepSeekCredentials(apiKey: apiKey)
            return try? await deepseekService.fetchUsage(credentials: credentials)
        case .glm:
            guard let apiKey = profile.glmApiKey else { return nil }
            let credentials = GLMCredentials(apiKey: apiKey)
            return try? await glmService.fetchUsage(credentials: credentials)
        case .qwen:
            guard let apiKey = profile.qwenApiKey else { return nil }
            let credentials = QwenCredentials(apiKey: apiKey)
            return try? await qwenService.fetchUsage(credentials: credentials)
        case .minimax:
            guard let apiKey = profile.minimaxApiKey else { return nil }
            let credentials = MiniMaxCredentials(apiKey: apiKey, groupId: profile.minimaxGroupId)
            return try? await minimaxService.fetchUsage(credentials: credentials)
        }
    }

    /// Returns which providers are available for fetching (visible + license-compatible)
    var availableProviders: [AIProvider] {
        AIProvider.visibleProviders.filter { provider in
            if provider.isFreeTier { return true }
            return FeatureFlags.shared.isAvailable(FeatureFlags.shared.multiAI)
        }
    }
}
