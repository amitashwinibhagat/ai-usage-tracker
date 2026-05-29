import SwiftUI

struct ResetCountdownCard: View {
    let usage: ClaudeUsage
    @StateObject private var profileManager = ProfileManager.shared

    private var nearestReset: Date {
        let now = Date()
        if usage.sessionResetTime > now && usage.weeklyResetTime > now {
            return min(usage.sessionResetTime, usage.weeklyResetTime)
        } else if usage.sessionResetTime > now {
            return usage.sessionResetTime
        } else {
            return usage.weeklyResetTime
        }
    }

    private var isUrgent: Bool {
        let interval = nearestReset.timeIntervalSince(Date())
        return interval > 0 && interval < 24 * 60 * 60
    }

    private var accentColor: Color {
        isUrgent ? AppTheme.Colors.warning : AppTheme.Colors.textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            if profileManager.profiles.count > 1 {
                ForEach(profileManager.profiles) { profile in
                    if let profileUsage = profile.claudeUsage {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Circle()
                                .fill(resetCountdownColor(for: profileUsage))
                                .frame(width: 6, height: 6)

                            Text(profile.name)
                                .font(AppTheme.Typography.captionMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(resetCountdownLabel(for: profileUsage))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "clock.fill")
                        .font(AppTheme.Typography.captionSemibold)
                        .foregroundColor(accentColor)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(accentColor.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("NEXT RESET")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(AppTheme.Colors.textMuted)

                        HStack(spacing: 6) {
                            if usage.sessionResetTime > Date() {
                                Text("Session \(usage.sessionResetTime.resetTimeString())")
                                    .font(AppTheme.Typography.captionMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .lineLimit(1)
                            }

                            if usage.weeklyResetTime > Date() {
                                Text("Weekly \(usage.weeklyResetTime.resetTimeString())")
                                    .font(AppTheme.Typography.captionMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()

                    Text(nearestReset.timeRemainingString())
                        .font(AppTheme.Typography.roundedSemibold)
                        .foregroundColor(isUrgent ? AppTheme.Colors.warning : AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(isUrgent ? AppTheme.Colors.warning.opacity(0.08) : AppTheme.Colors.card.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(
                    isUrgent ? AppTheme.Colors.warning.opacity(0.3) : AppTheme.Colors.borderSubtle,
                    lineWidth: 0.5
                )
        )
        .padding(.horizontal, 10)
    }

    private func resetCountdownColor(for profileUsage: ClaudeUsage) -> Color {
        let now = Date()
        let sessionOk = profileUsage.sessionResetTime > now
        let weeklyOk = profileUsage.weeklyResetTime > now

        var intervals: [TimeInterval] = []
        if sessionOk { intervals.append(profileUsage.sessionResetTime.timeIntervalSince(now)) }
        if weeklyOk { intervals.append(profileUsage.weeklyResetTime.timeIntervalSince(now)) }

        let nearest = intervals.min() ?? 0
        if nearest > 0 && nearest < 24 * 60 * 60 {
            return AppTheme.Colors.warning
        }
        return AppTheme.Colors.success
    }

    private func resetCountdownLabel(for profileUsage: ClaudeUsage) -> String {
        let now = Date()
        let sessionOk = profileUsage.sessionResetTime > now
        let weeklyOk = profileUsage.weeklyResetTime > now

        var candidates: [(String, TimeInterval)] = []
        if sessionOk {
            candidates.append(("Session \(profileUsage.sessionResetTime.timeRemainingString())", profileUsage.sessionResetTime.timeIntervalSince(now)))
        }
        if weeklyOk {
            candidates.append(("Weekly \(profileUsage.weeklyResetTime.timeRemainingString())", profileUsage.weeklyResetTime.timeIntervalSince(now)))
        }

        if let nearest = candidates.min(by: { $0.1 < $1.1 }) {
            return nearest.0
        }
        return "Reset"
    }
}
