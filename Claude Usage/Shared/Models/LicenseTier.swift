//
//  LicenseTier.swift
//  Claude Usage
//
//  License tier definitions for feature gating.
//

import Foundation

/// Represents the subscription tier of the user
enum LicenseTier: String, Codable, CaseIterable {
    case free
    case pro
    case team

    /// Rank for comparison (higher = more access)
    var rank: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .team: return 2
        }
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .team: return "Team"
        }
    }

    /// Whether this tier has access to the given required tier
    func hasAccess(to required: LicenseTier) -> Bool {
        return self.rank >= required.rank
    }
}
