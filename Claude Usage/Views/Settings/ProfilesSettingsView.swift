//
//  ProfilesSettingsView.swift
//  Claude Usage - Consolidated Profiles Settings
//
//  Merges: ManageProfilesView, general profile settings, UsageHistoryView
//

import SwiftUI

struct ProfilesSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingCreateProfile = false
    @State private var newProfileName = ""
    @State private var errorMessage: String?
    @State private var showingDateRangeExport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "profiles.title".localized,
                    subtitle: "profiles.subtitle".localized
                )

                ProductInsightCard(
                    icon: "person.2.wave.2.fill",
                    title: "Profiles are for separating work context",
                    message: "Use profiles for separate Claude accounts, client projects, API keys, or workflows so limits and costs stay understandable.",
                    color: AppTheme.Colors.info
                )

                profileSwitcherCard

                profileCapacityCard

                profileListCard

                SettingsButton.primary(
                    title: "profiles.create_new".localized,
                    icon: "plus.circle.fill"
                ) {
                    showingCreateProfile = true
                }

                multiProfileCard

                autoSwitchCard

                SettingsSectionCard(
                    title: "section.history_title".localized,
                    subtitle: "section.history_desc".localized
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        NavigationLink {
                            UsageHistoryView()
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(AppTheme.Typography.smallSemibold)
                                    .foregroundColor(AppTheme.Colors.accent)
                                Text("history.title".localized)
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

                        Button(action: { showingDateRangeExport = true }) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(AppTheme.Typography.smallSemibold)
                                    .foregroundColor(AppTheme.Colors.accent)
                                Text("Export with Date Range...")
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
                        .sheet(isPresented: $showingDateRangeExport) {
                            if let profileId = profileManager.activeProfile?.id {
                                DateRangeExportView(profileId: profileId)
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(AppTheme.Colors.error)
                        .font(AppTheme.Typography.small)
                }

                Spacer()
            }
            .padding(28)
        }
        .sheet(isPresented: $showingCreateProfile) {
            CreateProfileSheet(
                profileName: $newProfileName,
                onSave: {
                    createNewProfile()
                },
                onCancel: {
                    showingCreateProfile = false
                    newProfileName = ""
                }
            )
        }
    }

    // MARK: - Profile Switcher

    private var profileSwitcherCard: some View {
        SettingsContentCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("section.active_profile".localized)
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .textCase(.uppercase)

                if let active = profileManager.activeProfile {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accentMuted)
                                .frame(width: 36, height: 36)
                            Image(systemName: active.hasCliAccount ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.Colors.accentHover)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.name)
                                .font(AppTheme.Typography.label)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text(profileSummary(active))
                                .font(AppTheme.Typography.tiny)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { profileManager.activeProfile?.id ?? UUID() },
                            set: { newId in
                                Task { await profileManager.activateProfile(newId) }
                            }
                        )) {
                            ForEach(profileManager.profiles) { profile in
                                Text(profile.name).tag(profile.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.small)
                        .tint(AppTheme.Colors.accent)
                        .frame(width: 140)
                    }
                } else {
                    Text("No active profile")
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
        }
    }

    private func profileSummary(_ profile: Profile) -> String {
        var parts: [String] = []
        if profile.hasCliAccount { parts.append("profiles.cli_synced".localized) }
        if profile.hasUsageCredentials { parts.append("Claude.ai connected") }
        parts.append("\("profiles.created".localized) \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
        return parts.joined(separator: " • ")
    }

    // MARK: - Profile Capacity

    private var profileCapacityCard: some View {
        SettingsContentCard {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Profile capacity")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .textCase(.uppercase)

                    Text("\(profileManager.profiles.count) profiles active")
                        .font(AppTheme.Typography.sectionTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(profileManager.canCreateProfile ? "Add another profile when a new account or project needs separate tracking." : "Free tier profile capacity is full. Existing profiles remain usable.")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(profileManager.canCreateProfile ? "Ready" : "Limit")
                    .font(AppTheme.Typography.badge)
                    .foregroundColor(profileManager.canCreateProfile ? AppTheme.Colors.success : AppTheme.Colors.warning)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((profileManager.canCreateProfile ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.14))
                    )
            }
        }
    }

    // MARK: - Profile List

    private var profileListCard: some View {
        SettingsContentCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(profileManager.profiles) { profile in
                    ProfileRow(profile: profile)
                }
            }
        }
    }

    // MARK: - Multi-Profile Display

    private var multiProfileCard: some View {
        SettingsSectionCard(
            title: "multiprofile.title".localized,
            subtitle: "multiprofile.subtitle".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SettingToggle(
                    title: "multiprofile.enable_title".localized,
                    description: "multiprofile.enable_description".localized,
                    badge: .new,
                    isOn: Binding(
                        get: { profileManager.displayMode == .multi },
                        set: { enabled in
                            profileManager.updateDisplayMode(enabled ? .multi : .single)
                            NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                        }
                    )
                )

                if profileManager.displayMode == .multi {
                    Divider().overlay(AppTheme.Colors.divider)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("multiprofile.select_profiles".localized)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        ForEach(profileManager.profiles) { profile in
                            ProfileSelectionRow(
                                profile: profile,
                                isSelected: profile.isSelectedForDisplay,
                                isActive: profileManager.activeProfile?.id == profile.id,
                                onToggle: {
                                    let selectedCount = profileManager.profiles.filter { $0.isSelectedForDisplay }.count
                                    if profile.isSelectedForDisplay && selectedCount <= 1 { return }
                                    profileManager.toggleProfileSelection(profile.id)
                                    NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                }
                            )
                        }
                    }

                    Divider().overlay(AppTheme.Colors.divider)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("multiprofile.icon_style".localized)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Picker("", selection: Binding(
                            get: { profileManager.multiProfileConfig.iconStyle },
                            set: { newStyle in
                                var config = profileManager.multiProfileConfig
                                config.iconStyle = newStyle
                                profileManager.updateMultiProfileConfig(config)
                                NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                            }
                        )) {
                            ForEach(MultiProfileIconStyle.allCases, id: \.self) { style in
                                Text(style.shortNameKey.localized).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    SettingToggle(
                        title: "multiprofile.show_week".localized,
                        description: "multiprofile.show_week_description".localized,
                        isOn: Binding(
                            get: { profileManager.multiProfileConfig.showWeek },
                            set: { showWeek in
                                var config = profileManager.multiProfileConfig
                                config.showWeek = showWeek
                                profileManager.updateMultiProfileConfig(config)
                                NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                            }
                        )
                    )
                }
            }
        }
    }

    // MARK: - Auto-Switch

    private var autoSwitchCard: some View {
        SettingsSectionCard(
            title: "auto_switch.title".localized,
            subtitle: "auto_switch.subtitle".localized
        ) {
            SettingToggle(
                title: "auto_switch.enable_title".localized,
                description: "auto_switch.enable_description".localized,
                badge: .new,
                isOn: Binding(
                    get: { SharedDataStore.shared.loadAutoSwitchProfileEnabled() },
                    set: { enabled in
                        SharedDataStore.shared.saveAutoSwitchProfileEnabled(enabled)
                    }
                )
            )
        }
    }

    // MARK: - Actions

    private func createNewProfile() {
        let name = newProfileName.isEmpty ? nil : newProfileName
        do {
            try profileManager.createProfile(name: name)
        } catch {
            errorMessage = "profiles.create_failed".localized
        }
        showingCreateProfile = false
        newProfileName = ""
    }
}

#Preview {
    ProfilesSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
