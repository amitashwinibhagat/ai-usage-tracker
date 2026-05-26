import SwiftUI
import Charts

// MARK: - Always-active vibrancy background
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        // Base vibrancy layer
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.isEmphasized = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effectView)

        // Solid tint overlay for more density
        let tintView = NSView()
        tintView.wantsLayer = true
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor
        } else {
            tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.4).cgColor
        }
        tintView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tintView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: container.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: container.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update tint for appearance changes
        if let tintView = nsView.subviews.last {
            tintView.wantsLayer = true
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor
            } else {
                tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.4).cgColor
            }
        }
    }
}

/// Native macOS popover interface - minimal, flat, system-style
struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void

    @State private var isRefreshing = false
    @State private var showInsights = false
    @StateObject private var profileManager = ProfileManager.shared

    private func profileInitials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    // Computed properties for multi-profile mode support
    private var displayUsage: ClaudeUsage {
        manager.clickedProfileUsage ?? manager.usage
    }

    private var displayAPIUsage: APIUsage? {
        // When viewing a non-active profile, use only that profile's API data
        // to avoid leaking the active profile's console data
        if manager.clickedProfileUsage != nil {
            return manager.clickedProfileAPIUsage
        }
        return manager.apiUsage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            SmartHeader(
                usage: displayUsage,
                status: manager.status,
                isRefreshing: isRefreshing,
                onRefresh: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRefreshing = true
                    }
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isRefreshing = false
                        }
                    }
                },
                onManageProfiles: onPreferences,
                onPreferences: onPreferences,
                clickedProfileId: manager.clickedProfileId
            )

            PopoverDivider()

            // Error / stale data banners
            if manager.hasCredentialError {
                StatusBannerView(
                    icon: "exclamationmark.triangle.fill",
                    message: "popover.banner.credentials_expired".localized,
                    color: .orange
                ) {
                    onPreferences()
                }
            } else if manager.consecutiveRefreshFailures >= 3 {
                StatusBannerView(
                    icon: "arrow.clockwise.circle.fill",
                    message: String(format: "popover.banner.refresh_failed".localized, manager.consecutiveRefreshFailures),
                    color: .yellow
                ) {
                    onRefresh()
                }
            } else if let lastRefresh = manager.lastSuccessfulRefreshTime,
                      Date().timeIntervalSince(lastRefresh) > 300 {
                let minutesAgo = Int(Date().timeIntervalSince(lastRefresh) / 60)
                StatusBannerView(
                    icon: "clock.fill",
                    message: String(format: "popover.banner.updated_ago".localized, minutesAgo),
                    color: .orange
                ) {
                    onRefresh()
                }
            }

            // Viewing usage tag (shown in multi-profile mode)
            if profileManager.displayMode == .multi,
               let viewingProfile = manager.clickedProfileId.flatMap({ id in
                   profileManager.profiles.first(where: { $0.id == id })
               }) ?? profileManager.activeProfile {
                HStack(spacing: 8) {
                    // Profile initials avatar
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 20, height: 20)

                        Text(profileInitials(for: viewingProfile.name))
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                    }

                    Text(viewingProfile.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if viewingProfile.id == profileManager.activeProfile?.id {
                        Text("Active")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.03))
                )
                .padding(.horizontal, 10)
                .padding(.top, 6)
            }

            // Usage
            SmartUsageDashboard(usage: displayUsage, apiUsage: displayAPIUsage)

            // Conversation Breakdown (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.perSessionBreakdown),
               let profile = profileManager.activeProfile,
               let breakdown = ConversationBreakdownService.shared.getBreakdown(for: profile.id),
               !breakdown.conversations.isEmpty {
                PopoverDivider()
                ConversationBreakdownCard(breakdown: breakdown)
            }

            // Burn Rate Predictor (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.burnRatePredictor),
               let profile = profileManager.activeProfile {
                PopoverDivider()
                BurnRateCard(usage: displayUsage, profileId: profile.id)
            }

            // Cost Transparency (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.costTransparency) {
                if let costBreakdown = CostTransparency.shared.calculate(usage: displayUsage) {
                    PopoverDivider()
                    CostTransparencyCard(breakdown: costBreakdown)
                }
            }

            // Cross-Profile Unified Dashboard (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.crossProfileDashboard),
               profileManager.profiles.count > 1 {
                PopoverDivider()
                CrossProfileDashboard()
            }

            // Context Window Tracker (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.contextWindowTracker),
               displayUsage.sessionTokensUsed > 0 {
                let contextUsage = ContextWindowTracker.shared.estimateContextWindow(sessionTokens: displayUsage.sessionTokensUsed)
                if contextUsage.usagePercentage > 50 {
                    PopoverDivider()
                    ContextWindowCard(usage: contextUsage)
                }
            }

            // Predictive Throttling Alert (Pro)
            if FeatureFlags.shared.isAvailable(FeatureFlags.shared.predictiveThrottling),
               let profile = profileManager.activeProfile,
               let prediction = PredictiveThrottlingService.shared.predict(for: profile.id, currentUsage: displayUsage),
               prediction.willHitSessionLimit || prediction.willHitWeeklyLimit {
                PopoverDivider()
                PredictiveThrottlingCard(prediction: prediction)
            }

            // Multi-AI Dashboard (Pro)
            if FeatureFlags.shared.isProOrHigher,
               let profile = profileManager.activeProfile,
               profile.hasMultiAICredentials {
                PopoverDivider()
                MultiAIDashboard(profile: profile)
            }

            // Pro Upsell Banner (Free tier, when usage > 80% or always visible as preview)
            if FeatureFlags.shared.isFree {
                PopoverDivider()
                ProUpsellBanner(usage: displayUsage)
            }

            // Session Overlap Card
            if let activeProfile = profileManager.activeProfile,
               let settings = activeProfile.sessionPlanningSettings,
               settings.isEnabled {
                PopoverDivider()
                SessionOverlapCard(profile: activeProfile)
            }

            // Rotating contextual tip
            if let activeProfile = profileManager.activeProfile {
                PopoverDivider()
                ContextualTipCard(profile: activeProfile, usage: displayUsage)
            }

            // Contextual Insights
            if showInsights {
                PopoverDivider()
                ContextualInsights(usage: displayUsage)
                    .transition(.opacity)
            }

        }
        .padding(.bottom, 8)
        .frame(width: 280)
        .background(VisualEffectBackground())
    }
}

