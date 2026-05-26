//
//  KimiUsage.swift
//  Claude Usage
//
//  Usage model for Moonshot AI Kimi.
//

import Foundation

struct KimiUsage: ProviderUsage {
    static let provider: AIProvider = .kimi

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
    var balance: Double? // CNY balance remaining

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

    static var empty: KimiUsage { KimiUsage() }
}

struct KimiCredentials: ProviderCredentials {
    static let provider: AIProvider = .kimi
    var apiKey: String?
    var isValid: Bool { apiKey != nil && !apiKey!.isEmpty }
    var statusDescription: String { isValid ? "Connected" : "API key required" }
}
