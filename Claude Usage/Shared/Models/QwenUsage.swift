//
//  QwenUsage.swift
//  Claude Usage
//
//  Usage model for Alibaba Qwen via DashScope.
//

import Foundation

struct QwenUsage: ProviderUsage {
    static let provider: AIProvider = .qwen

    var tokensUsed: Int
    var limit: Int?
    var usagePercentage: Double
    var resetTime: Date?
    var estimatedCost: Double?
    var lastUpdated: Date
    var isValid: Bool { tokensUsed >= 0 }

    var model: String?
    var inputTokens: Int?
    var outputTokens: Int?
    var requestsCount: Int?

    init(
        tokensUsed: Int = 0,
        limit: Int? = nil,
        usagePercentage: Double = 0,
        resetTime: Date? = nil,
        estimatedCost: Double? = nil,
        lastUpdated: Date = Date(),
        model: String? = nil,
        inputTokens: Int? = nil,
        outputTokens: Int? = nil,
        requestsCount: Int? = nil
    ) {
        self.tokensUsed = tokensUsed
        self.limit = limit
        self.usagePercentage = usagePercentage
        self.resetTime = resetTime
        self.estimatedCost = estimatedCost
        self.lastUpdated = lastUpdated
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.requestsCount = requestsCount
    }

    static var empty: QwenUsage { QwenUsage() }
}

struct QwenCredentials: ProviderCredentials {
    static let provider: AIProvider = .qwen
    var apiKey: String?
    var isValid: Bool { apiKey != nil && !apiKey!.isEmpty }
    var statusDescription: String { isValid ? "Connected" : "API key required" }
}
