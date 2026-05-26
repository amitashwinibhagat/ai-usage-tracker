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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("All Profiles")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Text("\(profilesWithUsage.count) profiles")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Aggregate totals
            HStack(spacing: 16) {
                AggregateMetric(
                    label: "Session Tokens",
                    value: "\(totalSessionTokens.formatted())",
                    icon: "flame.fill",
                    color: .orange
                )

                AggregateMetric(
                    label: "Weekly Tokens",
                    value: "\(totalWeeklyTokens.formatted())",
                    icon: "calendar",
                    color: .blue
                )
            }

            // Per-profile rows
            VStack(spacing: 6) {
                ForEach(profilesWithUsage, id: \.0.id) { profile, usage in
                    ProfileUsageRow(profile: profile, usage: usage)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }
}

struct AggregateMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(6)
    }
}

struct ProfileUsageRow: View {
    let profile: Profile
    let usage: ClaudeUsage

    var body: some View {
        HStack(spacing: 8) {
            // Profile indicator
            Circle()
                .fill(usageColor)
                .frame(width: 6, height: 6)

            Text(profile.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)

            Spacer()

            // Session
            HStack(spacing: 3) {
                Text("\(Int(usage.effectiveSessionPercentage))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(usageColor)
            }

            // Weekly
            HStack(spacing: 3) {
                Text("\(Int(usage.weeklyPercentage))%")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(profile.isSelectedForDisplay ? 0.05 : 0.02))
        )
    }

    private var usageColor: Color {
        let pct = usage.effectiveSessionPercentage
        switch pct {
        case 0..<50: return .adaptiveGreen
        case 50..<80: return .orange
        default: return .red
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
