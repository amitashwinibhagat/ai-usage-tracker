import SwiftUI

struct SessionOverlapCard: View {
    let profile: Profile
    @StateObject private var planningService = SessionPlanningService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.accentHover)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.accentMuted)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session plan")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Align Claude reset timing with your work block.")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }

                Spacer()
            }

            if planningService.isSessionActive(for: profile),
               let usage = profile.claudeUsage {
                let estimatedStart = usage.sessionResetTime.addingTimeInterval(-Constants.sessionWindow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session active since \(FormatterHelper.timeString(from: estimatedStart))")
                        .font(AppTheme.Typography.tinyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text("Resets \(FormatterHelper.timeString(from: usage.sessionResetTime))")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            } else if let pingTime = planningService.calculateRecommendedPingTime(for: profile),
                      let plannedWorkStart = profile.sessionPlanningSettings?.plannedWorkStart {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next ping: \(FormatterHelper.timeString(from: pingTime))")
                        .font(AppTheme.Typography.tinyMedium)
                        .foregroundColor(AppTheme.Colors.accentHover)
                    Text("Work starts: \(FormatterHelper.timeString(from: plannedWorkStart))")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            } else {
                Text("No active plan")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.accent.opacity(0.24), lineWidth: 0.5)
        )
        .padding(.horizontal, 14)
    }
}
