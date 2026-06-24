import SwiftUI

/// Hero card showing Session and Weekly usage side-by-side with a single
/// "limiting factor" status badge. Replaces the single large ring so users
/// can see both Claude limits at a glance without toggling.
struct DualMetricHero: View {
    let usage: ClaudeUsage
    let apiUsage: APIUsage?

    private let ringSize: CGFloat = 76
    private let ringLineWidth: CGFloat = 7

    private var sessionPct: Double { usage.effectiveSessionPercentage }
    private var weeklyPct: Double { usage.weeklyPercentage }

    private var sessionColor: Color { Self.color(for: sessionPct) }
    private var weeklyColor: Color { Self.color(for: weeklyPct) }

    /// Whether session or weekly is the more urgent limit. `nil` when both are
    /// low (no urgent limit).
    private enum LimitingFactor { case session, weekly }
    private var limitingFactor: LimitingFactor? {
        if sessionPct >= weeklyPct { return .session }
        return .weekly
    }

    private var statusBadge: (text: String, color: Color) {
        // No real session window currently active
        if usage.sessionResetTime < Date() && sessionPct == 0 && weeklyPct < 50 {
            return ("Session not active", AppTheme.Colors.success)
        }
        let maxPct = max(sessionPct, weeklyPct)
        if maxPct < 50 {
            return ("Plenty of room", AppTheme.Colors.success)
        }
        if maxPct < 80 {
            return limitingFactor == .weekly
                ? ("Weekly is the constraint", AppTheme.Colors.caution)
                : ("Watch your pace", AppTheme.Colors.caution)
        }
        if maxPct < 95 {
            return limitingFactor == .weekly
                ? ("Weekly is the constraint", AppTheme.Colors.warning)
                : ("Slow down soon", AppTheme.Colors.warning)
        }
        return limitingFactor == .weekly
            ? ("Weekly limit near", AppTheme.Colors.error)
            : ("Session almost full", AppTheme.Colors.error)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(statusBadge.text)
                .font(AppTheme.Typography.captionSemibold)
                .foregroundColor(statusBadge.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(statusBadge.color.opacity(0.12))
                )
                .accessibilityLabel("Status: \(statusBadge.text)")

            HStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
                ringColumn(
                    pct: sessionPct,
                    color: sessionColor,
                    label: "5-hour session",
                    used: usage.sessionTokensUsed,
                    limit: usage.sessionLimit,
                    accessibilityName: "Session"
                )
                ringColumn(
                    pct: weeklyPct,
                    color: weeklyColor,
                    label: "Weekly",
                    used: usage.weeklyTokensUsed,
                    limit: usage.weeklyLimit,
                    accessibilityName: "Weekly"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    @ViewBuilder
    private func ringColumn(
        pct: Double,
        color: Color,
        label: String,
        used: Int,
        limit: Int,
        accessibilityName: String
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.elevated.opacity(0.5), lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: max(0, min(pct / 100.0, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pct)

                Text("\(Int(pct.rounded()))%")
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(accessibilityName) usage \(Int(pct.rounded())) percent")

            Text(label)
                .font(AppTheme.Typography.tinySemibold)
                .foregroundColor(AppTheme.Colors.textMuted)
                .lineLimit(1)

            tokenLabel(used: used, limit: limit)
                .font(AppTheme.Typography.tiny)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func tokenLabel(used: Int, limit: Int) -> some View {
        if limit > 0 {
            Text("\(used.formatted()) / \(limit.formatted())")
        } else {
            Text("Limit not set")
        }
    }

    private static func color(for pct: Double) -> Color {
        switch pct {
        case 0..<50: return AppTheme.Colors.success
        case 50..<80: return AppTheme.Colors.caution
        case 80..<95: return AppTheme.Colors.warning
        default: return AppTheme.Colors.error
        }
    }
}

#Preview("Both moderate") {
    DualMetricHero(
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
        apiUsage: nil
    )
    .padding()
    .background(AppTheme.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("Session critical") {
    DualMetricHero(
        usage: ClaudeUsage(
            sessionTokensUsed: 8_750,
            sessionLimit: 10_000,
            sessionPercentage: 87.5,
            sessionResetTime: Date().addingTimeInterval(35 * 60),
            weeklyTokensUsed: 200_000,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 20,
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
        apiUsage: nil
    )
    .padding()
    .background(AppTheme.Colors.background)
    .preferredColorScheme(.dark)
}
