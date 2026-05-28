//
//  ManageProfilesView.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-07.
//

import SwiftUI

struct ManageProfilesView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingCreateProfile = false
    @State private var newProfileName = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Page Header
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

                profileCapacityCard

                SettingsContentCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        ForEach(profileManager.profiles) { profile in
                            ProfileRow(profile: profile)
                        }
                    }
                }

                if profileManager.canCreateProfile {
                    SettingsButton.primary(
                        title: "profiles.create_new".localized,
                        icon: "plus.circle.fill"
                    ) {
                        showingCreateProfile = true
                    }
                } else {
                    ProUpsellCard(
                        title: "Upgrade to Pro for Unlimited Profiles",
                        message: "You've reached the free limit of 2 profiles. Pro removes profile limits so every account, client, and API key can be tracked separately.",
                        actionTitle: "Upgrade for $4.99/mo"
                    ) {
                        if let url = LicenseManager.shared.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                // Multi-Profile Display Section
                SettingsSectionCard(
                    title: "multiprofile.title".localized,
                    subtitle: "multiprofile.subtitle".localized
                ) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.cardPadding) {
                        // Main toggle
                        SettingToggle(
                            title: "multiprofile.enable_title".localized,
                            description: "multiprofile.enable_description".localized,
                            badge: .new,
                            isOn: Binding(
                                get: { profileManager.displayMode == .multi },
                                set: { enabled in
                                    profileManager.updateDisplayMode(enabled ? .multi : .single)
                                    // Post notification for menu bar to update
                                    NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                                }
                            )
                        )

                        // Profile selection (visible when multi-profile is ON)
                        if profileManager.displayMode == .multi {
                            Divider()

                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                                Text("multiprofile.select_profiles".localized)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(.secondary)

                                ForEach(profileManager.profiles) { profile in
                                    ProfileSelectionRow(
                                        profile: profile,
                                        isSelected: profile.isSelectedForDisplay,
                                        isActive: profileManager.activeProfile?.id == profile.id,
                                        onToggle: {
                                            // Ensure at least one profile stays selected
                                            let selectedCount = profileManager.profiles.filter { $0.isSelectedForDisplay }.count
                                            if profile.isSelectedForDisplay && selectedCount <= 1 {
                                                // Can't deselect the last one
                                                return
                                            }
                                            profileManager.toggleProfileSelection(profile.id)
                                            // Post notification for menu bar to update (incremental, not full recreate)
                                            NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                        }
                                    )
                                }

                                // Warning if trying to deselect last profile
                                if profileManager.profiles.filter({ $0.isSelectedForDisplay }).count == 1 {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                        Text("multiprofile.at_least_one".localized)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            Divider()
                                .padding(.vertical, DesignTokens.Spacing.small)

                            // Icon Style Picker
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                                Text("multiprofile.icon_style".localized)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(.secondary)

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
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Show Week Toggle
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

                            // Show Profile Label Toggle
                            SettingToggle(
                                title: "multiprofile.show_label".localized,
                                description: "multiprofile.show_label_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.showProfileLabel },
                                    set: { showLabel in
                                        var config = profileManager.multiProfileConfig
                                        config.showProfileLabel = showLabel
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Use System Color Toggle
                            SettingToggle(
                                title: "multiprofile.use_system_color".localized,
                                description: "multiprofile.use_system_color_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.useSystemColor },
                                    set: { useSystemColor in
                                        var config = profileManager.multiProfileConfig
                                        config.useSystemColor = useSystemColor
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Show Time Marker Toggle
                            SettingToggle(
                                title: "appearance.show_time_marker_title".localized,
                                description: "appearance.show_time_marker_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.showTimeMarker },
                                    set: { showMarker in
                                        var config = profileManager.multiProfileConfig
                                        config.showTimeMarker = showMarker
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Pace Marker Toggle
                            SettingToggle(
                                title: "appearance.show_pace_marker_title".localized,
                                description: "appearance.show_pace_marker_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.showPaceMarker },
                                    set: { showPace in
                                        var config = profileManager.multiProfileConfig
                                        config.showPaceMarker = showPace
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Pace-Aware Bar Colors Toggle
                            SettingToggle(
                                title: "appearance.pace_coloring_title".localized,
                                description: "appearance.pace_coloring_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.usePaceColoring },
                                    set: { usePace in
                                        var config = profileManager.multiProfileConfig
                                        config.usePaceColoring = usePace
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Show Remaining Percentage Toggle
                            SettingToggle(
                                title: "appearance.show_remaining_title".localized,
                                description: "appearance.show_remaining_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.showRemainingPercentage },
                                    set: { showRemaining in
                                        var config = profileManager.multiProfileConfig
                                        config.showRemainingPercentage = showRemaining
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Show Active Profile Indicator Toggle
                            SettingToggle(
                                title: "multiprofile.active_indicator_title".localized,
                                description: "multiprofile.active_indicator_description".localized,
                                isOn: Binding(
                                    get: { profileManager.multiProfileConfig.showActiveProfileIndicator },
                                    set: { showIndicator in
                                        var config = profileManager.multiProfileConfig
                                        config.showActiveProfileIndicator = showIndicator
                                        profileManager.updateMultiProfileConfig(config)
                                        NotificationCenter.default.post(name: .multiProfileConfigChanged, object: nil)
                                    }
                                )
                            )

                            // Info message
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                                Text("multiprofile.info".localized)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, DesignTokens.Spacing.small)
                        }
                    }
                }

                // Auto-Switch Profile Section
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

                // Info Card
                SettingsContentCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                        HStack(spacing: DesignTokens.Spacing.small) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: DesignTokens.Icons.standard))
                            Text("profiles.about_title".localized)
                                .font(DesignTokens.Typography.sectionTitle)
                        }

                        Text("profiles.about_description".localized)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                            BulletPoint("profiles.about_credentials".localized)
                            BulletPoint("profiles.about_api".localized)
                            BulletPoint("profiles.about_cli".localized)
                            BulletPoint("profiles.about_appearance".localized)
                            BulletPoint("profiles.about_notifications".localized)
                            BulletPoint("profiles.about_refresh".localized)
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, DesignTokens.Spacing.small)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 11))
                }
            }
            .padding()
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

    private func createNewProfile() {
        let name = newProfileName.isEmpty ? nil : newProfileName
        let profile = profileManager.createProfile(name: name)
        if profile == nil {
            errorMessage = "Profile limit reached. Upgrade to Pro for unlimited profiles."
        }
        showingCreateProfile = false
        newProfileName = ""
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: Profile
    @StateObject private var profileManager = ProfileManager.shared
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isActive ? AppTheme.Colors.accentMuted : AppTheme.Colors.elevated.opacity(0.75))
                    .frame(width: 42, height: 42)

                Image(systemName: profile.hasCliAccount ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(isActive ? AppTheme.Colors.accentHover : AppTheme.Colors.textMuted)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                if isEditing {
                    TextField("Profile Name", text: $editedName, onCommit: {
                        saveProfileName()
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if isActive {
                            Text("profiles.active_badge".localized)
                                .font(AppTheme.Typography.badge)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.accentMuted)
                                .clipShape(Capsule())
                        }
                    }
                }

                Text(profileInfo)
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if !isEditing {
                    // Rename Button
                    Button(action: {
                        editedName = profile.name
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .font(AppTheme.Typography.smallMedium)
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("profiles.rename".localized)

                    // Activate Button (if not active)
                    if profileManager.activeProfile?.id != profile.id {
                        Button(action: {
                            Task {
                                await profileManager.activateProfile(profile.id)
                            }
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(AppTheme.Typography.smallMedium)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                        .buttonStyle(.plain)
                        .help("profiles.activate".localized)
                    }

                    // Delete Button (if not the last profile)
                    if profileManager.profiles.count > 1 {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(AppTheme.Typography.smallMedium)
                                .foregroundColor(AppTheme.Colors.error)
                        }
                        .buttonStyle(.plain)
                        .help("profiles.delete".localized)
                    }
                } else {
                    // Save Button
                    Button(action: {
                        saveProfileName()
                    }) {
                        Image(systemName: "checkmark")
                            .font(AppTheme.Typography.smallMedium)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    .buttonStyle(.plain)

                    // Cancel Button
                    Button(action: {
                        isEditing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(AppTheme.Typography.smallMedium)
                            .foregroundColor(AppTheme.Colors.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(isActive ? AppTheme.Colors.accentMuted.opacity(0.6) : AppTheme.Colors.backgroundDeep.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(isActive ? AppTheme.Colors.accent.opacity(0.35) : AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
        )
        .alert("profiles.delete_title".localized, isPresented: $showingDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                deleteProfile()
            }
        } message: {
            Text(String(format: "profiles.delete_confirm".localized, profile.name))
        }
    }

    private var isActive: Bool {
        profileManager.activeProfile?.id == profile.id
    }

    private var profileInfo: String {
        var parts: [String] = []

        if profile.hasCliAccount {
            parts.append("profiles.cli_synced".localized)
        }

        parts.append("\("profiles.created".localized) \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")

        return parts.joined(separator: " • ")
    }

    private func saveProfileName() {
        if !editedName.isEmpty && editedName != profile.name {
            var updated = profile
            updated.name = editedName
            profileManager.updateProfile(updated)
        }
        isEditing = false
    }

    private func deleteProfile() {
        do {
            try profileManager.deleteProfile(profile.id)
        } catch {
            // Error handled by ProfileManager
        }
    }
}

// MARK: - Create Profile Sheet

struct CreateProfileSheet: View {
    @Binding var profileName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("profiles.create_title".localized)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("profiles.name_label".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("profiles.name_placeholder".localized, text: $profileName)
                    .textFieldStyle(.roundedBorder)

                Text("profiles.name_hint".localized)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button("common.cancel".localized) {
                    onCancel()
                }
                .buttonStyle(.plain)

                Button("common.create".localized) {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
