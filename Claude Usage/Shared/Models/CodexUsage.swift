//
//  CodexUsage.swift
//  Claude Usage
//
//  Usage model for OpenAI Codex CLI/API.
//

import Foundation

/// Usage data for OpenAI Codex
struct CodexUsage: ProviderUsage {
    static let provider: AIProvider = .codex

    // MARK: - Usage Metrics

    /// Total tokens consumed (input + output)
    var tokensUsed: Int

    /// Token limit for the billing period (if on a plan with limits)
    var limit: Int?

    /// Percentage of limit used
    var usagePercentage: Double

    /// When the current billing period resets
    var resetTime: Date?

    /// Estimated API cost in USD
    var estimatedCost: Double?

    /// Last updated timestamp
    var lastUpdated: Date

    /// Whether the data is valid
    var isValid: Bool { tokensUsed >= 0 }

    // MARK: - Codex-Specific Metrics

    /// Number of CLI sessions
    var sessionsCount: Int?

    /// Number of code completions accepted
    var completionsAccepted: Int?

    /// Number of completions suggested
    var completionsSuggested: Int?

    /// Acceptance rate (0.0 - 1.0)
    var acceptanceRate: Double? {
        guard let accepted = completionsAccepted, let suggested = completionsSuggested, suggested > 0 else {
            return nil
        }
        return Double(accepted) / Double(suggested)
    }

    /// Input tokens consumed
    var inputTokens: Int?

    /// Output tokens consumed
    var outputTokens: Int?

    /// Model used (e.g., "codex-mini", "codex-latest")
    var model: String?

    // MARK: - Init

    init(
        tokensUsed: Int = 0,
        limit: Int? = nil,
        usagePercentage: Double = 0,
        resetTime: Date? = nil,
        estimatedCost: Double? = nil,
        lastUpdated: Date = Date(),
        sessionsCount: Int? = nil,
        completionsAccepted: Int? = nil,
        completionsSuggested: Int? = nil,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil,
        model: String? = nil
    ) {
        self.tokensUsed = tokensUsed
        self.limit = limit
        self.usagePercentage = usagePercentage
        self.resetTime = resetTime
        self.estimatedCost = estimatedCost
        self.lastUpdated = lastUpdated
        self.sessionsCount = sessionsCount
        self.completionsAccepted = completionsAccepted
        self.completionsSuggested = completionsSuggested
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.model = model
    }

    /// Empty usage (placeholder)
    static var empty: CodexUsage {
        CodexUsage()
    }
}

/// Credentials for OpenAI Codex API
struct CodexCredentials: ProviderCredentials {
    static let provider: AIProvider = .codex

    /// OpenAI API key
    var apiKey: String?

    /// Organization ID (optional)
    var organizationId: String?

    var isValid: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    var statusDescription: String {
        isValid ? "Connected" : "API key required"
    }
}
