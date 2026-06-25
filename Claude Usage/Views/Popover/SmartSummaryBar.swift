import SwiftUI

/// Compact card combining the next reset time and burn-rate forecast into a
/// single scannable card. Replaces the standalone ResetCountdownCard and
/// BurnRateCard in the popover. Surfaces BOTH session and weekly reset times
/// stacked in the reset column so users never lose visibility of the weekly
/// limit.
struct SmartSummaryBar: View {
    let usage: ClaudeUsage
    let profileId: UUID

    @State private var prediction: BurnRatePrediction?

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

    private var sessionResetUrgent: Bool {
        let now = Date()
        let interval = usage.sessionResetTime.timeIntervalSince(now)
        return interval > 0 && interval < 24 * 3600
    }

    private var weeklyResetUrgent: Bool {
        let now = Date()
        let interval = usage.weeklyResetTime.timeIntervalSince(now)
        return interval > 0 && interval < 24 * 3600
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            resetColumn
            Rectangle()
                .fill(AppTheme.Colors.divider)
                .frame(width: 1, height: 44)
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
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "clock.fill")
                .font(AppTheme.Typography.tinySemibold)
                .foregroundColor(AppTheme.Colors.textMuted)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 4) {
                resetRow(label: "Session", resetTime: usage.sessionResetTime, urgent: sessionResetUrgent)
                resetRow(label: "Weekly", resetTime: usage.weeklyResetTime, urgent: weeklyResetUrgent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func resetRow(label: String, resetTime: Date, urgent: Bool) -> some View {
        if resetTime > Date() {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(urgent ? AppTheme.Colors.warning : AppTheme.Colors.textMuted)
                    Text(resetTime.timeRemainingString())
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(urgent ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Text(resetTime.resetTimeString())
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                    Text("passed")
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                Text("—")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
        }
    }

    @ViewBuilder
    private var paceColumn: some View {
        if hasUsableForecast, let minutes = limitingMinutes {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: minutes < 15 ? "exclamationmark.triangle.fill" : "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(paceColor(minutes: minutes))
                    .padding(.top, 3)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(paceHeadline(minutes: minutes))
                            .font(AppTheme.Typography.captionMedium)
                            .foregroundColor(paceColor(minutes: minutes))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(limitingIsWeekly ? "weekly" : "session")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(paceColor(minutes: minutes))
                            .lineLimit(1)
                    }
                    Text("at current pace")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .padding(.top, 3)
                Text("Need more usage to forecast")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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
            sessionTokensUsed: 2_300,
            sessionLimit: 10_000,
            sessionPercentage: 23,
            sessionResetTime: Date().addingTimeInterval(1 * 3600 + 59 * 60),
            weeklyTokensUsed: 10_000,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 1,
            weeklyResetTime: Date().addingTimeInterval(6 * 86400 + 21 * 3600),
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
