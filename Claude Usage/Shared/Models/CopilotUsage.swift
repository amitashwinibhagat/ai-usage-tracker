//
//  CopilotUsage.swift
//  Claude Usage
//
//  Usage model for GitHub Copilot.
//

import Foundation

/// Usage data for GitHub Copilot
struct CopilotUsage: ProviderUsage {
    static let provider: AIProvider = .copilot

    // MARK: - Usage Metrics

    /// Total suggestions/requests (Copilot doesn't use tokens directly)
    var tokensUsed: Int

    /// Limit (usually nil for Copilot as it's subscription-based)
    var limit: Int?

    /// Percentage of any quota used
    var usagePercentage: Double

    /// When the current billing period resets
    var resetTime: Date?

    /// Monthly subscription cost (fixed)
    var estimatedCost: Double?

    /// Last updated timestamp
    var lastUpdated: Date

    /// Whether the data is valid
    var isValid: Bool { tokensUsed >= 0 }

    // MARK: - Copilot-Specific Metrics

    /// Number of suggestions accepted
    var suggestionsAccepted: Int?

    /// Number of suggestions shown
    var suggestionsShown: Int?

    /// Acceptance rate (0.0 - 1.0)
    var acceptanceRate: Double? {
        guard let accepted = suggestionsAccepted, let shown = suggestionsShown, shown > 0 else {
            return nil
        }
        return Double(accepted) / Double(shown)
    }

    /// Lines of code generated
    var linesGenerated: Int?

    /// Number of active users (for team plans)
    var activeUsers: Int?

    /// Seat count (for team/enterprise plans)
    var seatCount: Int?

    /// Plan type
    var planType: CopilotPlanType?

    // MARK: - Init

    init(
        tokensUsed: Int = 0,
        limit: Int? = nil,
        usagePercentage: Double = 0,
        resetTime: Date? = nil,
        estimatedCost: Double? = nil,
        lastUpdated: Date = Date(),
        suggestionsAccepted: Int? = nil,
        suggestionsShown: Int? = nil,
        linesGenerated: Int? = nil,
        activeUsers: Int? = nil,
        seatCount: Int? = nil,
        planType: CopilotPlanType? = nil
    ) {
        self.tokensUsed = tokensUsed
        self.limit = limit
        self.usagePercentage = usagePercentage
        self.resetTime = resetTime
        self.estimatedCost = estimatedCost
        self.lastUpdated = lastUpdated
        self.suggestionsAccepted = suggestionsAccepted
        self.suggestionsShown = suggestionsShown
        self.linesGenerated = linesGenerated
        self.activeUsers = activeUsers
        self.seatCount = seatCount
        self.planType = planType
    }

    /// Empty usage (placeholder)
    static var empty: CopilotUsage {
        CopilotUsage()
    }
}

/// Copilot subscription plan type
enum CopilotPlanType: String, Codable {
    case individual = "individual"
    case business = "business"
    case enterprise = "enterprise"
    case free = "free"

    var displayName: String {
        switch self {
        case .individual: return "Individual"
        case .business: return "Business"
        case .enterprise: return "Enterprise"
        case .free: return "Free"
        }
    }

    var monthlyCost: Double {
        switch self {
        case .individual: return 10.0
        case .business: return 19.0
        case .enterprise: return 39.0
        case .free: return 0.0
        }
    }
}

/// Credentials for GitHub Copilot
struct CopilotCredentials: ProviderCredentials {
    static let provider: AIProvider = .copilot

    /// GitHub personal access token
    var accessToken: String?

    /// GitHub username
    var username: String?

    var isValid: Bool {
        accessToken != nil && !accessToken!.isEmpty
    }

    var statusDescription: String {
        isValid ? "Connected" : "GitHub token required"
    }
}
