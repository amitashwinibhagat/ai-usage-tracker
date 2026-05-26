//
//  SmartNotificationGenerator.swift
//  Claude Usage
//
//  Generates contextual, actionable notification messages.
//  Pro feature: Notifications with specific advice based on usage pattern.
//

import Foundation

/// A smart notification with contextual advice
struct SmartNotification: Equatable {
    let title: String
    let body: String
    let actionLabel: String?
    let actionURL: URL?
    let priority: SmartNotificationPriority
    let category: SmartNotificationCategory
}

enum SmartNotificationPriority: String, Equatable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum SmartNotificationCategory: String, Equatable {
    case threshold = "threshold"
    case burnRate = "burn_rate"
    case sessionPlanning = "session_planning"
    case weeklyLimit = "weekly_limit"
    case costAlert = "cost_alert"
}

/// Generates contextual notifications with actionable advice
@MainActor
final class SmartNotificationGenerator {
    static let shared = SmartNotificationGenerator()

    private init() {}

    // MARK: - Public API

    /// Generates a smart threshold notification with contextual advice
    func thresholdNotification(
        percentage: Double,
        resetTime: Date?,
        profileName: String,
        usage: ClaudeUsage
    ) -> SmartNotification {
        // Gate: Pro feature
        guard FeatureFlags.shared.isAvailable(FeatureFlags.shared.smartNotifications) else {
            return basicThresholdNotification(percentage: percentage, resetTime: resetTime, profileName: profileName)
        }

        let context = buildContext(percentage: percentage, resetTime: resetTime, usage: usage)

        if percentage >= 95 {
            return criticalNotification(context: context, profileName: profileName)
        } else if percentage >= 90 {
            return warningNotification(context: context, profileName: profileName)
        } else if percentage >= 75 {
            return infoNotification(context: context, profileName: profileName)
        }

        return basicThresholdNotification(percentage: percentage, resetTime: resetTime, profileName: profileName)
    }

    /// Generates a burn rate alert notification
    func burnRateNotification(prediction: BurnRatePrediction, profileName: String) -> SmartNotification? {
        guard FeatureFlags.shared.isAvailable(FeatureFlags.shared.smartNotifications),
              FeatureFlags.shared.isAvailable(FeatureFlags.shared.burnRatePredictor),
              prediction.isReliable,
              let minutes = prediction.minutesToLimit,
              minutes < 30 else {
            return nil
        }

        let body: String
        let actionLabel: String?

        switch prediction.trend {
        case .accelerating:
            body = "\(profileName): At this accelerating pace, you'll hit your limit in \(Int(minutes)) minutes. Consider switching to a lighter model or starting a new session."
            actionLabel = "Open Guide"
        case .steady:
            body = "\(profileName): You'll reach your session limit in approximately \(Int(minutes)) minutes at the current pace."
            actionLabel = nil
        case .decelerating:
            body = "\(profileName): Usage has slowed. You'll hit the limit in \(Int(minutes)) minutes if pace picks back up."
            actionLabel = nil
        case .unknown:
            return nil
        }

        return SmartNotification(
            title: "⏱️ Limit Approaching Soon",
            body: body,
            actionLabel: actionLabel,
            actionURL: URL(string: "https://docs.anthropic.com/en/docs/build-with-claude/token-counting"),
            priority: minutes < 10 ? .critical : .high,
            category: .burnRate
        )
    }

    /// Generates a weekly limit approaching notification
    func weeklyLimitNotification(usage: ClaudeUsage, profileName: String) -> SmartNotification? {
        guard FeatureFlags.shared.isAvailable(FeatureFlags.shared.smartNotifications),
              usage.weeklyPercentage >= 80 else {
            return nil
        }

        let advice: String
        if usage.weeklyPercentage >= 95 {
            advice = "You've used \(Int(usage.weeklyPercentage))% of your weekly limit. Consider using Claude Code with local tools or taking a break until Monday reset."
        } else if usage.weeklyPercentage >= 90 {
            advice = "Weekly usage at \(Int(usage.weeklyPercentage))%. Pace yourself — you have \(Int(100 - usage.weeklyPercentage))% remaining for the rest of the week."
        } else {
            advice = "You've used \(Int(usage.weeklyPercentage))% of your weekly limit. You're on track, but monitor usage if you have heavy days ahead."
        }

        return SmartNotification(
            title: "📊 Weekly Limit: \(Int(usage.weeklyPercentage))%",
            body: "\(profileName): \(advice)",
            actionLabel: nil,
            actionURL: nil,
            priority: usage.weeklyPercentage >= 90 ? .high : .medium,
            category: .weeklyLimit
        )
    }

