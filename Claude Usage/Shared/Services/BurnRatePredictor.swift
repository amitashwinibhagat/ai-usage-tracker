//
//  BurnRatePredictor.swift
//  Claude Usage
//
//  Calculates token burn rate and time-to-limit predictions.
//  Pro feature: "At your current pace, you'll hit 100% in X minutes"
//

import Foundation

/// Burn rate prediction result
struct BurnRatePrediction: Equatable {
    /// Tokens consumed per minute
    let tokensPerMinute: Double

    /// Estimated minutes until session limit is reached
    let minutesToLimit: Double?

    /// Estimated minutes until weekly limit is reached
    let weeklyMinutesToLimit: Double?

    /// Trend direction compared to expected pace
    let trend: BurnTrend

    /// Human-readable time-to-limit string
    let timeToLimitText: String

    /// Whether the prediction is reliable (has enough data)
    let isReliable: Bool
}

enum BurnTrend: String, Equatable {
    case accelerating = "accelerating"
    case steady = "steady"
    case decelerating = "decelerating"
    case unknown = "unknown"

    var icon: String {
        switch self {
        case .accelerating: return "arrow.up.forward"
        case .steady: return "arrow.forward"
        case .decelerating: return "arrow.down.forward"
        case .unknown: return "questionmark"
        }
    }

    var description: String {
        switch self {
        case .accelerating: return "Burning faster than expected"
        case .steady: return "On pace with expected usage"
        case .decelerating: return "Burning slower than expected"
        case .unknown: return "Not enough data yet"
        }
    }
}

/// Predicts when user will hit usage limits based on recent burn rate
@MainActor
final class BurnRatePredictor {
    static let shared = BurnRatePredictor()

    /// Minimum snapshots needed for reliable prediction
    private let minimumSnapshots = 3

    /// Time window to analyze for burn rate (last 30 minutes)
    private let analysisWindow: TimeInterval = 30 * 60

    private init() {}

    // MARK: - Public API

    /// Calculates burn rate prediction for a profile's current session
    func predict(for profileId: UUID, currentUsage: ClaudeUsage) -> BurnRatePrediction {
        let history = UsageHistoryService.shared.getSessionSnapshots(for: profileId)
        let recentSnapshots = history.filter {
            $0.timestamp > Date().addingTimeInterval(-analysisWindow)
        }

        guard recentSnapshots.count >= minimumSnapshots else {
            return unreliablePrediction()
        }

        // Calculate session burn rate
        let sessionPrediction = calculatePrediction(
            snapshots: recentSnapshots,
            currentTokens: currentUsage.sessionTokensUsed,
            limit: currentUsage.sessionLimit,
            resetTime: currentUsage.sessionResetTime
        )

        // Calculate weekly burn rate (using weekly snapshots)
        let weeklyHistory = UsageHistoryService.shared.getWeeklySnapshots(for: profileId)
        let weeklyPrediction = calculateWeeklyPrediction(
            snapshots: weeklyHistory,
            currentTokens: currentUsage.weeklyTokensUsed,
            limit: currentUsage.weeklyLimit
        )

        return BurnRatePrediction(
            tokensPerMinute: sessionPrediction.tokensPerMinute,
            minutesToLimit: sessionPrediction.minutesToLimit,
            weeklyMinutesToLimit: weeklyPrediction.minutesToLimit,
            trend: sessionPrediction.trend,
            timeToLimitText: formatTimeToLimit(sessionPrediction.minutesToLimit),
            isReliable: true
        )
    }

    /// Quick prediction using just current usage and elapsed time
    func quickPredict(currentUsage: ClaudeUsage) -> BurnRatePrediction {
        let resetTime = currentUsage.sessionResetTime
        let elapsed = resetTime.timeIntervalSince(Date())
        let sessionDuration: TimeInterval = 5 * 60 * 60 // 5 hour window
        let elapsedFraction = 1.0 - (elapsed / sessionDuration)

        guard elapsedFraction > 0.05 else {
            // Too early in session
            return BurnRatePrediction(
                tokensPerMinute: 0,
                minutesToLimit: nil,
                weeklyMinutesToLimit: nil,
                trend: .unknown,
                timeToLimitText: "Check back in a few minutes",
                isReliable: false
            )
        }

        let expectedUsage = elapsedFraction * 100.0
        let actualUsage = currentUsage.effectiveSessionPercentage
        let remainingPercentage = 100.0 - actualUsage

        // Simple linear extrapolation
        let rate = actualUsage / max(elapsedFraction * sessionDuration / 60.0, 1.0)
        let minutesToLimit = remainingPercentage > 0.5 ? (remainingPercentage / max(rate, 0.01)) : 0

        let trend: BurnTrend = {
            let diff = actualUsage - expectedUsage
            if diff > 15 { return .accelerating }
            if diff < -15 { return .decelerating }
            return .steady
        }()

        return BurnRatePrediction(
            tokensPerMinute: Double(currentUsage.sessionTokensUsed) / max(elapsedFraction * sessionDuration / 60.0, 1.0),
            minutesToLimit: minutesToLimit,
            weeklyMinutesToLimit: nil,
            trend: trend,
            timeToLimitText: formatTimeToLimit(minutesToLimit),
            isReliable: elapsedFraction > 0.1
        )
    }

