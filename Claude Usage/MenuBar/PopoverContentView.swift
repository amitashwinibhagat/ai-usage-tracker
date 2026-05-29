import SwiftUI

// MARK: - Always-active vibrancy background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.isEmphasized = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effectView)

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

// MARK: - Native Divider

struct PopoverDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Profile Switcher Compact (header dropdown)

struct ProfileSwitcherCompact: View {
    @StateObject private var profileManager = ProfileManager.shared
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
                    .fill(isHovered ? AppTheme.Colors.elevated : Color.clear)
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

// MARK: - Simplified Header (no status dot)

struct SimpleHeader: View {
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onManageProfiles: () -> Void
    let onPreferences: () -> Void

    var body: some View {
        HStack {
            ProfileSwitcherCompact(onManageProfiles: onManageProfiles)

            Spacer()

            HStack(alignment: .center, spacing: 2) {
                HeaderIconButton(
                    icon: "arrow.clockwise",
                    isRefreshing: isRefreshing,
                    action: onRefresh
                )
                .disabled(isRefreshing)

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

// MARK: - Status Banner

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

// MARK: - Popover Content (5-Card Layout)

struct PopoverContentView: View {
    @ObservedObject var manager: MenuBarManager
    let onRefresh: () -> Void
    let onPreferences: () -> Void

    @State private var isRefreshing = false
    @StateObject private var profileManager = ProfileManager.shared

    private var displayUsage: ClaudeUsage {
        manager.clickedProfileUsage ?? manager.usage
    }

    private var displayAPIUsage: APIUsage? {
        if manager.clickedProfileUsage != nil {
            return manager.clickedProfileAPIUsage
        }
        return manager.apiUsage
    }

    private var activeProfile: Profile? {
        profileManager.activeProfile
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SimpleHeader(
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
                    onPreferences: onPreferences
                )

                PopoverDivider()

                // Error banners
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

                // Multi-profile viewing tag
                if profileManager.displayMode == .multi,
                   let viewingProfile = manager.clickedProfileId.flatMap({ id in
                       profileManager.profiles.first(where: { $0.id == id })
                   }) ?? profileManager.activeProfile {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 20, height: 20)
                            Text(profileInitials(for: viewingProfile.name))
                                .font(AppTheme.Typography.nanoBold)
                                .foregroundColor(.accentColor)
                        }

                        Text(viewingProfile.name)
                            .font(AppTheme.Typography.captionSemibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        if viewingProfile.id == profileManager.activeProfile?.id {
                            Text("Active")
                                .font(AppTheme.Typography.nanoSemibold)
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
                        RoundedRectangle(cornerRadius: AppTheme.Radius.compact)
                            .fill(AppTheme.Colors.card)
                    )
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                }

                // Card 1: Usage Ring
                UsageRingCard(usage: displayUsage, apiUsage: displayAPIUsage)
                    .padding(.top, 6)

                PopoverDivider()

                // Card 2: Reset Countdown
                ResetCountdownCard(usage: displayUsage)

                PopoverDivider()
                    .padding(.top, 6)

                // Card 3: Burn Rate (conditional)
                if shouldShowBurnRateCard {
                    if let profile = activeProfile {
                        BurnRateCard(usage: displayUsage, profileId: profile.id)
                    }
                    PopoverDivider()
                        .padding(.top, 6)
                }

                // Card 4: Contextual Tip
                if let profile = activeProfile {
                    ContextualTipCard(profile: profile, usage: displayUsage)
                    PopoverDivider()
                        .padding(.top, 6)
                }

                // Card 5: Details Disclosure
                DetailsDisclosure(
                    usage: displayUsage,
                    apiUsage: displayAPIUsage,
                    manager: manager
                )
                .padding(.top, 6)

                // Footer: Settings
                HStack {
                    Spacer()
                    Button(action: onPreferences) {
                        HStack(spacing: 5) {
                            Image(systemName: "gearshape.fill")
                                .font(AppTheme.Typography.tinyMedium)
                            Text("common.settings".localized)
                                .font(AppTheme.Typography.captionMedium)
                        }
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.vertical, 6)

            }
            .padding(.bottom, 8)
        }
        .frame(width: 320)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var shouldShowBurnRateCard: Bool {
        if FeatureFlags.shared.isProOrHigher {
            return true
        }
        return displayUsage.effectiveSessionPercentage > 50
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
}
