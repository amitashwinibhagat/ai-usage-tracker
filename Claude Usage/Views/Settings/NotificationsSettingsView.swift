//
//  NotificationsSettingsView.swift
//  Claude Usage - Consolidated Notifications Settings
//
//  Merges: notification settings from GeneralSettingsView, SessionPlanningSettingsView
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared
    @StateObject private var planningService = SessionPlanningService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "Notifications",
                    subtitle: "Configure when and how the app alerts you about usage thresholds."
                )

                if let profile = profileManager.activeProfile {
                    notificationEnableCard(profile: profile)

                    if profile.notificationSettings.enabled {
                        thresholdsCard(profile: profile)

                        customThresholdsCard(profile: profile)

                        soundCard(profile: profile)

                        notificationPreviewCard(profile: profile)
                    }
                }

                if let profile = profileManager.activeProfile {
                    SessionPlanningSettingsView(profile: profile)
                }

                Spacer()
            }
            .padding(28)
        }
    }

    // MARK: - Enable Notifications

    private func notificationEnableCard(profile: Profile) -> some View {
        SettingsSectionCard(
            title: "notifications.enable".localized,
            subtitle: "notifications.enable.description".localized
        ) {
            SettingToggle(
                title: "notifications.enable".localized,
                description: "notifications.enable.description".localized,
                isOn: Binding(
                    get: { profile.notificationSettings.enabled },
                    set: { newValue in
                        var updated = profile
                        updated.notificationSettings.enabled = newValue
                        profileManager.updateProfile(updated)

                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                )
            )
        }
    }

    // MARK: - Thresholds

    private func thresholdsCard(profile: Profile) -> some View {
        SettingsSectionCard(
            title: "notifications.alert_thresholds".localized,
            subtitle: "Receive alerts when usage crosses these thresholds"
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ThresholdToggleRow(
                    level: "75%",
                    color: SettingsColors.usageMedium,
                    label: "notifications.threshold.warning".localized,
                    isOn: Binding(
                        get: { profile.notificationSettings.threshold75Enabled },
                        set: { newValue in
                            var updated = profile
                            updated.notificationSettings.threshold75Enabled = newValue
                            profileManager.updateProfile(updated)
                        }
                    )
                )
                ThresholdToggleRow(
                    level: "90%",
                    color: SettingsColors.usageHigh,
                    label: "notifications.threshold.high".localized,
                    isOn: Binding(
                        get: { profile.notificationSettings.threshold90Enabled },
                        set: { newValue in
                            var updated = profile
                            updated.notificationSettings.threshold90Enabled = newValue
                            profileManager.updateProfile(updated)
                        }
                    )
                )
                ThresholdToggleRow(
                    level: "95%",
                    color: SettingsColors.usageCritical,
                    label: "notifications.threshold.critical".localized,
                    isOn: Binding(
                        get: { profile.notificationSettings.threshold95Enabled },
                        set: { newValue in
                            var updated = profile
                            updated.notificationSettings.threshold95Enabled = newValue
                            profileManager.updateProfile(updated)
                        }
                    )
                )
                ThresholdIndicator(level: "0%", color: SettingsColors.usageLow, label: "notifications.threshold.session_reset".localized)
            }
        }
    }

    // MARK: - Custom Thresholds

    @ViewBuilder
    private func customThresholdsCard(profile: Profile) -> some View {
        if featureFlags.isAvailable(featureFlags.customThresholds) {
            SettingsSectionCard(
                title: "notifications.custom_thresholds".localized,
                subtitle: "Define your own alert percentages"
            ) {
                CustomThresholdsEditor(
                    thresholds: Binding(
                        get: { profile.notificationSettings.customThresholds },
                        set: { newValue in
                            var updated = profile
                            updated.notificationSettings.customThresholds = newValue
                            profileManager.updateProfile(updated)
                        }
                    )
                )
            }
        } else {
            SettingsContentCard {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.proBadge)
                    Text("Custom thresholds available on Pro")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(AppTheme.Spacing.sm)
            }
        }
    }

    // MARK: - Sound

    private func soundCard(profile: Profile) -> some View {
        SettingsSectionCard(
            title: "notifications.sound".localized,
            subtitle: "Choose the alert sound for threshold notifications"
        ) {
            NotificationSoundPicker(
                soundName: Binding(
                    get: { profile.notificationSettings.soundName },
                    set: { newValue in
                        var updated = profile
                        updated.notificationSettings.soundName = newValue
                        profileManager.updateProfile(updated)
                    }
                )
            )
        }
    }

    // MARK: - Notification Preview

    private func notificationPreviewCard(profile: Profile) -> some View {
        SettingsSectionCard(
            title: "Notification Preview",
            subtitle: "Test how threshold alerts will appear"
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                previewAlertRow(
                    level: "75%",
                    color: SettingsColors.usageMedium,
                    message: "notifications.threshold.warning".localized,
                    enabled: profile.notificationSettings.threshold75Enabled
                )
                previewAlertRow(
                    level: "90%",
                    color: SettingsColors.usageHigh,
                    message: "notifications.threshold.high".localized,
                    enabled: profile.notificationSettings.threshold90Enabled
                )
                previewAlertRow(
                    level: "95%",
                    color: SettingsColors.usageCritical,
                    message: "notifications.threshold.critical".localized,
                    enabled: profile.notificationSettings.threshold95Enabled
                )

                SettingsButton(
                    title: "Send Test Notification",
                    icon: "bell.fill",
                    style: .secondary
                ) {
                    NotificationManager.shared.sendSimpleAlert(type: .notificationsEnabled)
                }
            }
        }
    }

    private func previewAlertRow(level: String, color: Color, message: String, enabled: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(enabled ? color : AppTheme.Colors.borderSubtle)
                .frame(width: 8, height: 8)

            Text(level)
                .font(AppTheme.Typography.captionSemibold)
                .foregroundColor(enabled ? AppTheme.Colors.textPrimary : AppTheme.Colors.textMuted)
                .frame(width: 32, alignment: .leading)

            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundColor(enabled ? AppTheme.Colors.textSecondary : AppTheme.Colors.textMuted)

            Spacer()

            if !enabled {
                Text("OFF")
                    .font(AppTheme.Typography.badge)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.borderSubtle.opacity(0.3))
                    )
            }
        }
    }

    // MARK: - Helpers

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            if settings.authorizationStatus == .authorized {
                NotificationManager.shared.sendSimpleAlert(type: .notificationsEnabled)
            } else if settings.authorizationStatus == .notDetermined {
                let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted == true {
                    NotificationManager.shared.sendSimpleAlert(type: .notificationsEnabled)
                }
            }
        }
    }
}

#Preview {
    NotificationsSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
