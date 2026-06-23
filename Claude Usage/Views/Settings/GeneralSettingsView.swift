//
//  GeneralSettingsView.swift
//  Claude Usage - Consolidated General Settings
//
//  Merges: AppSettingsView, LanguageSettingsView, UpdatesSettingsView,
//          ClaudeCodeView, PopoverSettingsView, DebugNetworkLogView
//

import SwiftUI
import UserNotifications

struct GeneralSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var updateManager = UpdateManager.shared
    @State private var launchAtLogin = LaunchAtLoginManager.shared.isEnabled
    @State private var showRestartAlert = false
    @State private var showResetConfirmation = false
    @State private var autoUpdateEnabled: Bool = true
    @State private var peakHoursEnabled: Bool = SharedDataStore.shared.loadPeakHoursIndicatorEnabled()
    @State private var peakHoursMenuIconEnabled: Bool = SharedDataStore.shared.loadPeakHoursMenuIconEnabled()
    @State private var timeDisplay: PopoverTimeDisplay = SharedDataStore.shared.loadPopoverTimeDisplay()
    @State private var timeFormat: TimeFormatPreference = SharedDataStore.shared.loadTimeFormatPreference()
    @State private var showDeveloperTools = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "general.title".localized,
                    subtitle: "general.subtitle".localized
                )

                launchAtLoginCard

                if let profile = profileManager.activeProfile {
                    refreshIntervalCard(profile: profile)
                }

                peakHoursCard

                languageCard

                updatesCard

                popoverCard

                claudeCodeCard

                resetAppDataCard

                developerCard

                Spacer()
            }
            .padding(28)
        }
        .onChange(of: launchAtLogin) { _, newValue in
            LaunchAtLoginManager.shared.setEnabled(newValue)
        }
        .onChange(of: peakHoursEnabled) { _, newValue in
            SharedDataStore.shared.savePeakHoursIndicatorEnabled(newValue)
            NotificationCenter.default.post(name: .peakHoursSettingChanged, object: nil)
        }
        .onChange(of: peakHoursMenuIconEnabled) { _, newValue in
            SharedDataStore.shared.savePeakHoursMenuIconEnabled(newValue)
            NotificationCenter.default.post(name: .peakHoursSettingChanged, object: nil)
        }
        .onChange(of: timeDisplay) { _, newValue in
            SharedDataStore.shared.savePopoverTimeDisplay(newValue)
        }
        .onChange(of: timeFormat) { _, newValue in
            SharedDataStore.shared.saveTimeFormatPreference(newValue)
        }
        .onAppear {
            autoUpdateEnabled = updateManager.automaticChecksEnabled
        }
        .alert("general.language.restart_note".localized, isPresented: $showRestartAlert) {
            Button("language.restart_now".localized, role: .destructive) {
                restartApp()
            }
            Button("language.restart_later".localized, role: .cancel) { }
        } message: {
            Text("language.restart_message".localized)
        }
        .alert("about.reset_confirmation_title".localized, isPresented: $showResetConfirmation) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("about.reset_confirm".localized, role: .destructive) {
                resetAppData()
            }
        } message: {
            Text("about.reset_confirmation_message".localized)
        }
    }

    // MARK: - Launch at Login

    private var launchAtLoginCard: some View {
        SettingsSectionCard(
            title: "general.launch_at_login".localized,
            subtitle: "general.launch_at_login.description".localized
        ) {
            SettingToggle(
                title: "general.launch_at_login".localized,
                isOn: $launchAtLogin
            )
        }
    }

    // MARK: - Refresh Interval

    private func refreshIntervalCard(profile: Profile) -> some View {
        SettingsSectionCard(
            title: "general.refresh_title".localized,
            subtitle: "general.refresh_subtitle".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(String(format: "general.refresh_seconds".localized, Int(profile.refreshInterval)))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                }

                Slider(
                    value: Binding(
                        get: { profile.refreshInterval },
                        set: { newValue in
                            var updated = profile
                            updated.refreshInterval = newValue
                            profileManager.updateProfile(updated)
                        }
                    ),
                    in: 10...300,
                    step: 10
                )

                HStack {
                    Text("general.refresh_min".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                    Spacer()
                    Text("general.refresh_max".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
        }
    }

    // MARK: - Peak Hours

    private var peakHoursCard: some View {
        SettingsSectionCard(
            title: "popover.peak_hours".localized,
            subtitle: "popover.peak_hours_desc".localized(with: PeakHoursService.localTimeRangeString())
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SettingToggle(
                    title: "popover.peak_hours_toggle".localized,
                    description: "popover.peak_hours_toggle_desc".localized,
                    badge: .new,
                    isOn: $peakHoursEnabled
                )

                SettingToggle(
                    title: "popover.peak_hours_menu_icon".localized,
                    description: "popover.peak_hours_menu_icon_desc".localized,
                    isOn: $peakHoursMenuIconEnabled
                )
                .disabled(!peakHoursEnabled)
                .opacity(peakHoursEnabled ? 1.0 : 0.5)
                .padding(.leading, AppTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Language

    private var languageCard: some View {
        SettingsSectionCard(
            title: "language.title".localized,
            subtitle: "language.subtitle".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                ForEach(LanguageManager.SupportedLanguage.allCases) { language in
                    languageRow(language)
                }
            }
        }
    }

    private func languageRow(_ language: LanguageManager.SupportedLanguage) -> some View {
        let isSelected = languageManager.currentLanguage == language
        return Button(action: { selectLanguage(language) }) {
            HStack(spacing: AppTheme.Spacing.md) {
                Text(language.flag)
                    .font(.system(size: 24))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(language.englishName)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.accent)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .fill(isSelected ? AppTheme.Colors.accent.opacity(0.08) : AppTheme.Colors.backgroundDeep.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func selectLanguage(_ language: LanguageManager.SupportedLanguage) {
        guard language != languageManager.currentLanguage else { return }
        languageManager.currentLanguage = language
        showRestartAlert = true
    }

    // MARK: - Updates

    private var updatesCard: some View {
        SettingsSectionCard(
            title: "settings.updates".localized,
            subtitle: "settings.updates.description".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("settings.updates.current_version".localized)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("v\(appVersion) (\(buildNumber))")
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.Colors.backgroundDeep.opacity(0.45))
                )

                SettingToggle(
                    title: "settings.updates.automatic".localized,
                    description: "settings.updates.automatic.description".localized,
                    isOn: $autoUpdateEnabled
                )
                .onChange(of: autoUpdateEnabled) { _, newValue in
                    updateManager.setAutomaticChecksEnabled(newValue)
                }

                SettingsButton.primary(
                    title: "settings.updates.check_now".localized,
                    icon: "arrow.down.circle"
                ) {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)

                // BUG 5 from the click audit: surface the result of
                // the most recent check so the user knows whether
                // Sparkle did anything.
                if updateManager.lastCheckOutcome != .idle {
                    updateOutcomeBanner
                }
            }
        }
    }

    @ViewBuilder
    private var updateOutcomeBanner: some View {
        let (icon, text, tint) = updateOutcomeDetails
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(AppTheme.Typography.tiny)
            Spacer()
            Button(action: { updateManager.acknowledgeLastCheckOutcome() }) {
                Image(systemName: "xmark")
                    .font(AppTheme.Typography.tiny)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(tint)
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(tint.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var updateOutcomeDetails: (String, String, Color) {
        switch updateManager.lastCheckOutcome {
        case .idle, .checking:
            return ("hourglass", "Checking for updates…", AppTheme.Colors.textMuted)
        case .upToDate:
            return ("checkmark.circle.fill", "You’re on the latest version.", AppTheme.Colors.success)
        case .updateAvailable(let version):
            return ("arrow.down.circle.fill", "Update available: v\(version). Sparkle will install it.", AppTheme.Colors.accent)
        case .failed(let message):
            return ("exclamationmark.triangle.fill", "Update check failed: \(message)", AppTheme.Colors.warning)
        }
    }

    // MARK: - Popover Display

    private var popoverCard: some View {
        SettingsSectionCard(
            title: "section.popover_title".localized,
            subtitle: "section.popover_desc".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("popover.time_display".localized)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Picker("", selection: $timeDisplay) {
                        Text("popover.time_display_reset".localized).tag(PopoverTimeDisplay.resetTime)
                        Text("popover.time_display_remaining".localized).tag(PopoverTimeDisplay.remainingTime)
                        Text("popover.time_display_both".localized).tag(PopoverTimeDisplay.both)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("popover.time_format".localized)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Picker("", selection: $timeFormat) {
                        Text("popover.time_format_system".localized).tag(TimeFormatPreference.system)
                        Text("popover.time_format_12h".localized).tag(TimeFormatPreference.twelveHour)
                        Text("popover.time_format_24h".localized).tag(TimeFormatPreference.twentyFourHour)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
        }
    }

    // MARK: - Claude Code (condensed)

    private var claudeCodeCard: some View {
        SettingsSectionCard(
            title: "settings.claude_cli".localized,
            subtitle: "settings.claude_cli.description".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("claudecode.subtitle".localized)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                NavigationLink {
                    ClaudeCodeView()
                } label: {
                    HStack {
                        Text("claudecode.title".localized)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                            .fill(AppTheme.Colors.backgroundDeep.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                            .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    LimitOptimizationGuideView()
                } label: {
                    HStack {
                        Text("guide.title".localized)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                            .fill(AppTheme.Colors.backgroundDeep.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                            .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reset App Data

    private var resetAppDataCard: some View {
        SettingsSectionCard(
            title: "about.reset_app_data".localized,
            subtitle: "about.reset_confirmation_message".localized
        ) {
            SettingsButton.destructive(
                title: "about.reset_app_data".localized,
                icon: "trash"
            ) {
                showResetConfirmation = true
            }
        }
    }

    // MARK: - Developer Tools

    private var developerCard: some View {
        Group {
            if showDeveloperTools {
                SettingsSectionCard(
                    title: "section.debug_title".localized,
                    subtitle: "section.debug_desc".localized
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("debug.network_logger_desc".localized)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        NavigationLink {
                            DebugNetworkLogView()
                        } label: {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .font(AppTheme.Typography.smallSemibold)
                                    .foregroundColor(AppTheme.Colors.accent)
                                Text("debug.title".localized)
                                    .font(AppTheme.Typography.label)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppTheme.Typography.tinySemibold)
                                    .foregroundColor(AppTheme.Colors.textMuted)
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                                    .fill(AppTheme.Colors.backgroundDeep.opacity(0.45))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                                    .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func restartApp() {
        UserDefaults.standard.synchronize()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.5; open '\(Bundle.main.bundlePath)'"]
        task.launch()
        NSApplication.shared.terminate(nil)
    }

    private func resetAppData() {
        MigrationService.shared.resetAppData()
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
