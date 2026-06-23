import SwiftUI

struct ContextualTipCard: View {
    let profile: Profile
    let usage: ClaudeUsage
    @State private var currentTip: LimitOptimizationTip?
    @State private var copiedCommand: String?

    var body: some View {
        if let tip = currentTip,
           shouldShowTip {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.caution)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.caution.opacity(0.13))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Usage tip")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(AppTheme.Colors.textMuted)
                            .textCase(.uppercase)

                        Text(tip.titleKey.localized)
                            .font(AppTheme.Typography.captionMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if let actionData = tip.actionData, actionData.type != .none {
                        Button {
                            if actionData.type == .copy, let value = actionData.value {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(value, forType: .string)
                                copiedCommand = value
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedCommand = nil
                                }
                            }
                        } label: {
                            Image(systemName: copiedCommand == actionData.value ? "checkmark" : "doc.on.doc")
                                .font(AppTheme.Typography.tinySemibold)
                                .foregroundColor(copiedCommand == actionData.value ? AppTheme.Colors.success : AppTheme.Colors.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
            .onAppear {
                loadTip()
            }
            .onChange(of: usage.sessionTokensUsed) { _, _ in
                loadTip()
            }
        } else {
            EmptyView()
                .onAppear {
                    loadTip()
                }
        }
    }

    private var shouldShowTip: Bool {
        guard let settings = profile.sessionPlanningSettings else { return false }
        if usage.effectiveSessionPercentage > 80 {
            return settings.planModeTipsEnabled
        }
        return true
    }

    private func loadTip() {
        let isPeak = PeakHoursService.shared.isPeakHours
        currentTip = LimitOptimizationTipService.shared.rotatingTip(
            sessionPercentage: usage.effectiveSessionPercentage,
            isPeakHours: isPeak,
            lastTipId: nil
        )
    }
}
