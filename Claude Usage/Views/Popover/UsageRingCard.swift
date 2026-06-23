import SwiftUI

struct UsageRingCard: View {
    let usage: ClaudeUsage
    let apiUsage: APIUsage?

    private enum DisplayMode {
        case session
        case weekly
    }

    @State private var showingWeekly: Bool

    private let ringSize: CGFloat = 130
    private let ringLineWidth: CGFloat = 10

    init(usage: ClaudeUsage, apiUsage: APIUsage?) {
        self.usage = usage
        self.apiUsage = apiUsage
        // Default to whichever limit is closer to being hit.
        _showingWeekly = State(initialValue: usage.weeklyPercentage > usage.effectiveSessionPercentage)
    }

    private var displayMode: DisplayMode {
        showingWeekly ? .weekly : .session
    }

    private var activePercentage: Double {
        switch displayMode {
        case .weekly: return usage.weeklyPercentage
        case .session: return usage.effectiveSessionPercentage
        }
    }

    private var statusColor: Color {
        switch activePercentage {
        case 0..<50: return AppTheme.Colors.success
        case 50..<80: return AppTheme.Colors.caution
        case 80..<95: return AppTheme.Colors.warning
        default: return AppTheme.Colors.error
        }
    }

    private var verdict: (text: String, color: Color) {
        switch activePercentage {
        case 0: return ("No usage yet", AppTheme.Colors.success)
        case 0..<50: return ("Plenty of room", AppTheme.Colors.success)
        case 50..<80: return ("Watch your pace", AppTheme.Colors.caution)
        case 80..<95: return ("Slow down soon", AppTheme.Colors.warning)
        case 95..<100: return ("Almost at limit", AppTheme.Colors.error)
        default: return ("Limit reached", AppTheme.Colors.error)
        }
    }

    private var percentageText: String {
        "\(Int(activePercentage.rounded()))%"
    }

    private var primaryLabel: String {
        switch displayMode {
        case .weekly: return "Weekly limit"
        case .session: return "5-hour session limit"
        }
    }

    private var tokenCountString: String {
        let used = displayMode == .weekly ? usage.weeklyTokensUsed : usage.sessionTokensUsed
        let limit = displayMode == .weekly ? usage.weeklyLimit : usage.sessionLimit
        guard limit > 0 else { return "Limit not set" }
        return "\(used.formatted()) / \(limit.formatted()) tokens"
    }

    private var secondaryDetail: String? {
        switch displayMode {
        case .weekly:
            guard usage.sessionTokensUsed > 0 || usage.effectiveSessionPercentage > 0 else { return nil }
            return "Session: \(Int(usage.effectiveSessionPercentage.rounded()))% · \(usage.sessionTokensUsed.formatted()) tokens"
        case .session:
            guard usage.weeklyTokensUsed > 0 || usage.weeklyPercentage > 0 else { return nil }
            return "Weekly: \(Int(usage.weeklyPercentage.rounded()))% · \(usage.weeklyTokensUsed.formatted()) tokens"
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text(verdict.text)
                .font(AppTheme.Typography.captionSemibold)
                .foregroundColor(verdict.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(verdict.color.opacity(0.12))
                )
                .accessibilityLabel(verdict.text)

            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.elevated.opacity(0.5), lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: max(0, min(activePercentage / 100.0, 1.0)))
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: activePercentage)

                VStack(spacing: 2) {
                    Text(percentageText)
                        .font(AppTheme.Typography.statLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(primaryLabel)
                        .font(AppTheme.Typography.microSemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(percentageText) of \(primaryLabel.lowercased()) used")

            Picker("Usage window", selection: $showingWeekly) {
                Text("5-hour session")
                    .tag(false)
                Text("Weekly")
                    .tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .accessibilityLabel("Usage window")
            .accessibilityHint("Switch between 5-hour session and weekly usage")

            VStack(spacing: 2) {
                Text(tokenCountString)
                    .font(AppTheme.Typography.smallMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                if let secondaryDetail = secondaryDetail {
                    Text(secondaryDetail)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

#Preview("Low weekly usage") {
    UsageRingCard(
        usage: ClaudeUsage(
            sessionTokensUsed: 0,
            sessionLimit: 10000,
            sessionPercentage: 0,
            sessionResetTime: Date().addingTimeInterval(5 * 60 * 60),
            weeklyTokensUsed: 1200,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 12,
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

#Preview("High session usage") {
    UsageRingCard(
        usage: ClaudeUsage(
            sessionTokensUsed: 8750,
            sessionLimit: 10000,
            sessionPercentage: 87.5,
            sessionResetTime: Date().addingTimeInterval(5 * 60 * 60),
            weeklyTokensUsed: 1200,
            weeklyLimit: 1_000_000,
            weeklyPercentage: 12,
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