    // MARK: - Private

    private struct NotificationContext {
        let percentage: Double
        let minutesToReset: Int?
        let isPeakHours: Bool
        let hasHighWeeklyUsage: Bool
        let isFirstAlertOfSession: Bool
    }

    private func buildContext(percentage: Double, resetTime: Date?, usage: ClaudeUsage) -> NotificationContext {
        let minutesToReset = resetTime.map { max(Int($0.timeIntervalSince(Date()) / 60), 0) }
        let isPeakHours = PeakHoursService.shared.isPeakHours
        let hasHighWeeklyUsage = usage.weeklyPercentage > 70

        // For simplicity, assume first alert if percentage just crossed threshold
        let isFirstAlert = Int(percentage) % 5 == 0

        return NotificationContext(
            percentage: percentage,
            minutesToReset: minutesToReset,
            isPeakHours: isPeakHours,
            hasHighWeeklyUsage: hasHighWeeklyUsage,
            isFirstAlertOfSession: isFirstAlert
        )
    }

    private func criticalNotification(context: NotificationContext, profileName: String) -> SmartNotification {
        let body: String
        let actionLabel: String?

        if let minutes = context.minutesToReset, minutes < 30 {
            body = "\(profileName): Critical — \(Int(context.percentage))% used with only \(minutes) min remaining. Start a new session now or switch to API billing to avoid interruption."
            actionLabel = "Learn More"
        } else if context.hasHighWeeklyUsage {
            body = "\(profileName): Session at \(Int(context.percentage))% AND weekly usage is high. Consider using Claude Code CLI for better efficiency."
            actionLabel = nil
        } else {
            body = "\(profileName): You've used \(Int(context.percentage))% of your session limit. Wrap up current work soon to avoid hitting the wall."
            actionLabel = nil
        }

        return SmartNotification(
            title: "🚨 Session Critical: \(Int(context.percentage))%",
            body: body,
            actionLabel: actionLabel,
            actionURL: actionLabel != nil ? URL(string: "https://docs.anthropic.com/en/docs/build-with-claude/token-counting") : nil,
            priority: .critical,
            category: .threshold
        )
    }

    private func warningNotification(context: NotificationContext, profileName: String) -> SmartNotification {
        let body: String

        if context.isPeakHours {
            body = "\(profileName): \(Int(context.percentage))% used during peak hours. Response times may slow as you approach the limit. Consider spacing out requests."
        } else if context.hasHighWeeklyUsage {
            body = "\(profileName): \(Int(context.percentage))% session + high weekly usage. Switch to a profile with more headroom or use the API Console for heavy tasks."
        } else {
            body = "\(profileName): You've used \(Int(context.percentage))% of your session limit. You have comfortable headroom, but plan your remaining work accordingly."
        }

        return SmartNotification(
            title: "⚠️ Session Warning: \(Int(context.percentage))%",
            body: body,
            actionLabel: nil,
            actionURL: nil,
            priority: .high,
            category: .threshold
        )
    }

    private func infoNotification(context: NotificationContext, profileName: String) -> SmartNotification {
        let body = "\(profileName): You've used \(Int(context.percentage))% of your session limit. You're pacing well — no immediate action needed."

        return SmartNotification(
            title: "ℹ️ Usage Update: \(Int(context.percentage))%",
            body: body,
            actionLabel: nil,
            actionURL: nil,
            priority: .medium,
            category: .threshold
        )
    }

    private func basicThresholdNotification(percentage: Double, resetTime: Date?, profileName: String) -> SmartNotification {
        let percentStr = String(format: "%.1f%%", percentage)
        let resetStr = resetTime.map { "Resets \(FormatterHelper.timeUntilReset(from: $0))" } ?? ""

        return SmartNotification(
            title: "\(profileName) - Usage Alert",
            body: "You've used \(percentStr) of your session limit. \(resetStr)",
            actionLabel: nil,
            actionURL: nil,
            priority: .medium,
            category: .threshold
        )
    }
}
