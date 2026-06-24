import SwiftUI

struct DetailsDisclosure: View {
    let usage: ClaudeUsage
    let apiUsage: APIUsage?
    let manager: MenuBarManager

    @State private var isExpanded = false
    @StateObject private var profileManager = ProfileManager.shared

    private var activeProfile: Profile? {
        profileManager.activeProfile
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text("Details")
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: AppTheme.Spacing.xs) {
                    apiCostRow
                    sessionBreakdownRow
                    contextWindowRow
                    costTransparencyRow
                }
                .padding(.horizontal, 14)
                .padding(.bottom, AppTheme.Spacing.sm)
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

    // MARK: - API Cost Row

    @ViewBuilder
    private var apiCostRow: some View {
        if let api = apiUsage {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "creditcard.fill")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 16)

                Text("API cost")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                if let cost = api.formattedAPICost {
                    Text(cost)
                        .font(AppTheme.Typography.roundedSemibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                Text(api.formattedUsed)
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Session Breakdown Row

    @ViewBuilder
    private var sessionBreakdownRow: some View {
        if let profile = activeProfile,
           let breakdown = ConversationBreakdownService.shared.getBreakdown(for: profile.id),
           !breakdown.conversations.isEmpty {
            DisclosureGroup {
                VStack(spacing: 3) {
                    ForEach(breakdown.sortedByCost.prefix(5)) { conversation in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(conversation.isHighCost ? AppTheme.Colors.error.opacity(0.6) : AppTheme.Colors.accent.opacity(0.4))
                                .frame(width: 5, height: 5)

                            Text(conversation.title)
                                .font(AppTheme.Typography.tiny)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("\(conversation.tokensUsed.formatted()) tokens")
                                .font(AppTheme.Typography.nanoMedium)
                                .foregroundColor(AppTheme.Colors.textMuted)

                            if conversation.isHighCost {
                                Text("\(Int(conversation.percentageOfSession))%")
                                    .font(AppTheme.Typography.nanoSemibold)
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.tiny)
                                .fill(AppTheme.Colors.card)
                        )
                    }
                }
                .padding(.top, 4)
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "text.bubble.fill")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(width: 16)

                    Text("This session")
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Spacer()

                    Text("\(breakdown.conversations.count)")
                        .font(AppTheme.Typography.badge)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Context Window Row

    @ViewBuilder
    private var contextWindowRow: some View {
        if usage.sessionTokensUsed > 0 {
            let ctxUsage = ContextWindowTracker.shared.estimateContextWindow(sessionTokens: usage.sessionTokensUsed)

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "window.horizontal")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 16)

                Text("Context window")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("\(Int(ctxUsage.usagePercentage))%")
                    .font(AppTheme.Typography.roundedSemibold)
                    .foregroundColor(ctxUsage.isCritical ? AppTheme.Colors.error : (ctxUsage.isNearCompaction ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary))

                Text("\(ctxUsage.currentTokens.formatted())/200K")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Cost Transparency Row

    @ViewBuilder
    private var costTransparencyRow: some View {
        if let breakdown = CostTransparency.shared.calculate(usage: usage) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 16)

                Text("API value")
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text(breakdown.formattedTotalCost)
                    .font(AppTheme.Typography.roundedSemibold)
                    .foregroundColor(AppTheme.Colors.success)

                Text("est. today")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Multi-AI Row (removed; ProviderAvailabilityStrip now surfaces this)

    // Empty — intentionally kept as a comment marker for future contributors.
}
