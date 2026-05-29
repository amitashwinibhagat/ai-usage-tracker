//
//  ConversationBreakdown.swift
//  Claude Usage
//
//  Models for per-session conversation-level token tracking.
//

import Foundation

/// Represents a single conversation's token usage within a session
struct ConversationUsage: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var tokensUsed: Int
    var timestamp: Date
    var model: String? // e.g., "claude-sonnet-4-5", "claude-opus-4"

    /// Percentage of session limit this conversation consumed
    var percentageOfSession: Double

    /// Whether this was a high-cost conversation (>20% of session)
    var isHighCost: Bool { percentageOfSession >= 20 }
}

/// Tracks all conversations within the current session
struct SessionConversationBreakdown: Codable, Equatable {
    var profileId: UUID
    var sessionStartTime: Date
    var sessionResetTime: Date
    var conversations: [ConversationUsage]

    /// Total tokens across all tracked conversations
    var totalTokens: Int {
        conversations.reduce(0) { $0 + $1.tokensUsed }
    }

    /// Most expensive conversation
    var mostExpensiveConversation: ConversationUsage? {
        conversations.max(by: { $0.tokensUsed < $1.tokensUsed })
    }

    /// Conversations sorted by cost (most expensive first)
    var sortedByCost: [ConversationUsage] {
        conversations.sorted(by: { $0.tokensUsed > $1.tokensUsed })
    }

    /// High-cost conversations (>20% of session)
    var highCostConversations: [ConversationUsage] {
        conversations.filter { $0.isHighCost }
    }

    mutating func addConversation(_ conversation: ConversationUsage) {
        conversations.append(conversation)
    }

    /// Clears breakdown when session resets
    mutating func clearForNewSession(sessionResetTime: Date) {
        conversations = []
        self.sessionResetTime = sessionResetTime
        self.sessionStartTime = Date()
    }
}

/// Service that estimates conversation-level usage from session deltas
@MainActor
final class ConversationBreakdownService {
    static let shared = ConversationBreakdownService()

    private let defaults = UserDefaults.standard
    private var lastKnownSessionTokens: [UUID: Int] = [:]
    private var currentBreakdowns: [UUID: SessionConversationBreakdown] = [:]

    private init() {
        loadBreakdowns()
    }

    // MARK: - Public API

    /// Records a usage check and estimates conversation tokens from delta
    func recordUsageCheck(profileId: UUID, currentUsage: ClaudeUsage) {
        let lastTokens = lastKnownSessionTokens[profileId] ?? 0
        let delta = max(currentUsage.sessionTokensUsed - lastTokens, 0)

        // If session reset happened, clear the breakdown
        if let breakdown = currentBreakdowns[profileId],
           currentUsage.sessionResetTime != breakdown.sessionResetTime {
            var newBreakdown = breakdown
            newBreakdown.clearForNewSession(sessionResetTime: currentUsage.sessionResetTime)
            currentBreakdowns[profileId] = newBreakdown
        }

        // If there's a significant delta, attribute it to a "conversation"
        if delta > 100 {
            var breakdown = currentBreakdowns[profileId] ?? SessionConversationBreakdown(
                profileId: profileId,
                sessionStartTime: Date(),
                sessionResetTime: currentUsage.sessionResetTime,
                conversations: []
            )

            let sessionLimit = max(currentUsage.sessionLimit, 1)
            let percentage = (Double(delta) / Double(sessionLimit)) * 100.0

            let conversation = ConversationUsage(
                id: UUID(),
                title: generateConversationTitle(for: delta),
                tokensUsed: delta,
                timestamp: Date(),
                model: nil, // Could be enhanced with model detection
                percentageOfSession: percentage
            )

            breakdown.addConversation(conversation)
            currentBreakdowns[profileId] = breakdown
            saveBreakdowns()
        }

        lastKnownSessionTokens[profileId] = currentUsage.sessionTokensUsed
    }

    /// Gets the conversation breakdown for a profile
    func getBreakdown(for profileId: UUID) -> SessionConversationBreakdown? {
        return currentBreakdowns[profileId]
    }

    /// Clears breakdown for a profile
    func clearBreakdown(for profileId: UUID) {
        currentBreakdowns.removeValue(forKey: profileId)
        saveBreakdowns()
    }

    // MARK: - Private

    private func generateConversationTitle(for tokens: Int) -> String {
        if tokens > 50000 {
            return "Large context operation"
        } else if tokens > 20000 {
            return "Extended conversation"
        } else if tokens > 5000 {
            return "Medium conversation"
        } else {
            return "Quick interaction"
        }
    }

    private func saveBreakdowns() {
        if let data = try? JSONEncoder().encode(currentBreakdowns) {
            defaults.set(data, forKey: "conversationBreakdowns")
        }
    }

    private func loadBreakdowns() {
        guard let data = defaults.data(forKey: "conversationBreakdowns"),
              let decoded = try? JSONDecoder().decode([UUID: SessionConversationBreakdown].self, from: data) else {
            return
        }
        currentBreakdowns = decoded
    }
}
