//
//  GeminiUsage.swift
//  Claude Usage
//
//  Usage model for Google Gemini CLI/API.
//

import Foundation

/// Usage data for Google Gemini
struct GeminiUsage: ProviderUsage {
    static let provider: AIProvider = .gemini

    // MARK: - Usage Metrics

    /// Total tokens consumed
    var tokensUsed: Int

    /// Token limit for the billing period
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

    // MARK: - Gemini-Specific Metrics

    /// Number of requests made
    var requestsCount: Int?

    /// Input tokens
    var inputTokens: Int?

    /// Output tokens
    var outputTokens: Int?

    /// Model used (e.g., "gemini-2.5-pro", "gemini-2.5-flash")
    var model: String?

    /// Free tier quota remaining (Gemini has generous free tier)
    var freeTierRemaining: Int?

    /// Whether currently on free tier
    var isFreeTier: Bool?

    // MARK: - Init

    init(
        tokensUsed: Int = 0,
        limit: Int? = nil,
        usagePercentage: Double = 0,
        resetTime: Date? = nil,
        estimatedCost: Double? = nil,
        lastUpdated: Date = Date(),
        requestsCount: Int? = nil,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil,
        model: String? = nil,
        freeTierRemaining: Int? = nil,
        isFreeTier: Bool? = nil
    ) {
        self.tokensUsed = tokensUsed
        self.limit = limit
        self.usagePercentage = usagePercentage
        self.resetTime = resetTime
        self.estimatedCost = estimatedCost
        self.lastUpdated = lastUpdated
        self.requestsCount = requestsCount
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.model = model
        self.freeTierRemaining = freeTierRemaining
        self.isFreeTier = isFreeTier
    }

    /// Empty usage (placeholder)
    static var empty: GeminiUsage {
        GeminiUsage()
    }
}

/// Credentials for Google Gemini API
struct GeminiCredentials: ProviderCredentials {
    static let provider: AIProvider = .gemini

    /// Google AI Studio API key
    var apiKey: String?

    /// Project ID (for GCP-based usage)
    var projectId: String?

    var isValid: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    var statusDescription: String {
        isValid ? "Connected" : "API key required"
    }
}
