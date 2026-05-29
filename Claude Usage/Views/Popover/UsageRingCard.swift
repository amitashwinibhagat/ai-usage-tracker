import SwiftUI

struct UsageRingCard: View {
    let usage: ClaudeUsage
    let apiUsage: APIUsage?

    @State private var showingWeekly = false

    private let ringSize: CGFloat = 140
    private let ringLineWidth: CGFloat = 10

    private var activePercentage: Double {
        if showingWeekly {
            return usage.weeklyPercentage
        }
        return usage.effectiveSessionPercentage
    }

    private var tokenLabel: String {
        if showingWeekly {
            return "\(usage.weeklyTokensUsed.formatted()) of \(usage.weeklyLimit.formatted()) tokens this week"
        }
        return "\(usage.sessionTokensUsed.formatted()) of \(usage.sessionLimit.formatted()) tokens this session"
    }

    private var statusColor: Color {
        switch activePercentage {
        case 90...: return AppTheme.Colors.error
        case 75..<90: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }

    private var percentageText: String {
        "\(Int(activePercentage.rounded()))%"
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.elevated.opacity(0.6), lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)

                Circle()
                    .trim(from: 0, to: max(0.001, min(activePercentage / 100.0, 1.0)))
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
                    .animation(.easeInOut(duration: 0.8), value: activePercentage)

                VStack(spacing: 2) {
                    Text(percentageText)
                        .font(AppTheme.Typography.statLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("USED")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }

                VStack(spacing: 0) {
                    Spacer()

                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingWeekly = false
                            }
                        }) {
                            Text("Session")
                                .font(AppTheme.Typography.pico)
                                .foregroundColor(showingWeekly ? AppTheme.Colors.textMuted : AppTheme.Colors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(showingWeekly ? Color.clear : statusColor.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingWeekly = true
                            }
                        }) {
                            Text("Weekly")
                                .font(AppTheme.Typography.pico)
                                .foregroundColor(showingWeekly ? AppTheme.Colors.textPrimary : AppTheme.Colors.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(showingWeekly ? statusColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 6)
                }
                .frame(width: ringSize, height: ringSize)
            }
            .frame(maxWidth: .infinity)

            Text(tokenLabel)
                .font(AppTheme.Typography.captionMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if let apiUsage = apiUsage, apiUsage.usagePercentage > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(AppTheme.Typography.nanoMedium)
                        .foregroundColor(AppTheme.Colors.textMuted)

                    Text("API: \(apiUsage.formattedAPICost ?? "$0.00")")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}