    // MARK: - Private

    private func calculatePrediction(
        snapshots: [UsageSnapshot],
        currentTokens: Int,
        limit: Int,
        resetTime: Date?
    ) -> (tokensPerMinute: Double, minutesToLimit: Double?, trend: BurnTrend) {
        guard snapshots.count >= 2,
              let oldest = snapshots.last,
              let newest = snapshots.first,
              let oldestTokens = oldest.sessionTokensUsed,
              let newestTokens = newest.sessionTokensUsed else {
            return (0, nil, .unknown)
        }

        let timeDelta = newest.timestamp.timeIntervalSince(oldest.timestamp)
        let tokenDelta = Double(newestTokens - oldestTokens)

        guard timeDelta > 60 else { return (0, nil, .unknown) }

        let tokensPerMinute = tokenDelta / (timeDelta / 60.0)
        let remainingTokens = max(Double(limit - currentTokens), 0)

        let minutesToLimit: Double? = tokensPerMinute > 0.5 ? remainingTokens / tokensPerMinute : nil

        // Determine trend by comparing to expected linear usage
        let trend: BurnTrend = {
            guard let reset = resetTime else { return .unknown }
            let elapsed = reset.timeIntervalSince(Date())
            let sessionDuration: TimeInterval = 5 * 60 * 60
            let elapsedFraction = 1.0 - (elapsed / sessionDuration)
            let expectedPercentage = elapsedFraction * 100.0
            let actualPercentage = (Double(currentTokens) / Double(max(limit, 1))) * 100.0
            let diff = actualPercentage - expectedPercentage

            if diff > 15 { return .accelerating }
            if diff < -15 { return .decelerating }
            return .steady
        }()

        return (tokensPerMinute, minutesToLimit, trend)
    }

    private func calculateWeeklyPrediction(
        snapshots: [UsageSnapshot],
        currentTokens: Int,
        limit: Int
    ) -> (tokensPerMinute: Double, minutesToLimit: Double?) {
        guard snapshots.count >= 2,
              let oldest = snapshots.last,
              let newest = snapshots.first,
              let oldestTokens = oldest.weeklyTokensUsed,
              let newestTokens = newest.weeklyTokensUsed else {
            return (0, nil)
        }

        let timeDelta = newest.timestamp.timeIntervalSince(oldest.timestamp)
        let tokenDelta = Double(newestTokens - oldestTokens)

        guard timeDelta > 300 else { return (0, nil) }

        let tokensPerMinute = tokenDelta / (timeDelta / 60.0)
        let remainingTokens = max(Double(limit - currentTokens), 0)

        let minutesToLimit = tokensPerMinute > 0.1 ? remainingTokens / tokensPerMinute : nil
        return (tokensPerMinute, minutesToLimit)
    }

    private func formatTimeToLimit(_ minutes: Double?) -> String {
        guard let minutes = minutes else { return "Calculating..." }
        if minutes <= 0 { return "Limit reached soon" }
        if minutes < 1 { return "Less than a minute" }
        if minutes < 60 {
            return "\(Int(minutes)) min"
        }
        let hours = minutes / 60.0
        if hours < 24 {
            return String(format: "%.1f hours", hours)
        }
        return String(format: "%.1f days", hours / 24.0)
    }

    private func unreliablePrediction() -> BurnRatePrediction {
        BurnRatePrediction(
            tokensPerMinute: 0,
            minutesToLimit: nil,
            weeklyMinutesToLimit: nil,
            trend: .unknown,
            timeToLimitText: "Not enough data yet",
            isReliable: false
        )
    }
}
