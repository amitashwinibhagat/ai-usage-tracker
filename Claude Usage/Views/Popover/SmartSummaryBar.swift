import SwiftUI

/// Compact card combining the next reset time and burn-rate forecast into a
/// single scannable line. Replaces the standalone ResetCountdownCard and
/// BurnRateCard in the popover.
struct SmartSummaryBar: View {
    let usage: ClaudeUsage
    let profileId: UUID

    @State private var prediction: BurnRatePrediction?

    private var nearestReset: Date {
        let now = Date()
        let candidates = [usage.sessionResetTime, usage.weeklyResetTime]
            .filter { $0 > now }
        return candidates.min() ?? usage.sessionResetTime
    }

    private var resetIsUrgent: Bool {
        let interval = nearestReset.timeIntervalSince(Date())
        return interval > 0 && interval < 24 * 3600
    }

    private var hasUsableForecast: Bool {
        guard let prediction = prediction else { return false }
        return prediction.isReliable && usage.sessionTokensUsed > 0
    }

    private var limitingMinutes: Double? {
        guard let prediction = prediction else { return nil }
        let candidates = [prediction.minutesToLimit, prediction.weeklyMinutesToLimit].compactMap { $0 }
        guard !candidates.isEmpty else { return nil }
        return candidates.min()
    }

    /// Whether the limiting factor is the session or weekly window, used to
    /// qualify the pace label so users know which limit will be hit.
    private var limitingIsWeekly: Bool {
        guard let prediction = prediction,
              let sessionMin = prediction.minutesToLimit,
              let weeklyMin = prediction.weeklyMinutesToLimit else {
            return false
        }
        return weeklyMin <= sessionMin
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
            resetColumn
            Rectangle()
                .fill(AppTheme.Colors.divider)
                .frame(width: 1, height: 24)
            paceColumn
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .onAppear { computePrediction() }
        .onChange(of: usage.sessionTokensUsed) { _, _ in computePrediction() }
        .onChange(of: usage.weeklyTokensUsed) { _, _ in computePrediction() }
        .onChange(of: usage.weeklyResetTime) { _, _ in computePrediction() }
    }

    private var resetColumn: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(AppTheme.Typography.tinySemibold)
                .foregroundColor(resetIsUrgent ? AppTheme.Colors.warning : AppTheme.Colors.textMuted)

            VStack(alignment: .leading, spacing: 0) {
                Text("Resets in \(nearestReset.timeRemainingString())")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(resetIsUrgent ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary)
                Text(nearestResetLabel)
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nearestResetLabel: String {
        let now = Date()
        let sessionOk = usage.sessionResetTime > now
        let weeklyOk = usage.weeklyResetTime > now
        let sessionInterval = sessionOk ? usage.sessionResetTime.timeIntervalSince(now) : .greatestFiniteMagnitude
        let weeklyInterval = weeklyOk ? usage.weeklyResetTime.timeIntervalSince(now) : .greatestFiniteMagnitude

        if sessionInterval < weeklyInterval {
            return "Session · \(usage.sessionResetTime.resetTimeString())"
        } else if weeklyOk {
            return "Weekly · \(usage.weeklyResetTime.resetTimeString())"
        } else {
            return "Reset passed"
        }
    }

    @ViewBuilder
    private var paceColumn: some View {
        if hasUsableForecast, let minutes = limitingMinutes {
            HStack(spacing: 6) {
                Image(systemName: minutes < 15 ? "exclamationmark.triangle.fill" : "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(paceColor(minutes: minutes))
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(paceHeadline(minutes: minutes))
                            .font(AppTheme.Typography.captionMedium)
                            .foregroundColor(paceColor(minutes: minutes))
                        Text(limitingIsWeekly ? "weekly" : "session")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(paceColor(minutes: minutes))
                            .lineLimit(1)
                    }
                    Text("at current pace")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text("Need more usage to forecast")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func paceColor(minutes: Double) -> Color {
        if minutes < 15 { return AppTheme.Colors.error }
        if minutes < 60 { return AppTheme.Colors.warning }
        return AppTheme.Colors.textPrimary
    }

    private func paceHeadline(minutes: Double) -> String {
        if minutes < 1 { return "Limit reached soon" }
        if minutes < 60 { return "Limit in \(Int(minutes)) min" }
        let hours = minutes / 60
        if hours < 24 { return String(format: "Limit in %.1f hr", hours) }
        return String(format: "Limit in %.1f days", hours / 24)
    }

    private func computePrediction() {
        let full = BurnRatePredictor.shared.predict(for: profileId, currentUsage: usage)
        if full.isReliable {
            prediction = full
        } else {
            prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
        }
    }
}

#Preview {
    SmartSummaryBar(
        usage: ClaudeUsage(
            sessionTokensUsed: 1_750,
            sessionLimit: 10_000,
            sessionPercentage: 17.5,
            sessionResetTime: Date().addingTimeInterval(4 * 3600 + 35 * 60),
            weeklyTokensUsed: 410_000,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 41,
            weeklyResetTime: Date().nextMonday1259pm(),
            opusWeeklyTokensUsed: 0,
            opusWeeklyPercentage: 0,
            sonnetWeeklyTokensUsed: 0,
            sonnetWeeklyPercentage: 0,
            sonnetWeeklyResetTime: nil,
            costUsed: nil,
            costLimit: nil,
            costCurrency: nil,
            overageBalance: nil,
            overageBalanceCurrency: nil,
            lastUpdated: Date(),
            userTimezone: .current
        ),
        profileId: UUID()
    )
    .padding()
    .background(AppTheme.Colors.background)
    .preferredColorScheme(.dark)
}
