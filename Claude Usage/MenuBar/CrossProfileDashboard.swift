//
//  CrossProfileDashboard.swift
//  Claude Usage
//
//  Unified view showing all profiles' usage side-by-side.
//

import SwiftUI

/// Cross-profile unified dashboard - shows all profiles in one view
struct CrossProfileDashboard: View {
    @StateObject private var profileManager = ProfileManager.shared

    private var profilesWithUsage: [(Profile, ClaudeUsage)] {
        profileManager.profiles.compactMap { profile in
            guard let usage = profile.claudeUsage else { return nil }
            return (profile, usage)
        }
    }

    private var totalSessionTokens: Int {
        profilesWithUsage.reduce(0) { $0 + $1.1.sessionTokensUsed }
    }

    private var totalWeeklyTokens: Int {
        profilesWithUsage.reduce(0) { $0 + $1.1.weeklyTokensUsed }
    }

    private var highestRiskProfile: (Profile, ClaudeUsage)? {
        profilesWithUsage.max { lhs, rhs in
            max(lhs.1.effectiveSessionPercentage, lhs.1.weeklyPercentage) < max(rhs.1.effectiveSessionPercentage, rhs.1.weeklyPercentage)
        }
    }

    private var sortedProfiles: [(Profile, ClaudeUsage)] {
        profilesWithUsage.sorted {
            max($0.1.effectiveSessionPercentage, $0.1.weeklyPercentage) > max($1.1.effectiveSessionPercentage, $1.1.weeklyPercentage)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.info)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.info.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Profiles at a glance")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(crossProfileGuidance)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("\(profilesWithUsage.count) profiles")
                    .font(AppTheme.Typography.badge)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                AggregateMetric(
                    label: "Session",
                    value: "\(totalSessionTokens.formatted())",
                    icon: "flame.fill",
                    color: AppTheme.Colors.warning
                )

                AggregateMetric(
                    label: "Weekly",
                    value: "\(totalWeeklyTokens.formatted())",
                    icon: "calendar",
                    color: AppTheme.Colors.info
                )
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(sortedProfiles, id: \.0.id) { profile, usage in
                    ProfileUsageRow(profile: profile, usage: usage)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }

    private var crossProfileGuidance: String {
        guard let highestRiskProfile else {
            return "No profile usage has been refreshed yet."
        }

        let name = highestRiskProfile.0.name
        let risk = max(highestRiskProfile.1.effectiveSessionPercentage, highestRiskProfile.1.weeklyPercentage)
        if risk >= 80 { return "\(name) needs attention before more heavy work." }
        if risk >= 50 { return "\(name) is the profile to watch next." }
        return "All tracked profiles have comfortable capacity."
    }
}

struct AggregateMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(AppTheme.Typography.tinySemibold)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(AppTheme.Typography.nanoMedium)
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text(value)
                    .font(AppTheme.Typography.captionSemibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(color.opacity(0.18), lineWidth: 0.5)
        )
    }
}

struct ProfileUsageRow: View {
    let profile: Profile
    let usage: ClaudeUsage

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(spacing: 2) {
                Circle()
                    .fill(usageColor)
                    .frame(width: 7, height: 7)

                Text(riskLabel)
                    .font(AppTheme.Typography.nanoBold)
                    .foregroundColor(usageColor)
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("Resets \(usage.sessionResetTime.timeRemainingString())")
                    .font(AppTheme.Typography.nanoMedium)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("S \(Int(usage.effectiveSessionPercentage))%")
                    .font(AppTheme.Typography.monoTiny)
                    .foregroundColor(usageColor)

                Text("W \(Int(usage.weeklyPercentage))%")
                    .font(AppTheme.Typography.monoTiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(AppTheme.Colors.backgroundDeep.opacity(profile.isSelectedForDisplay ? 0.55 : 0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
        )
    }

    private var riskLabel: String {
        switch max(usage.effectiveSessionPercentage, usage.weeklyPercentage) {
        case 80...: return "High"
        case 50..<80: return "Watch"
        default: return "OK"
        }
    }

    private var usageColor: Color {
        let pct = max(usage.effectiveSessionPercentage, usage.weeklyPercentage)
        switch pct {
        case 0..<50: return AppTheme.Colors.success
        case 50..<80: return AppTheme.Colors.warning
        default: return AppTheme.Colors.error
        }
    }
}

extension Int {
    fileprivate var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
