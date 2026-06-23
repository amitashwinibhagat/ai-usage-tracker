//
//  CostTransparency.swift
//  Claude Usage
//
//  Calculates API-equivalent costs for usage data.
//  Pro feature: "Today's usage would cost $X at API rates"
//

import Foundation

/// API pricing per 1K tokens (as of 2025)
enum APIPricing {
    /// Claude 3.5 Sonnet input
    static let sonnetInputPer1K: Double = 3.0 / 1000.0 // $3 per MTok

    /// Claude 3.5 Sonnet output
    static let sonnetOutputPer1K: Double = 15.0 / 1000.0 // $15 per MTok

    /// Claude 3 Opus input
    static let opusInputPer1K: Double = 15.0 / 1000.0 // $15 per MTok

    /// Claude 3 Opus output
    static let opusOutputPer1K: Double = 75.0 / 1000.0 // $75 per MTok

    /// Claude 3.5 Haiku input
    static let haikuInputPer1K: Double = 0.25 / 1000.0 // $0.25 per MTok

    /// Claude 3.5 Haiku output
    static let haikuOutputPer1K: Double = 1.25 / 1000.0 // $1.25 per MTok

    /// Average output ratio (output tokens / input tokens)
    static let averageOutputRatio = 0.3
}

/// Cost transparency breakdown for a usage session
struct CostBreakdown: Equatable {
    /// Estimated API cost for session tokens
    let sessionCost: Double

    /// Estimated API cost for weekly tokens
    let weeklyCost: Double

    /// Total estimated cost (session + weekly)
    let totalCost: Double

    /// Currency (always USD for API pricing)
    let currency: String = "USD"

    /// Assumed model mix (weighted average cost per token)
    let effectiveCostPer1K: Double

    /// How much the user "saved" vs API pricing (if on Pro/Max subscription)
    let savingsVsAPI: Double?

    /// Formatted total cost
    var formattedTotalCost: String {
        String(format: "$%.2f", totalCost)
    }

    /// Formatted session cost
    var formattedSessionCost: String {
        String(format: "$%.2f", sessionCost)
    }

    /// Formatted weekly cost
    var formattedWeeklyCost: String {
        String(format: "$%.2f", weeklyCost)
    }

    /// Formatted savings
    var formattedSavings: String? {
        guard let savings = savingsVsAPI else { return nil }
        return String(format: "$%.2f", savings)
    }
}

/// Calculates API-equivalent costs for transparency
@MainActor
final class CostTransparency {
    static let shared = CostTransparency()

    /// Assumed blend: 70% Sonnet, 20% Haiku, 10% Opus for weighted pricing
    private var weightedInputCostPer1K: Double {
        (APIPricing.sonnetInputPer1K * 0.70) +
        (APIPricing.haikuInputPer1K * 0.20) +
        (APIPricing.opusInputPer1K * 0.10)
    }

    private var weightedOutputCostPer1K: Double {
        (APIPricing.sonnetOutputPer1K * 0.70) +
        (APIPricing.haikuOutputPer1K * 0.20) +
        (APIPricing.opusOutputPer1K * 0.10)
    }

    /// Effective cost per token considering input/output mix
    private var effectiveCostPerToken: Double {
        let inputWeight = 1.0 / (1.0 + APIPricing.averageOutputRatio)
        let outputWeight = APIPricing.averageOutputRatio / (1.0 + APIPricing.averageOutputRatio)
        let costPer1K = (weightedInputCostPer1K * inputWeight) + (weightedOutputCostPer1K * outputWeight)
        return costPer1K / 1000.0
    }

    private init() {}

    // MARK: - Public API

    /// Calculates cost breakdown for current usage
    func calculate(usage: ClaudeUsage, subscriptionType: String? = nil) -> CostBreakdown? {
        let sessionCost = Double(usage.sessionTokensUsed) * effectiveCostPerToken
        let weeklyCost = Double(usage.weeklyTokensUsed) * effectiveCostPerToken
        let totalCost = sessionCost + weeklyCost

        // Calculate savings vs typical Pro subscription ($20/mo ~ $0.67/day)
        let dailySubscriptionCost: Double? = {
            guard let subType = subscriptionType?.lowercased() else { return nil }
            if subType.contains("pro") || subType.contains("max") {
                return 20.0 / 30.0 // ~$0.67 per day for Pro
            }
            return nil
        }()

        let savings = dailySubscriptionCost.map { max($0 - totalCost, 0) }

        return CostBreakdown(
            sessionCost: sessionCost,
            weeklyCost: weeklyCost,
            totalCost: totalCost,
            effectiveCostPer1K: effectiveCostPerToken * 1000.0,
            savingsVsAPI: savings
        )
    }

    /// Calculates cost for a specific token amount
    func costForTokens(_ tokens: Int) -> Double {
        return Double(tokens) * effectiveCostPerToken
    }

    /// Formatted cost string for a token amount
    func formattedCostForTokens(_ tokens: Int) -> String {
        let cost = costForTokens(tokens)
        if cost < 0.01 {
            return "<$0.01"
        }
        return String(format: "$%.2f", cost)
    }

    /// Returns a comparison string: "Would cost $X on API vs $Y/mo subscription"
    func comparisonString(usage: ClaudeUsage, subscriptionMonthlyCost: Double = 20.0) -> String? {
        guard let breakdown = calculate(usage: usage) else { return nil }
        let dailySub = subscriptionMonthlyCost / 30.0
        return "Today's usage would cost \(breakdown.formattedTotalCost) at API rates vs $\(String(format: "%.2f", dailySub))/day on your subscription."
    }
}
