//
//  FeatureGate.swift
//  Claude Usage
//
//  Feature gating system for Pro/Team tier monetization.
//

import Foundation
import Combine

/// Protocol for features that require a specific license tier
protocol FeatureGate {
    var requiredTier: LicenseTier { get }
    func isAvailable(for tier: LicenseTier) -> Bool
}

extension FeatureGate {
    func isAvailable(for tier: LicenseTier) -> Bool {
        return tier.hasAccess(to: requiredTier)
    }
}

/// Concrete feature implementations
struct ProFeature: FeatureGate {
    let requiredTier: LicenseTier = .pro
}

struct TeamFeature: FeatureGate {
    let requiredTier: LicenseTier = .team
}

/// Central registry of all feature flags
@MainActor
final class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    private init() {}

    // MARK: - Pro Features

    /// Unlimited profiles (free is capped at 2)
    let unlimitedProfiles = ProFeature()

    /// Burn rate predictor - time-to-limit estimation
    let burnRatePredictor = ProFeature()

    /// Cost transparency - API-equivalent cost display
    let costTransparency = ProFeature()

    /// Usage history export (JSON/CSV)
    let usageHistoryExport = ProFeature()

    /// Multi-AI tracking (non-Claude providers)
    let multiAI = ProFeature()

    /// Custom notification thresholds (free has fixed 75/90/95)
    let customThresholds = ProFeature()

    /// Advanced icon styles (free has ring only)
    let advancedIconStyles = ProFeature()

    // MARK: - Deferred Features (no UI yet)

    /// Weekly digest — deferred
    let weeklyDigest = ProFeature()

    /// Team tier — all deferred
    let teamDashboard = TeamFeature()
    let budgetAlerts = TeamFeature()
    let adminControls = TeamFeature()
    let aggregateReporting = TeamFeature()
    let sso = TeamFeature()

    // MARK: - Always-Available Features (formerly Pro-gated, now free)

    /// Smart notifications — always contextual (simpler on Free)
    /// Per-session conversation breakdown — always tracked
    /// Cross-profile unified dashboard — always shown (if >1 profile)
    /// Context window tracker — always shown (if using Claude Code)
    /// Predictive throttling — merged into burn rate

    // MARK: - Convenience Checkers

    /// Current effective license tier
    var currentTier: LicenseTier {
        LicenseManager.shared.currentTier
    }

    /// Checks if a feature is available for the current user
    func isAvailable(_ feature: FeatureGate) -> Bool {
        return feature.isAvailable(for: currentTier)
    }

    /// Whether the user is on the free tier
    var isFree: Bool {
        currentTier == .free
    }

    /// Whether the user has Pro or higher
    var isProOrHigher: Bool {
        currentTier.rank >= LicenseTier.pro.rank
    }

    /// Whether the user has Team
    var isTeam: Bool {
        currentTier == .team
    }

    /// Maximum number of profiles allowed for current tier
    var maxProfiles: Int {
        switch currentTier {
        case .free: return 2
        case .pro, .team: return Int.max
        }
    }

    /// Whether profile creation is allowed
    var canCreateProfile: Bool {
        ProfileManager.shared.profiles.count < maxProfiles
    }

    /// Days of history to retain (free = 7, pro = unlimited)
    var historyRetentionDays: Int? {
        switch currentTier {
        case .free: return 7
        case .pro, .team: return nil
        }
    }
}
