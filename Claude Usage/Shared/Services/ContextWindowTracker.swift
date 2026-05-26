//
//  ContextWindowTracker.swift
//  Claude Usage
//
//  Tracks Claude Code context window usage (200K tokens).
//

import Foundation

/// Context window usage for a Claude Code session
struct ContextWindowUsage: Codable, Equatable {
    /// Current context window size (tokens)
    var currentTokens: Int

    /// Maximum context window size (200K for Claude 3.5 Sonnet)
    let maxTokens: Int = 200_000

    /// Percentage of context window used
    var usagePercentage: Double {
        (Double(currentTokens) / Double(maxTokens)) * 100.0
    }

    /// Remaining tokens in context window
    var remainingTokens: Int {
        max(0, maxTokens - currentTokens)
    }

    /// Whether context compaction is likely happening soon
    var isNearCompaction: Bool {
        usagePercentage >= 85
    }

    /// Whether context window is critically full
    var isCritical: Bool {
        usagePercentage >= 95
    }

    /// Number of files in context
    var fileCount: Int?

    /// Last updated
    var lastUpdated: Date
}

/// Service for tracking Claude Code context window
@MainActor
final class ContextWindowTracker {
    static let shared = ContextWindowTracker()

    private init() {}

    // MARK: - Public API

    /// Estimates context window usage from session tokens
    /// NOTE: This is an approximation. Real context window data would need
    /// integration with Claude Code's /status or /context command output.
    func estimateContextWindow(sessionTokens: Int) -> ContextWindowUsage {
        guard FeatureFlags.shared.isAvailable(FeatureFlags.shared.contextWindowTracker) else {
            return ContextWindowUsage(currentTokens: 0, fileCount: nil, lastUpdated: Date())
        }

        // Rough estimate: session tokens are roughly proportional to context window
        // In reality, context window includes conversation history + file contents
        let estimatedContext = min(sessionTokens, 200_000)

        return ContextWindowUsage(
            currentTokens: estimatedContext,
            fileCount: nil,
            lastUpdated: Date()
        )
    }

    /// Returns a human-readable warning if context is getting full
    func contextWarning(usage: ContextWindowUsage) -> String? {
        guard FeatureFlags.shared.isAvailable(FeatureFlags.shared.contextWindowTracker) else { return nil }

        if usage.isCritical {
            return "⚠️ Context window >95% full. Compaction imminent — save important context."
        } else if usage.isNearCompaction {
            return "Context window at \(Int(usage.usagePercentage))%. Consider starting a new session soon."
        }
        return nil
    }
}
