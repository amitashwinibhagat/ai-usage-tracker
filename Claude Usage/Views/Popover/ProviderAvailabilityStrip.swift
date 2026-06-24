import SwiftUI

/// Horizontal strip of chips showing the status of every connected AI provider
/// (Codex, Gemini, Copilot, etc.). Hidden entirely when no providers are
/// configured. Each chip surfaces OK / Watch / Critical so users can pick the
/// provider with the most room without leaving the popover.
struct ProviderAvailabilityStrip: View {
    let profile: Profile
    let multiAIResult: MultiAIUsageResult?
    var onTapProvider: ((AIProvider) -> Void)? = nil

    /// Providers with stored credentials AND real usage-fetching implementations.
    /// Excludes Claude (the hero metric) and the five Chinese providers that
    /// only validate API keys without fetching real usage data (free-pivot decision).
    private var connectedProviders: [AIProvider] {
        profile.configuredProviders
            .filter { $0 != .claude && $0.isImplemented }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.info)
                Text("Other providers")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(connectedProviders, id: \.self) { provider in
                        chip(for: provider)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func chip(for provider: AIProvider) -> some View {
        let status = status(for: provider)
        Button(action: { onTapProvider?(provider) }) {
            HStack(spacing: 5) {
                Image(systemName: provider.icon)
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(provider.brandColor)

                Text(provider.shortName)
                    .font(AppTheme.Typography.tinyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                statusBadge(for: status)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(provider.brandColor.opacity(0.10))
            )
            .overlay(
                Capsule().strokeBorder(provider.brandColor.opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("\(provider.displayName) — \(status.label)")
        .accessibilityLabel("\(provider.displayName), \(status.label)")
    }

    @ViewBuilder
    private func statusBadge(for status: ProviderStatus) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(status.color)
                .frame(width: 5, height: 5)
            Text(status.label)
                .font(AppTheme.Typography.nanoSemibold)
                .foregroundColor(status.color)
        }
    }

    private func status(for provider: AIProvider) -> ProviderStatus {
        // Only show a percentage when we have real usage data with non-zero
        // tokens. Avoids "OK 0%" chips for unimplemented providers or empty fetches.
        if let usage = multiAIResult?.allUsage[provider],
           usage.isValid,
           usage.tokensUsed > 0 {
            let pct = usage.usagePercentage
            if pct >= 80 { return .critical(percentage: pct) }
            if pct >= 50 { return .watch(percentage: pct) }
            return .ok(percentage: pct)
        }
        // Fall back to credential-only status
        return .connected
    }
}

private enum ProviderStatus {
    case ok(percentage: Double)
    case watch(percentage: Double)
    case critical(percentage: Double)
    case connected

    var color: Color {
        switch self {
        case .ok: return AppTheme.Colors.success
        case .watch: return AppTheme.Colors.warning
        case .critical: return AppTheme.Colors.error
        case .connected: return AppTheme.Colors.textMuted
        }
    }

    var label: String {
        switch self {
        case .ok(let pct), .watch(let pct), .critical(let pct):
            return "\(Int(pct))%"
        case .connected:
            return "Connected"
        }
    }
}
