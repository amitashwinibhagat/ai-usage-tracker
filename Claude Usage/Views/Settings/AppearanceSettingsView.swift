//
//  AppearanceSettingsView.swift
//  Claude Usage - Consolidated Appearance Settings
//
//  Merges: AppearanceSettingsView, PopoverSettingsView (display parts)
//

import SwiftUI

enum AppColorScheme: String, CaseIterable {
    case system
    case dark
    case light
}

struct AppearanceSettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var configuration: MenuBarIconConfiguration = .default
    @State private var saveDebounceTimer: Timer?
    @AppStorage("appColorScheme") private var selectedColorSchemeRaw: String = AppColorScheme.system.rawValue
    private var selectedColorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: selectedColorSchemeRaw) ?? .system }
        set { selectedColorSchemeRaw = newValue.rawValue }
    }
    @State private var popoverWidthIndex: Int = 0

    private var isMultiProfileMode: Bool {
        profileManager.displayMode == .multi
    }

    private let popoverWidths: [(label: String, width: CGFloat)] = [
        ("Compact (320pt)", 320),
        ("Wide (400pt)", 400)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                SettingsPageHeader(
                    title: "section.appearance_title".localized,
                    subtitle: "section.appearance_desc".localized
                )

                if isMultiProfileMode {
                    multiProfileWarning
                }

                iconStyleCard

                displayToggleCard

                colorSchemeCard

                popoverWidthCard

                Spacer()
            }
            .padding(28)
        }
        .onAppear {
            if let activeProfile = profileManager.activeProfile {
                configuration = activeProfile.iconConfig
            }
        }
        .onChange(of: profileManager.activeProfile?.id) { _, _ in
            if let activeProfile = profileManager.activeProfile {
                configuration = activeProfile.iconConfig
            }
        }
    }

    // MARK: - Multi-Profile Warning

    private var multiProfileWarning: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("appearance.multiprofile_locked_title".localized)
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("appearance.multiprofile_locked_description".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button(action: {
                profileManager.updateDisplayMode(.single)
                NotificationCenter.default.post(name: .displayModeChanged, object: nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(AppTheme.Typography.tinySemibold)
                    Text("appearance.disable_multiprofile".localized)
                        .font(AppTheme.Typography.tinySemibold)
                }
                .foregroundColor(AppTheme.Colors.warning)
                        .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.compact)
                        .stroke(AppTheme.Colors.warning, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(AppTheme.Colors.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .strokeBorder(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Icon Style

    private var iconStyleCard: some View {
        SettingsSectionCard(
            title: "appearance.menu_bar_metrics".localized,
            subtitle: "appearance.metrics_subtitle".localized
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                iconStylePickerRow

                if !isMultiProfileMode {
                    Divider().overlay(AppTheme.Colors.divider)

                    SettingToggle(
                        title: "appearance.monochrome_title".localized,
                        description: "appearance.monochrome_description".localized,
                        isOn: Binding(
                            get: { configuration.colorMode == .monochrome },
                            set: { newValue in
                                configuration.colorMode = newValue ? .monochrome : .multiColor
                                saveConfiguration()
                            }
                        )
                    )

                    SettingToggle(
                        title: "appearance.show_labels_title".localized,
                        description: "appearance.show_labels_description".localized,
                        isOn: Binding(
                            get: { configuration.showIconNames },
                            set: { newValue in
                                configuration.showIconNames = newValue
                                saveConfiguration()
                            }
                        )
                    )

                    SettingToggle(
                        title: "appearance.show_remaining_title".localized,
                        description: "appearance.show_remaining_description".localized,
                        isOn: Binding(
                            get: { configuration.showRemainingPercentage },
                            set: { newValue in
                                configuration.showRemainingPercentage = newValue
                                saveConfiguration()
                            }
                        )
                    )

                    SettingToggle(
                        title: "appearance.show_time_marker_title".localized,
                        description: "appearance.show_time_marker_description".localized,
                        isOn: Binding(
                            get: { configuration.showTimeMarker },
                            set: { newValue in
                                configuration.showTimeMarker = newValue
                                saveConfiguration()
                            }
                        )
                    )

                    SettingToggle(
                        title: "appearance.show_pace_marker_title".localized,
                        description: "appearance.show_pace_marker_description".localized,
                        isOn: Binding(
                            get: { configuration.showPaceMarker },
                            set: { newValue in
                                configuration.showPaceMarker = newValue
                                saveConfiguration()
                            }
                        )
                    )

                    SettingToggle(
                        title: "appearance.pace_coloring_title".localized,
                        description: "appearance.pace_coloring_description".localized,
                        isOn: Binding(
                            get: { configuration.usePaceColoring },
                            set: { newValue in
                                configuration.usePaceColoring = newValue
                                saveConfiguration()
                            }
                        )
                    )
                }
            }
        }
        .disabled(isMultiProfileMode)
        .opacity(isMultiProfileMode ? 0.5 : 1.0)
    }

    private var iconStylePickerRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Icon Style")
                .font(AppTheme.Typography.label)
                .foregroundColor(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(["ring", "bar", "numeric"], id: \.self) { style in
                    Button(action: { selectIconStyle(style) }) {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: style == "ring" ? "circle.circle" : (style == "bar" ? "chart.bar.fill" : "number.circle.fill"))
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(currentIconStyle == style ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                            Text(style.capitalized)
                                .font(AppTheme.Typography.tiny)
                                .foregroundColor(currentIconStyle == style ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                        }
                        .padding(AppTheme.Spacing.sm)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                                .fill(currentIconStyle == style ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.backgroundDeep.opacity(0.45))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                                .strokeBorder(currentIconStyle == style ? AppTheme.Colors.accent.opacity(0.4) : AppTheme.Colors.borderSubtle.opacity(0.75), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var currentIconStyle: String {
        return "ring"
    }

    private func selectIconStyle(_ style: String) {
    }

    // MARK: - Display Toggles

    private var displayToggleCard: some View {
        SettingsSectionCard(
            title: "appearance.global_settings".localized,
            subtitle: "appearance.global_subtitle".localized
        ) {
            EmptyView()
        }
    }

    // MARK: - Color Scheme

    private var colorSchemeCard: some View {
        SettingsSectionCard(
            title: "Color Scheme",
            subtitle: "Choose the app appearance"
        ) {
            Picker("", selection: Binding(
                get: { selectedColorScheme },
                set: { selectedColorSchemeRaw = $0.rawValue }
            )) {
                Text("Auto").tag(AppColorScheme.system)
                Text("Dark").tag(AppColorScheme.dark)
                Text("Light").tag(AppColorScheme.light)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Popover Width

    private var popoverWidthCard: some View {
        SettingsSectionCard(
            title: "Popover Width",
            subtitle: "Adjust the popover panel size"
        ) {
            Picker("", selection: $popoverWidthIndex) {
                ForEach(0..<popoverWidths.count, id: \.self) { idx in
                    Text(popoverWidths[idx].label).tag(idx)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Helpers

    private func saveConfiguration() {
        guard let profileId = profileManager.activeProfile?.id else {
            return
        }
        profileManager.updateIconConfig(configuration, for: profileId)
        NotificationCenter.default.post(name: .menuBarIconConfigChanged, object: nil)
    }
}

#Preview {
    AppearanceSettingsView()
        .frame(width: 520, height: 700)
        .preferredColorScheme(.dark)
}
