import SwiftUI

/// Collapsible accordion showing every profile's session/weekly status side
/// by side. Auto-expands when the active profile is at >= 80% so users can
/// see at a glance whether another profile has more room.
struct CrossProfileAccordion: View {
    let profiles: [Profile]
    let activeProfileId: UUID?
    let onSelectProfile: (UUID) -> Void

    @State private var isExpanded: Bool = false
    /// Tracks whether the user has manually toggled the accordion. When true,
    /// auto-expand (from a profile hitting >= 80%) is suppressed so the user's
    /// last explicit choice is respected.
    @State private var userToggledManually: Bool = false

    private var rows: [(profile: Profile, usage: ClaudeUsage?)] {
        profiles.map { profile in
            (profile, profile.claudeUsage)
        }
    }

    private var shouldAutoExpand: Bool {
        guard let activeId = activeProfileId,
              let active = profiles.first(where: { $0.id == activeId }),
              let usage = active.claudeUsage else {
            return false
        }
        return max(usage.effectiveSessionPercentage, usage.weeklyPercentage) >= 80
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                userToggledManually = true
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.info)
                    Text("Profiles at a glance")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(profiles.count)")
                        .font(AppTheme.Typography.nanoSemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Typography.nanoSemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .onAppear {
                if shouldAutoExpand { isExpanded = true }
            }
            .onChange(of: shouldAutoExpand) { _, newValue in
                if newValue && !userToggledManually { isExpanded = true }
            }

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(rows, id: \.profile.id) { row in
                        rowView(profile: row.profile, usage: row.usage)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private func rowView(profile: Profile, usage: ClaudeUsage?) -> some View {
        let isActive = profile.id == activeProfileId
        let sessionPct = usage?.effectiveSessionPercentage ?? 0
        let weeklyPct = usage?.weeklyPercentage ?? 0
        let hasData = usage != nil
        let maxPct = max(sessionPct, weeklyPct)
        let rowColor: Color = {
            guard hasData else { return AppTheme.Colors.textMuted }
            switch maxPct {
            case 80...: return AppTheme.Colors.error
            case 50..<80: return AppTheme.Colors.warning
            default: return AppTheme.Colors.success
            }
        }()

        Button(action: { onSelectProfile(profile.id) }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(rowColor)
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.name)
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    if let usage = usage {
                        Text("Resets \(usage.sessionResetTime.timeRemainingString())")
                            .font(AppTheme.Typography.tiny)
                            .foregroundColor(AppTheme.Colors.textMuted)
                            .lineLimit(1)
                    } else {
                        Text("No data yet")
                            .font(AppTheme.Typography.tiny)
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("S \(Int(sessionPct))%")
                        .font(AppTheme.Typography.monoTiny)
                        .foregroundColor(rowColor)
                    Text("W \(Int(weeklyPct))%")
                        .font(AppTheme.Typography.monoTiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }

                if isActive {
                    Text("Active")
                        .font(AppTheme.Typography.nanoBold)
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppTheme.Colors.accentMuted))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(isActive ? AppTheme.Colors.elevated.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