// MARK: - Native Divider

struct PopoverDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Profile Switcher Compact (for header)

struct ProfileSwitcherCompact: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var isHovered = false
    let onManageProfiles: () -> Void

    var body: some View {
        Menu {
            ForEach(profileManager.profiles) { profile in
                Button(action: {
                    Task {
                        await profileManager.activateProfile(profile.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 12))

                        Text(profile.name)
                            .font(.system(size: 12, weight: .medium))

                        Spacer()

                        HStack(spacing: 4) {
                            if profile.hasCliAccount {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.adaptiveGreen)
                            }

                            if profile.claudeSessionKey != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                            }

                            if profile.id == profileManager.activeProfile?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }

            Divider()

            Button(action: onManageProfiles) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                    Text("popover.manage_profiles".localized)
                        .font(.system(size: 12, weight: .medium))
                }
            }
        } label: {
            Text(profileManager.activeProfile?.name ?? "popover.no_profile".localized)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Switcher Bar

struct ProfileSwitcherBar: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var isHovered = false
    let onManageProfiles: () -> Void

    var body: some View {
        Menu {
            ForEach(profileManager.profiles) { profile in
                Button(action: {
                    Task {
                        await profileManager.activateProfile(profile.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 12))

                        Text(profile.name)
                            .font(.system(size: 12, weight: .medium))

                        Spacer()

                        HStack(spacing: 4) {
                            if profile.hasCliAccount {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.adaptiveGreen)
                            }

                            if profile.claudeSessionKey != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                            }

                            if profile.id == profileManager.activeProfile?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }

            Divider()

            Button(action: onManageProfiles) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                    Text("popover.manage_profiles".localized)
                        .font(.system(size: 12, weight: .medium))
                }
            }
        } label: {
            HStack(spacing: 8) {
                // Profile avatar
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)

                    Text(profileInitials)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(profileManager.activeProfile?.name ?? "popover.no_profile".localized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if profileManager.profiles.count > 1 {
                            Text(String(format: "popover.profiles_count".localized, profileManager.profiles.count))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("popover.profile_count_singular".localized)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("common.switch".localized)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            )
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var profileInitials: String {
        guard let name = profileManager.activeProfile?.name else { return "?" }
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Smart Header Component
struct SmartHeader: View {
    let usage: ClaudeUsage
    let status: ClaudeStatus
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onManageProfiles: () -> Void
    let onPreferences: () -> Void
    var clickedProfileId: UUID? = nil

    @StateObject private var profileManager = ProfileManager.shared

    private var statusColor: Color {
        switch status.indicator.color {
        case .green: return .adaptiveGreen
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .gray: return .gray
        }
    }

    private var isMultiProfileMode: Bool {
        profileManager.displayMode == .multi
    }

    private var clickedProfile: Profile? {
        guard let id = clickedProfileId else { return nil }
        return profileManager.profiles.first { $0.id == id }
    }

    private func profileInitials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                ProfileSwitcherCompact(onManageProfiles: onManageProfiles)

                // Status
                Button(action: {
                    if let url = URL(string: "https://status.claude.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)

                        Text(status.description)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Click to open status.claude.com")
            }

            Spacer()

            HStack(alignment: .center, spacing: 2) {
                // Refresh
                HeaderIconButton(
                    icon: "arrow.clockwise",
                    isRefreshing: isRefreshing,
                    action: onRefresh
                )
                .disabled(isRefreshing)

                // Settings
                HeaderIconButton(
                    icon: "gearshape.fill",
                    fontSize: 12,
                    action: onPreferences
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Header Icon Button
struct HeaderIconButton: View {
    let icon: String
    var fontSize: CGFloat = 10.5
    var isRefreshing: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 10, height: 10)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: fontSize, weight: .medium))
                        .imageScale(.medium)
                }
            }
            .foregroundColor(isHovered ? .primary : .secondary)
            .frame(width: 24, height: 24, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Smart Usage Dashboard
struct SmartUsageDashboard: View {
    let usage: ClaudeUsage
    let apiUsage: APIUsage?
    @StateObject private var profileManager = ProfileManager.shared
    @ObservedObject private var peakHoursService = PeakHoursService.shared

    private var isPeakHours: Bool {
        SharedDataStore.shared.loadPeakHoursIndicatorEnabled() && peakHoursService.isPeakHours
    }

    private var showRemainingPercentage: Bool {
        if profileManager.displayMode == .multi {
            return profileManager.multiProfileConfig.showRemainingPercentage
        }
        return profileManager.activeProfile?.iconConfig.showRemainingPercentage ?? false
    }

    private var showTimeMarker: Bool {
        if profileManager.displayMode == .multi {
            return profileManager.multiProfileConfig.showTimeMarker
        }
        return profileManager.activeProfile?.iconConfig.showTimeMarker ?? true
    }

    private var usePaceColoring: Bool {
        if profileManager.displayMode == .multi {
            return profileManager.multiProfileConfig.usePaceColoring
        }
        return profileManager.activeProfile?.iconConfig.usePaceColoring ?? true
    }

    private var showPaceMarker: Bool {
        if profileManager.displayMode == .multi {
            return profileManager.multiProfileConfig.showPaceMarker
        }
        return profileManager.activeProfile?.iconConfig.showPaceMarker ?? true
    }

    private var timeDisplay: PopoverTimeDisplay {
        SharedDataStore.shared.loadPopoverTimeDisplay()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Primary: Session Usage
            UsageRow(
                title: "menubar.session_usage".localized,
                subtitle: "menubar.5_hour_window".localized,
                usedPercentage: usage.effectiveSessionPercentage,
                showRemaining: showRemainingPercentage,
                resetTime: usage.sessionResetTime,
                periodDuration: Constants.sessionWindow,
                showTimeMarker: showTimeMarker,
                showPaceMarker: showPaceMarker,
                usePaceColoring: usePaceColoring,
                timeDisplay: timeDisplay,
                isPeakHighlighted: isPeakHours
            )

            // All Models (Weekly)
            UsageRow(
                title: "menubar.all_models".localized,
                tag: "menubar.weekly".localized,
                subtitle: nil,
                usedPercentage: usage.weeklyPercentage,
                showRemaining: showRemainingPercentage,
                resetTime: usage.weeklyResetTime,
                periodDuration: Constants.weeklyWindow,
                showTimeMarker: showTimeMarker,
                showPaceMarker: showPaceMarker,
                usePaceColoring: usePaceColoring,
                timeDisplay: timeDisplay
            )

            if usage.opusWeeklyTokensUsed > 0 {
                UsageRow(
                    title: "menubar.opus_usage".localized,
                    tag: "menubar.weekly".localized,
                    subtitle: nil,
                    usedPercentage: usage.opusWeeklyPercentage,
                    showRemaining: showRemainingPercentage,
                    resetTime: nil,
                    periodDuration: nil
                )
            }

            if usage.sonnetWeeklyTokensUsed > 0 {
                UsageRow(
                    title: "menubar.sonnet_usage".localized,
                    subtitle: nil,
                    usedPercentage: usage.sonnetWeeklyPercentage,
                    showRemaining: showRemainingPercentage,
                    resetTime: usage.sonnetWeeklyResetTime,
                    periodDuration: nil,
                    timeDisplay: timeDisplay
                )
            }

            // Extra usage (cost-based)
            if let used = usage.costUsed, let limit = usage.costLimit, let currency = usage.costCurrency, limit > 0 {
                let usedPercentage = (used / limit) * 100.0
                UsageRow(
                    title: "menubar.extra_usage".localized,
                    subtitle: String(format: "%.2f / %.2f %@", used / 100.0, limit / 100.0, currency),
                    usedPercentage: usedPercentage,
                    showRemaining: showRemainingPercentage,
                    resetTime: nil,
                    periodDuration: nil
                )

                // Overage credit grant balance
                if let balance = usage.overageBalance, let balanceCurrency = usage.overageBalanceCurrency {
                    HStack {
                        Text("popover.overage_balance".localized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f %@", balance / 100.0, balanceCurrency.uppercased()))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.adaptiveGreen)
                    }
                }
            }

            // API Usage
            if let apiUsage = apiUsage {
                APIUsageCard(apiUsage: apiUsage, showRemaining: showRemainingPercentage, timeDisplay: timeDisplay)

                // API Cost Card (only if cost data is available)
                if let costCents = apiUsage.apiTokenCostCents, costCents > 0 {
                    APICostCard(apiUsage: apiUsage)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Usage Row (flat, native style)
struct UsageRow: View {
    let title: String
    var tag: String? = nil
    let subtitle: String?
    let usedPercentage: Double
    let showRemaining: Bool
    let resetTime: Date?
    let periodDuration: TimeInterval?
    var showTimeMarker: Bool = true
    var showPaceMarker: Bool = true
    var usePaceColoring: Bool = true
    var timeDisplay: PopoverTimeDisplay = .resetTime
    var isPeakHighlighted: Bool = false

    private var displayPercentage: Double {
        UsageStatusCalculator.getDisplayPercentage(
            usedPercentage: usedPercentage,
            showRemaining: showRemaining
        )
    }

    private var rawElapsedFraction: Double? {
        UsageStatusCalculator.elapsedFraction(
            resetTime: resetTime,
            duration: periodDuration ?? 0,
            showRemaining: false
        )
    }

    private var timeMarkerFraction: CGFloat? {
        guard showTimeMarker, let f = rawElapsedFraction else { return nil }
        return CGFloat(showRemaining ? 1.0 - f : f)
    }

    private var paceStatus: PaceStatus? {
        guard showPaceMarker, let elapsed = rawElapsedFraction else { return nil }
        return PaceStatus.calculate(usedPercentage: usedPercentage, elapsedFraction: elapsed)
    }

    private var timeMarkerColor: Color {
        if let pace = paceStatus {
            return pace.swiftUIColor
        }
        return Color(nsColor: .labelColor)
    }

    private var statusLevel: UsageStatusLevel {
        UsageStatusCalculator.calculateStatus(
            usedPercentage: usedPercentage,
            showRemaining: showRemaining,
            elapsedFraction: usePaceColoring ? rawElapsedFraction : nil
        )
    }

    private var statusColor: Color {
        switch statusLevel {
        case .safe: return .adaptiveGreen
        case .moderate: return .orange
        case .critical: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Title row with percentage
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        if let tag = tag {
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                )
                        }
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("\(Int(displayPercentage))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(statusColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(displayPercentage / 100.0, 1.0))
                        .animation(.easeInOut(duration: 0.6), value: displayPercentage)
                }
                .overlay(alignment: .leading) {
                    if let fraction = timeMarkerFraction {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(timeMarkerColor)
                            .frame(width: 2.5, height: 8)
                            .offset(x: round(geometry.size.width * fraction) - 0.75)
                    }
                }
            }
            .frame(height: 4)

            // Reset time
            if let reset = resetTime {
                Text(resetTimeText(for: reset))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isPeakHighlighted ? Color.red.opacity(0.6) : Color.primary.opacity(0.1),
                    lineWidth: isPeakHighlighted ? 1.5 : 0.5
                )
        )
    }

    private func resetTimeText(for reset: Date) -> String {
        switch timeDisplay {
        case .resetTime:
            return "menubar.resets_time".localized(with: reset.resetTimeString())
        case .remainingTime:
            return "menubar.resets_in".localized(with: reset.timeRemainingString())
        case .both:
            return "menubar.resets_both".localized(with: reset.timeRemainingString(), reset.resetTimeString())
        }
    }
}

// MARK: - Contextual Insights
struct ContextualInsights: View {
    let usage: ClaudeUsage

    private var insights: [Insight] {
        var result: [Insight] = []

        if usage.effectiveSessionPercentage > 80 {
            result.append(Insight(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "usage.high_session".localized,
                description: "usage.high_session.desc".localized
            ))
        }

        if usage.weeklyPercentage > 90 {
            result.append(Insight(
                icon: "clock.fill",
                color: .red,
                title: "usage.weekly_approaching".localized,
                description: "usage.weekly_approaching.desc".localized
            ))
        }

        if usage.effectiveSessionPercentage < 20 && usage.weeklyPercentage < 30 {
            result.append(Insight(
                icon: "checkmark.circle.fill",
                color: .adaptiveGreen,
                title: "usage.efficient".localized,
                description: "usage.efficient.desc".localized
            ))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(insights, id: \.title) { insight in
                HStack(spacing: 8) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 11))
                        .foregroundColor(insight.color)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(insight.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)

                        Text(insight.description)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Insight {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

// MARK: - Smart Footer
struct SmartFooter: View {
    let usage: ClaudeUsage
    let status: ClaudeStatus
    @Binding var showInsights: Bool
    let onPreferences: () -> Void

    var body: some View {
        HStack {
            Spacer()
            SmartActionButton(
                icon: "gearshape.fill",
                title: "common.settings".localized,
                action: onPreferences
            )
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Claude Status Row
struct ClaudeStatusRow: View {
    let status: ClaudeStatus
    @State private var isHovered = false

    private var statusColor: Color {
        switch status.indicator.color {
        case .green: return .adaptiveGreen
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .gray: return .gray
        }
    }

    var body: some View {
        Button(action: {
            if let url = URL(string: "https://status.claude.com") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(status.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .help("Click to open status.claude.com")
    }
}

// MARK: - Smart Action Button (kept for backward compatibility)
struct SmartActionButton: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 12)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isDestructive ? .red : (isHovered ? .primary : .secondary))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - API Cost Card
struct APICostCard: View {
    let apiUsage: APIUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("API Cost")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text("This Month")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Total cost
                if let formatted = apiUsage.formattedAPICost {
                    Text(formatted)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }

            // Daily cost chart
            DailyCostChart(dailyCosts: apiUsage.sortedDailyCosts, currency: apiUsage.currency)

            // Per-key breakdown (if multiple sources) or flat model list
            if apiUsage.hasMultipleSources {
                VStack(spacing: 6) {
                    ForEach(apiUsage.sortedCostSources) { source in
                        APICostSourceRow(source: source, currency: apiUsage.currency)
                    }
                }
            } else {
                // Single source or no source data — show flat model breakdown
                let models = apiUsage.sortedModelCosts
                if !models.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(models, id: \.model) { item in
                            HStack {
                                Text(item.model)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)

                                Spacer()

                                Text(item.cost)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Daily Cost Chart
struct DailyCostChart: View {
    let dailyCosts: [(date: Date, cents: Double)]
    let currency: String

    private struct DayCost: Identifiable {
        let id: Date
        let dollars: Double
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private var xDomain: ClosedRange<Date> {
        let cal = Calendar.current
        let today = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        // End of today (start of tomorrow)
        let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: today))!
        return startOfMonth ... endOfToday
    }

    var body: some View {
        if !dailyCosts.isEmpty {
            let data = dailyCosts.map { DayCost(id: $0.date, dollars: $0.cents / 100.0) }
            let maxValue = data.map(\.dollars).max() ?? 0
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.id, unit: .day),
                    y: .value("Cost", item.dollars),
                    width: .fixed(12)
                )
                .foregroundStyle(Color.orange.opacity(0.75))
                .cornerRadius(2)
            }
            .chartXScale(domain: xDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 7))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.secondary.opacity(0.15))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(formatDollars(v, max: maxValue))
                                .font(.system(size: 7, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
            }
            .chartYScale(domain: 0 ... max(maxValue * 1.15, 0.01))
            .frame(height: 80)
        }
    }

    private func formatDollars(_ amount: Double, max: Double) -> String {
        if max >= 100 {
            return "$\(Int(amount))"
        } else if max >= 1 {
            return String(format: "$%.1f", amount)
        } else {
            return String(format: "$%.2f", amount)
        }
    }
}

// MARK: - API Cost Source Row
struct APICostSourceRow: View {
    let source: APICostSource
    let currency: String
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 4) {
            // Source header (tappable to expand)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: source.sourceType.icon)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    Text(source.keyName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(source.formattedTotal(currency: currency))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)

            // Expanded model breakdown
            if isExpanded {
                let models = source.sortedModelCosts(currency: currency)
                VStack(spacing: 3) {
                    ForEach(models, id: \.model) { item in
                        HStack {
                            Text(item.model)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            Spacer()

                            Text(item.cost)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - API Usage Card
struct APIUsageCard: View {
    let apiUsage: APIUsage
    let showRemaining: Bool
    var timeDisplay: PopoverTimeDisplay = .resetTime

    private var displayPercentage: Double {
        UsageStatusCalculator.getDisplayPercentage(
            usedPercentage: apiUsage.usagePercentage,
            showRemaining: showRemaining
        )
    }

    private var statusLevel: UsageStatusLevel {
        UsageStatusCalculator.calculateStatus(
            usedPercentage: apiUsage.usagePercentage,
            showRemaining: showRemaining
        )
    }

    private var usageColor: Color {
        switch statusLevel {
        case .safe: return .adaptiveGreen
        case .moderate: return .orange
        case .critical: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("menubar.api_credits".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text("menubar.anthropic_console".localized)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(displayPercentage))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(usageColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(usageColor)
                        .frame(width: geometry.size.width * min(displayPercentage / 100.0, 1.0))
                        .animation(.easeInOut(duration: 0.6), value: displayPercentage)
                }
            }
            .frame(height: 4)

            // Used / Remaining
            HStack {
                Text(apiUsage.formattedUsed)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Text(apiUsage.formattedRemaining)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Reset Time
            if apiUsage.resetsAt > Date() {
                Text(resetTimeText(for: apiUsage.resetsAt))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func resetTimeText(for reset: Date) -> String {
        switch timeDisplay {
        case .resetTime:
            return "menubar.resets_time".localized(with: reset.resetTimeString())
        case .remainingTime:
            return "menubar.resets_in".localized(with: reset.timeRemainingString())
        case .both:
            return "menubar.resets_both".localized(with: reset.timeRemainingString(), reset.resetTimeString())
        }
    }
}

// MARK: - Status Banner View
struct StatusBannerView: View {
    let icon: String
    let message: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(6)
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .onTapGesture { onTap?() }
    }
}

// MARK: - Burn Rate Card (Pro)

struct BurnRateCard: View {
    let usage: ClaudeUsage
    let profileId: UUID
    @State private var prediction: BurnRatePrediction?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)

                Text("Burn Rate")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if let prediction = prediction, prediction.isReliable {
                    Image(systemName: prediction.trend.icon)
                        .font(.system(size: 10))
                        .foregroundColor(trendColor(prediction.trend))
                }
            }

            if let prediction = prediction {
                if prediction.isReliable, let minutes = prediction.minutesToLimit {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Hit limit in")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text(prediction.timeToLimitText)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(minutes < 15 ? .red : .orange)
                    }

                    Text(prediction.trend.description)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                } else {
                    Text(prediction.timeToLimitText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Calculating...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .onAppear {
            prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
        }
        .onChange(of: usage.sessionTokensUsed) { _, _ in
            prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
        }
    }

    private func trendColor(_ trend: BurnTrend) -> Color {
        switch trend {
        case .accelerating: return .red
        case .steady: return .orange
        case .decelerating: return .green
        case .unknown: return .secondary
        }
    }
}

// MARK: - Cost Transparency Card (Pro)

struct CostTransparencyCard: View {
    let breakdown: CostBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)

                Text("API Cost Equivalent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(breakdown.formattedTotalCost)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("today at API rates")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if let savings = breakdown.formattedSavings {
                Text("Saved \(savings) vs API pricing today")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }
}

// MARK: - Conversation Breakdown Card (Pro)

struct ConversationBreakdownCard: View {
    let breakdown: SessionConversationBreakdown
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.cyan)

                    Text("This Session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(breakdown.conversations.count) interactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(breakdown.sortedByCost.prefix(5)) { conversation in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(conversation.isHighCost ? Color.red.opacity(0.6) : Color.cyan.opacity(0.4))
                                .frame(width: 6, height: 6)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(conversation.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)

                                Text("\(conversation.tokensUsed.formatted()) tokens")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if conversation.isHighCost {
                                Text("\(Int(conversation.percentageOfSession))%")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.03))
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }
}

// MARK: - Context Window Card (Pro)

struct ContextWindowCard: View {
    let usage: ContextWindowUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "window.horizontal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.purple)

                Text("Context Window")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(usage.usagePercentage))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(usage.isCritical ? .red : (usage.isNearCompaction ? .orange : .purple))

                Text("(\(usage.currentTokens.formatted()) / 200K tokens)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if let warning = ContextWindowTracker.shared.contextWarning(usage: usage) {
                Text(warning)
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.purple.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }
}

// MARK: - Predictive Throttling Card (Pro)

struct PredictiveThrottlingCard: View {
    let prediction: ThrottlingPrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)

                Text("Usage Forecast")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text(prediction.advice)
                .font(.system(size: 10))
                .foregroundColor(prediction.willHitSessionLimit || prediction.willHitWeeklyLimit ? .orange : .secondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }
}

// MARK: - Multi-AI Dashboard (Pro)

struct MultiAIDashboard: View {
    let profile: Profile
    @State private var isExpanded = true

    private var providers: [(AIProvider, (any ProviderUsage)?)] {
        AIProvider.allCases.compactMap { provider in
            guard profile.configuredProviders.contains(provider) else { return nil }
            return (provider, profile.usage(for: provider))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("All Providers")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(providers.count) connected")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(providers, id: \.0) { provider, usage in
                        ProviderUsageRow(provider: provider, usage: usage)
                    }
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

struct ProviderUsageRow: View {
    let provider: AIProvider
    let usage: (any ProviderUsage)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: provider.icon)
                .font(.system(size: 11))
                .foregroundColor(provider.brandColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(provider.shortName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)

                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            providerMetrics
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
    }

    private var subtitleText: String? {
        guard let usage = usage else { return nil }

        switch provider {
        case .claude:
            return nil
        case .codex:
            if let codex = usage as? CodexUsage, let model = codex.model {
                return model
            }
            return nil
        case .gemini:
            if let gemini = usage as? GeminiUsage {
                if gemini.isFreeTier == true { return "Free tier" }
                if let model = gemini.model { return model }
            }
            return nil
        case .copilot:
            if let copilot = usage as? CopilotUsage, let plan = copilot.planType {
                return plan.displayName
            }
            return nil
        case .kimi:
            if let kimi = usage as? KimiUsage, let model = kimi.model { return model }
            return nil
        case .deepseek:
            if let ds = usage as? DeepSeekUsage {
                if let balance = ds.balance { return "Balance: $\(String(format: "%.2f", balance))" }
                if let model = ds.model { return model }
            }
            return nil
        case .glm:
            if let glm = usage as? GLMUsage, let model = glm.model { return model }
            return nil
        case .qwen:
            if let qwen = usage as? QwenUsage, let model = qwen.model { return model }
            return nil
        case .minimax:
            if let mm = usage as? MiniMaxUsage, let group = mm.groupId { return "Group: \(group)" }
            return nil
        }
    }

    @ViewBuilder
    private var providerMetrics: some View {
        if let usage = usage, usage.isValid {
            VStack(alignment: .trailing, spacing: 1) {
                switch provider {
                case .claude:
                    EmptyView()
                case .codex:
                    codexMetrics(usage)
                case .gemini:
                    geminiMetrics(usage)
                case .copilot:
                    copilotMetrics(usage)
                case .kimi:
                    genericConnectedMetrics(usage)
                case .deepseek:
                    deepseekMetrics(usage)
                case .glm:
                    genericConnectedMetrics(usage)
                case .qwen:
                    genericConnectedMetrics(usage)
                case .minimax:
                    genericConnectedMetrics(usage)
                }
            }
        } else {
            Text("No data")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private func codexMetrics(_ usage: any ProviderUsage) -> some View {
        let codex = usage as? CodexUsage
        return Group {
            if let cost = usage.estimatedCost, cost > 0 {
                Text("$\(String(format: "%.2f", cost))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            } else if usage.tokensUsed > 0 {
                Text("\(usage.tokensUsed.formatted()) tokens")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else if codex != nil {
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }

    private func geminiMetrics(_ usage: any ProviderUsage) -> some View {
        let gemini = usage as? GeminiUsage
        return Group {
            if let requests = gemini?.requestsCount, requests > 0 {
                Text("\(requests.formatted()) requests")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else if gemini?.isFreeTier == true {
                Text("Free tier")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            } else {
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }

    private func copilotMetrics(_ usage: any ProviderUsage) -> some View {
        let copilot = usage as? CopilotUsage
        return Group {
            if let accepted = copilot?.suggestionsAccepted, let shown = copilot?.suggestionsShown, shown > 0 {
                let rate = Double(accepted) / Double(shown) * 100
                Text("\(Int(rate))% acceptance")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else if let cost = usage.estimatedCost, cost > 0 {
                Text("$\(String(format: "%.2f", cost))/mo")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else if copilot != nil {
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }

    private func deepseekMetrics(_ usage: any ProviderUsage) -> some View {
        let ds = usage as? DeepSeekUsage
        return Group {
            if let balance = ds?.balance, balance > 0 {
                Text("$\(String(format: "%.2f", balance))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            } else {
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }

    private func genericConnectedMetrics(_ usage: any ProviderUsage) -> some View {
        Group {
            if usage.tokensUsed > 0 {
                Text("\(usage.tokensUsed.formatted()) tokens")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }

    private func usageColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<50: return .adaptiveGreen
        case 50..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Pro Upsell Banner (Free Tier)

struct ProUpsellBanner: View {
    let usage: ClaudeUsage
    @State private var isHovered = false

    private var shouldShow: Bool {
        // Show when usage > 60% or always as a gentle upsell
        usage.effectiveSessionPercentage > 60 || usage.weeklyPercentage > 50
    }

    private var message: String {
        if usage.effectiveSessionPercentage >= 90 {
            return "Pro shows time-to-limit prediction. Upgrade to never be surprised again."
        } else if usage.effectiveSessionPercentage >= 75 {
            return "Pro users get burn rate predictions and cost transparency."
        } else {
            return "Upgrade to Pro for predictions, cost tracking, and unlimited profiles."
        }
    }

    var body: some View {
        if shouldShow {
            Button(action: {
                if let url = LicenseManager.shared.proCheckoutURL {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(message)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.purple.opacity(0.15), lineWidth: 0.5)
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.purple.opacity(0.04) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .padding(.horizontal, 10)
        }
    }
}
