//
//  AIProvider.swift
//  Claude Usage
//
//  Enum representing all supported AI coding providers.
//

import Foundation
import SwiftUI

/// Supported AI providers for usage tracking
enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case claude = "claude"
    case codex = "codex"
    case gemini = "gemini"
    case copilot = "copilot"
    case kimi = "kimi"
    case deepseek = "deepseek"
    case glm = "glm"
    case qwen = "qwen"
    case minimax = "minimax"

    var id: String { rawValue }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "OpenAI Codex"
        case .gemini: return "Google Gemini"
        case .copilot: return "GitHub Copilot"
        case .kimi: return "Kimi (Moonshot)"
        case .deepseek: return "DeepSeek"
        case .glm: return "GLM (Zhipu AI)"
        case .qwen: return "Qwen (Alibaba)"
        case .minimax: return "MiniMax"
        }
    }

    /// Short display name for compact UI
    var shortName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .gemini: return "Gemini"
        case .copilot: return "Copilot"
        case .kimi: return "Kimi"
        case .deepseek: return "DeepSeek"
        case .glm: return "GLM"
        case .qwen: return "Qwen"
        case .minimax: return "MiniMax"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .claude: return "hexagon.fill"
        case .codex: return "brain.fill"
        case .gemini: return "diamond.fill"
        case .copilot: return "airplane.fill"
        case .kimi: return "moon.fill"
        case .deepseek: return "bolt.fill"
        case .glm: return "cube.fill"
        case .qwen: return "cloud.fill"
        case .minimax: return "rectangle.stack.fill"
        }
    }

    /// Brand color for the provider
    var brandColor: Color {
        switch self {
        case .claude: return Color(red: 0.85, green: 0.35, blue: 0.13)  // Claude orange
        case .codex: return Color(red: 0.0, green: 0.68, blue: 0.51)    // OpenAI teal
        case .gemini: return Color(red: 0.26, green: 0.52, blue: 0.96)  // Google blue
        case .copilot: return Color(red: 0.55, green: 0.27, blue: 0.68) // GitHub purple
        case .kimi: return Color(red: 0.13, green: 0.55, blue: 0.33)    // Moonshot green
        case .deepseek: return Color(red: 0.07, green: 0.47, blue: 0.82) // DeepSeek blue
        case .glm: return Color(red: 0.96, green: 0.26, blue: 0.21)     // Zhipu red
        case .qwen: return Color(red: 1.0, green: 0.55, blue: 0.0)      // Alibaba orange
        case .minimax: return Color(red: 0.35, green: 0.35, blue: 0.35) // MiniMax dark
        }
    }

    /// Whether this provider is shown in the user interface
    /// All providers are now universally available.
    var isShownInUI: Bool {
        true
    }

    /// Providers visible in the UI (subset of allCases)
    static var visibleProviders: [AIProvider] {
        allCases.filter { $0.isShownInUI }
    }

    /// Whether this provider supports OAuth login (vs manual API key)
    var supportsOAuth: Bool {
        switch self {
        case .gemini, .copilot: return true
        case .claude, .codex, .kimi, .deepseek, .glm, .qwen, .minimax: return false
        }
    }

    /// Whether this provider has a real usage-fetching implementation.
    /// The five Chinese providers (Kimi, DeepSeek, GLM, Qwen, MiniMax)
    /// currently only validate API keys against their model list — no
    /// real usage data is fetched. Use this to render a "Coming soon"
    /// badge and disable the row's tap action.
    /// (BUG 4 from the click audit.)
    var isImplemented: Bool {
        switch self {
        case .kimi, .deepseek, .glm, .qwen, .minimax: return false
        case .claude, .codex, .gemini, .copilot:        return true
        }
    }

    /// Description for settings UI
    var description: String {
        switch self {
        case .claude:
            return "Claude.ai, Claude Code CLI, and API Console"
        case .codex:
            return "OpenAI Codex CLI usage via API"
        case .gemini:
            return "Google Gemini CLI and API usage"
        case .copilot:
            return "GitHub Copilot suggestions and code generation"
        case .kimi:
            return "Moonshot AI Kimi API usage"
        case .deepseek:
            return "DeepSeek API usage"
        case .glm:
            return "Zhipu AI GLM API usage"
        case .qwen:
            return "Alibaba Qwen via DashScope API"
        case .minimax:
            return "MiniMax API usage"
        }
    }

    /// Setup/help URL for the provider
    var setupURL: URL? {
        switch self {
        case .claude:
            return URL(string: "https://claude.ai")
        case .codex:
            return URL(string: "https://platform.openai.com")
        case .gemini:
            return URL(string: "https://aistudio.google.com")
        case .copilot:
            return URL(string: "https://github.com/settings/copilot")
        case .kimi:
            return URL(string: "https://platform.moonshot.cn")
        case .deepseek:
            return URL(string: "https://platform.deepseek.com")
        case .glm:
            return URL(string: "https://open.bigmodel.cn")
        case .qwen:
            return URL(string: "https://dashscope.aliyun.com")
        case .minimax:
            return URL(string: "https://www.minimaxi.com")
        }
    }

    /// API key prefix for masked display
    var apiKeyPrefix: String {
        switch self {
        case .claude: return "sk-ant"
        case .codex: return "sk-"
        case .gemini: return "AIza"
        case .copilot: return "ghp_"
        case .kimi: return "sk-"
        case .deepseek: return "sk-"
        case .glm: return ""
        case .qwen: return "sk-"
        case .minimax: return ""
        }
    }
}

/// Protocol for provider-specific usage data
protocol ProviderUsage: Codable, Equatable {
    static var provider: AIProvider { get }

    /// Tokens or requests used
    var tokensUsed: Int { get }

    /// Limit (if applicable)
    var limit: Int? { get }

    /// Usage percentage (0-100)
    var usagePercentage: Double { get }

    /// When the usage period resets
    var resetTime: Date? { get }

    /// Estimated cost in USD (if available)
    var estimatedCost: Double? { get }

    /// Last updated timestamp
    var lastUpdated: Date { get }

    /// Whether the usage data is valid (not stale/empty)
    var isValid: Bool { get }
}

/// Protocol for provider credentials
protocol ProviderCredentials: Codable {
    static var provider: AIProvider { get }

    /// Whether the credentials are complete enough to fetch usage
    var isValid: Bool { get }

    /// Human-readable status description
    var statusDescription: String { get }
}
