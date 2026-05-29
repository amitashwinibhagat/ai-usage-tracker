//
//  PredictiveThrottlingService.swift
//  Claude Usage
//
//  Proactively predicts when user will hit limits based on historical patterns.
//

import Foundation

/// Prediction result for throttling alerts
struct ThrottlingPrediction: Equatable {
    /// Day of week (1=Sunday, 7=Saturday)
    let dayOfWeek: Int

    /// Predicted session percentage by end of day
    let predictedSessionPercentage: Double

    /// Predicted weekly percentage by end of day
    let predictedWeeklyPercentage: Double

    /// Whether user is on track to hit session limit today
    let willHitSessionLimit: Bool

    /// Whether user is on track to hit weekly limit by end of week
    let willHitWeeklyLimit: Bool

    /// Human-readable advice
    let advice: String
}

/// Analyzes historical usage patterns to predict future limit hits
@MainActor
final class PredictiveThrottlingService {
    static let shared = PredictiveThrottlingService()

    /// Minimum days of history needed for reliable prediction
    private let minimumHistoryDays = 3

    private init() {}

    // MARK: - Public API

    /// Generates a predictive throttling alert based on historical patterns
    func predict(for profileId: UUID, currentUsage: ClaudeUsage) -> ThrottlingPrediction? {
        let history = UsageHistoryService.shared.loadHistory(for: profileId)
        let sessionSnapshots = history.sessionSnapshots

        guard sessionSnapshots.count >= minimumHistoryDays else {
            return nil // Not enough history
        }

        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())

        // Calculate average daily burn rate from history
        let dailyBurnRate = calculateDailyBurnRate(from: sessionSnapshots)

        // Predict end-of-day usage
        let elapsedToday = calendar.component(.hour, from: Date())
        let remainingHours = max(24 - elapsedToday, 1)
        let predictedAdditionalBurn = dailyBurnRate * (Double(remainingHours) / 24.0)

        let predictedSessionPct = min(currentUsage.effectiveSessionPercentage + predictedAdditionalBurn, 100)

        // Predict weekly usage
        let daysUntilReset = daysUntilWeeklyReset(from: currentUsage.weeklyResetTime)
        let predictedWeeklyPct = min(currentUsage.weeklyPercentage + (dailyBurnRate * Double(daysUntilReset)), 100)

        let willHitSession = predictedSessionPct >= 95
        let willHitWeekly = predictedWeeklyPct >= 95

        let advice = generateAdvice(
            willHitSession: willHitSession,
            willHitWeekly: willHitWeekly,
            predictedSessionPct: predictedSessionPct,
            predictedWeeklyPct: predictedWeeklyPct,
            daysUntilReset: daysUntilReset
        )

        return ThrottlingPrediction(
            dayOfWeek: today,
            predictedSessionPercentage: predictedSessionPct,
            predictedWeeklyPercentage: predictedWeeklyPct,
            willHitSessionLimit: willHitSession,
            willHitWeeklyLimit: willHitWeekly,
            advice: advice
        )
    }

    /// Checks if user typically burns most of their limit by a certain day
    func typicalBurnPattern(for profileId: UUID) -> String? {
        let history = UsageHistoryService.shared.loadHistory(for: profileId)
        let weeklySnapshots = history.weeklySnapshots

        guard weeklySnapshots.count >= 7 else { return nil }

        let calendar = Calendar.current
        var dayOfWeekBurn: [Int: [Double]] = [:]

        for snapshot in weeklySnapshots {
            let dow = calendar.component(.weekday, from: snapshot.timestamp)
            if let pct = snapshot.weeklyPercentage {
                dayOfWeekBurn[dow, default: []].append(pct)
            }
        }

        // Find day when user typically hits 80%
        for day in 1...7 {
            if let burns = dayOfWeekBurn[day],
               let avg = burns.isEmpty ? nil : burns.reduce(0, +) / Double(burns.count),
               avg >= 80 {
                let dayName = dayName(day)
                return "You typically hit 80% of your weekly limit by \(dayName)."
            }
        }

        return nil
    }

    // MARK: - Private

    private func calculateDailyBurnRate(from snapshots: [UsageSnapshot]) -> Double {
        guard snapshots.count >= 2 else { return 0 }

        // Group by day and calculate average session percentage increase per day
        let calendar = Calendar.current
        var dailyTotals: [Date: Double] = [:]

        for snapshot in snapshots {
            let day = calendar.startOfDay(for: snapshot.timestamp)
            if let pct = snapshot.sessionPercentage {
                dailyTotals[day, default: 0] = max(dailyTotals[day, default: 0], pct)
            }
        }

        let sortedDays = dailyTotals.keys.sorted()
        guard sortedDays.count >= 2 else { return 0 }

        var totalBurn: Double = 0
        for i in 1..<sortedDays.count {
            let prevPct = dailyTotals[sortedDays[i-1]] ?? 0
            let currPct = dailyTotals[sortedDays[i]] ?? 0
            let dayBurn = max(currPct - prevPct, 0)
            totalBurn += dayBurn
        }

        return totalBurn / Double(sortedDays.count - 1)
    }

    private func daysUntilWeeklyReset(from resetTime: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: resetTime)
        return max(components.day ?? 0, 0)
    }

    private func generateAdvice(
        willHitSession: Bool,
        willHitWeekly: Bool,
        predictedSessionPct: Double,
        predictedWeeklyPct: Double,
        daysUntilReset: Int
    ) -> String {
        if willHitSession && willHitWeekly {
            return "You're on track to hit BOTH limits today. Consider switching to API billing or taking a break."
        } else if willHitSession {
            return "Session limit approaching today (\(Int(predictedSessionPct))%). Start a new session before you hit the wall."
        } else if willHitWeekly {
            return "Weekly limit at risk (\(Int(predictedWeeklyPct))% by reset in \(daysUntilReset) days). Pace yourself."
        } else if predictedWeeklyPct >= 70 {
            return "On track this week (\(Int(predictedWeeklyPct))%). Monitor usage if you have heavy days ahead."
        }
        return "Usage pacing looks healthy. No immediate concerns."
    }

    private func dayName(_ day: Int) -> String {
        let formatter = DateFormatter()
        guard let symbols = formatter.weekdaySymbols,
              day > 0, day <= symbols.count else { return "Unknown" }
        return symbols[day - 1]
    }
}
