//
//  GLMUsage.swift
//  Claude Usage
//
//  Usage model for Zhipu AI GLM.
//

import Foundation

struct GLMUsage: ProviderUsage {
    static let provider: AIProvider = .glm

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
    var balance: Double? // CNY balance

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
        balance: Double? = nil
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
        self.balance = balance
    }

    static var empty: GLMUsage { GLMUsage() }
}

struct GLMCredentials: ProviderCredentials {
    static let provider: AIProvider = .glm
    var apiKey: String?
    var isValid: Bool { apiKey != nil && !apiKey!.isEmpty }
    var statusDescription: String { isValid ? "Connected" : "API key required" }
}
