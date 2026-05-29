import SwiftUI
import UserNotifications

// MARK: - Visual Effect Backgrounds

/// Full-window vibrancy background — same approach as the popover's VisualEffectBackground.
/// Using NSViewRepresentable inside SwiftUI means the entire view tree is SwiftUI-managed,
/// so there is no opaque flash on deminiaturize or appearance change.
struct SettingsBackground: NSViewRepresentable {
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
            tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
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
                tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
            } else {
                tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.4).cgColor
            }
        }
    }
}

struct SidebarVisualEffect: NSViewRepresentable {
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
            tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        } else {
            tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
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
                tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
            } else {
                tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
            }
        }
    }
}

/// Borderless window that keeps rounded corners, shadow, and drag-to-move.
final class BorderlessSettingsWindow: NSWindow {
    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask,
                  backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .miniaturizable],
                   backing: backing, defer: flag)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isRestorable = false

        // Round corners via the content view's layer
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 10
        contentView?.layer?.masksToBounds = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Builds the settings window — fully borderless, no system titlebar.
enum SettingsWindowBuilder {
    static func makeWindow(size: CGSize) -> NSWindow {
        let window = BorderlessSettingsWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView:
            SettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        window.contentView?.addSubview(hostingView)
        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }

        return window
    }
}

// MARK: - Custom Traffic Light Buttons

struct TrafficLightButtons: View {
    @Environment(\.controlActiveState) private var controlActiveState

    var body: some View {
        HStack(spacing: 8) {
            TrafficLightButton(type: .close)
            TrafficLightButton(type: .miniaturize)
        }
    }
}

struct TrafficLightButton: View {
    enum ButtonType {
        case close, miniaturize, zoom

        var activeColor: Color {
            switch self {
            case .close: return Color(nsColor: NSColor(red: 1.0, green: 0.38, blue: 0.34, alpha: 1.0))
            case .miniaturize: return Color(nsColor: NSColor(red: 1.0, green: 0.74, blue: 0.18, alpha: 1.0))
            case .zoom: return Color(nsColor: NSColor(red: 0.15, green: 0.78, blue: 0.24, alpha: 1.0))
            }
        }

        var icon: String {
            switch self {
            case .close: return "xmark"
            case .miniaturize: return "minus"
            case .zoom: return "plus"
            }
        }
    }

    let type: ButtonType
    @State private var isHovered = false
    @Environment(\.controlActiveState) private var controlActiveState

    private var isActive: Bool { controlActiveState == .key }

    var body: some View {
        Circle()
            .fill(isActive ? type.activeColor : AppTheme.Colors.borderSubtle)
            .frame(width: 12, height: 12)
            .overlay {
                if isHovered && isActive {
                    Image(systemName: type.icon)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            .onHover { isHovered = $0 }
            .onTapGesture { performAction() }
    }

    private func performAction() {
        guard let window = NSApp.keyWindow else { return }
        switch type {
        case .close: window.close()
        case .miniaturize: window.miniaturize(nil)
        case .zoom: window.zoom(nil)
        }
    }
}

/// Professional, native macOS Settings interface with multi-profile support
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .appearance
    @State private var focusedProvider: AIProvider? = nil
    @StateObject private var profileManager = ProfileManager.shared

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(
                selectedSection: $selectedSection,
                focusedProvider: $focusedProvider
            )

            Rectangle()
                .fill(AppTheme.Colors.borderSubtle)
                .frame(width: 1)

            // Content
            Group {
                switch selectedSection {
                // Credentials (legacy — accessed via Providers section)
                case .claudeAI:
                    PersonalUsageView()
                case .apiConsole:
                    APIBillingView()
                case .cliAccount:
                    CLIAccountView()

                // Profile Settings
                case .appearance:
                    AppearanceSettingsView()
                case .general:
                    GeneralSettingsView()
                case .history:
                    UsageHistoryView()
                case .proFeatures:
                    ProFeaturesView()

                // AI Providers
                case .aiProviders:
                    AIProvidersSettingsView(focusedProvider: $focusedProvider)

                // Shared Settings
                case .appSettings:
                    AppSettingsView()
                case .manageProfiles:
                    ManageProfilesView()
                case .language:
                    LanguageSettingsView()
                case .claudeCode:
                    ClaudeCodeView()
                case .shortcuts:
                    ShortcutsSettingsView()
                case .updates:
                    UpdatesSettingsView()
                case .support:
                    SupportView()
                case .mobileApp:
                    MobileAppView()
                case .popover:
                    PopoverSettingsView()
                case .debug:
                    DebugNetworkLogView()
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background)
        }
        .frame(minWidth: 820, maxWidth: 820, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundDeep)
    }
}

// MARK: - Settings Sidebar

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection
    @Binding var focusedProvider: AIProvider?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TrafficLightButtons()
                Spacer()
            }
            .padding(.leading, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)

            SidebarBrandHeader()
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.mdCompact)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.mdCompact) {
                    ProfileSectionContainer(
                        selectedSection: $selectedSection,
                        focusedProvider: $focusedProvider
                    )
                    AppSettingsSection(selectedSection: $selectedSection)
                }
                .padding(.horizontal, AppTheme.Spacing.mdCompact)
                .padding(.top, AppTheme.Spacing.mdCompact)
                .padding(.bottom, AppTheme.Spacing.md)
            }

            BottomBarSection(selectedSection: $selectedSection)
                .padding(.horizontal, AppTheme.Spacing.mdCompact)
                .padding(.bottom, AppTheme.Spacing.sm)
        }
        .frame(width: 228)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.sidebar,
                    AppTheme.Colors.backgroundDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct SidebarBrandHeader: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(AppTheme.Colors.accentMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .strokeBorder(AppTheme.Colors.accent.opacity(0.35), lineWidth: 0.5)
                    )

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.accentHover)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Usage")
                    .font(AppTheme.Typography.labelBold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Tracker")
                    .font(AppTheme.Typography.tinyMedium)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - Profile Section Container

struct ProfileSectionContainer: View {
    @Binding var selectedSection: SettingsSection
    @Binding var focusedProvider: AIProvider?
    @StateObject private var profileManager = ProfileManager.shared

    var profileSections: [SettingsSection] {
        SettingsSection.allCases.filter { $0.isProfileSetting && !$0.isCredential }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Profile Switcher
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("section.active_profile".localized)
                    .font(AppTheme.Typography.microSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)

                Picker("", selection: Binding(
                    get: { profileManager.activeProfile?.id ?? UUID() },
                    set: { newId in
                        Task {
                            await profileManager.activateProfile(newId)
                        }
                    }
                )) {
                    ForEach(profileManager.profiles) { profile in
                        HStack {
                            Text(profile.name)
                            if profile.hasCliAccount {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(AppTheme.Typography.micro)
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                        }
                        .tag(profile.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .tint(AppTheme.Colors.accent)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.top, AppTheme.Spacing.sm)

            Divider()
                .overlay(AppTheme.Colors.divider)

            // Providers
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("section.providers".localized)
                    .font(AppTheme.Typography.microSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .padding(.horizontal, AppTheme.Spacing.sm)

                ProvidersSidebarSection(
                    selectedSection: $selectedSection,
                    focusedProvider: $focusedProvider
                )
                .padding(.horizontal, AppTheme.Spacing.xs)
            }

            Divider()
                .overlay(AppTheme.Colors.divider)

            // Profile Settings
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("section.settings".localized)
                    .font(AppTheme.Typography.microSemibold)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .padding(.horizontal, AppTheme.Spacing.sm)

                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(profileSections, id: \.self) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            SettingMiniButton(
                                icon: section.icon,
                                title: section.title,
                                isSelected: selectedSection == section
                            )
                        }
                        .buttonStyle(.plain)
                        .help(section.description)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
    }
}

// MARK: - App Settings Section

struct AppSettingsSection: View {
    @Binding var selectedSection: SettingsSection

    var sharedSections: [SettingsSection] {
        SettingsSection.allCases.filter { !$0.isProfileSetting && !$0.isCredential && !$0.isBottomBarItem }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("section.app".localized)
                .font(AppTheme.Typography.microSemibold)
                .foregroundColor(AppTheme.Colors.textMuted)
                .padding(.horizontal, AppTheme.Spacing.sm)

            ForEach(sharedSections, id: \.self) { section in
                SidebarItem(
                    icon: section.icon,
                    title: section.title,
                    description: section.description,
                    isSelected: selectedSection == section
                ) {
                    selectedSection = section
                }
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.48))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle.opacity(0.8), lineWidth: 0.5)
        )
    }
}

struct BottomBarSection: View {
    @Binding var selectedSection: SettingsSection
    @State private var hoveredItem: String?

    var items: [SettingsSection] {
        SettingsSection.allCases.filter { $0.isBottomBarItem }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Divider()
                .overlay(AppTheme.Colors.divider)

            HStack(spacing: 0) {
                ForEach(items, id: \.self) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        bottomBarLabel(
                            icon: section.icon,
                            label: section.shortLabel,
                            isSelected: selectedSection == section,
                            isHovered: hoveredItem == section.rawValue
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        hoveredItem = hovering ? section.rawValue : nil
                    }
                    .help(section.title)
                }

                // Quit button
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                        bottomBarLabel(
                            icon: "power",
                            label: "common.quit".localized,
                            isSelected: false,
                            isHovered: hoveredItem == "quit",
                            hoverColor: AppTheme.Colors.error.opacity(0.12)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredItem = hovering ? "quit" : nil
                }
                .help("common.quit".localized)
            }
        }
    }

    private func bottomBarLabel(icon: String, label: String, isSelected: Bool, isHovered: Bool, hoverColor: Color? = nil) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(AppTheme.Typography.smallMedium)
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textMuted)
                .frame(height: 14)

            Text(label)
                .font(AppTheme.Typography.nanoMedium)
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(isSelected ? AppTheme.Colors.accentMuted : (isHovered ? (hoverColor ?? AppTheme.Colors.cardElevated) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.35) : Color.clear, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}

enum SettingsSection: String, CaseIterable {
    // Credentials (not shown in sidebar)
    case claudeAI
    case apiConsole
    case cliAccount

    // Profile Settings
    case appearance
    case general
    case history

    // Pro Features
    case proFeatures

    // AI Providers
    case aiProviders

    // Shared Settings
    case appSettings
    case manageProfiles
    case language
    case claudeCode
    case shortcuts
    case updates
    case support
    case mobileApp
    case popover
    case debug
    case about

    var title: String {
        switch self {
        case .claudeAI: return "section.claudeai_title".localized
        case .apiConsole: return "section.api_console_title".localized
        case .cliAccount: return "section.cli_account_title".localized
        case .appearance: return "section.appearance_title".localized
        case .general: return "section.general_title".localized
        case .history: return "section.history_title".localized
        case .proFeatures: return "Pro Features"
        case .aiProviders: return "AI Providers"
        case .appSettings: return "section.app_settings_title".localized
        case .manageProfiles: return "section.manage_profiles_title".localized
        case .language: return "language.title".localized
        case .claudeCode: return "settings.claude_cli".localized
        case .shortcuts: return "section.shortcuts_title".localized
        case .updates: return "settings.updates".localized
        case .support: return "section.support_title".localized
        case .mobileApp: return "section.mobile_app_title".localized
        case .popover: return "section.popover_title".localized
        case .debug: return "section.debug_title".localized
        case .about: return "settings.about".localized
        }
    }

    var icon: String {
        switch self {
        case .claudeAI: return "key.fill"
        case .apiConsole: return "dollarsign.circle.fill"
        case .cliAccount: return "terminal.fill"
        case .appearance: return "paintbrush.fill"
        case .general: return "gearshape.fill"
        case .history: return "chart.bar.xaxis"
        case .proFeatures: return "star.fill"
        case .aiProviders: return "cpu.fill"
        case .appSettings: return "gearshape.2.fill"
        case .manageProfiles: return "person.2.fill"
        case .language: return "globe"
        case .claudeCode: return "chevron.left.forwardslash.chevron.right"
        case .shortcuts: return "keyboard"
        case .updates: return "arrow.down.circle.fill"
        case .support: return "heart.fill"
        case .mobileApp: return "iphone"
        case .popover: return "rectangle.topthird.inset.filled"
        case .debug: return "ladybug.fill"
        case .about: return "info.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .claudeAI: return "section.claudeai_desc".localized
        case .apiConsole: return "section.api_console_desc".localized
        case .cliAccount: return "section.cli_account_desc".localized
        case .appearance: return "section.appearance_desc".localized
        case .general: return "section.general_desc".localized
        case .history: return "section.history_desc".localized
        case .proFeatures: return "Unlock Pro features and manage your subscription"
        case .aiProviders: return "Manage credentials for all AI providers"
        case .appSettings: return "section.app_settings_desc".localized
        case .manageProfiles: return "section.manage_profiles_desc".localized
        case .language: return "language.subtitle".localized
        case .claudeCode: return "settings.claude_cli.description".localized
        case .shortcuts: return "section.shortcuts_desc".localized
        case .updates: return "settings.updates.description".localized
        case .support: return "section.support_desc".localized
        case .mobileApp: return "section.mobile_app_desc".localized
        case .popover: return "section.popover_desc".localized
        case .debug: return "section.debug_desc".localized
        case .about: return "settings.about.description".localized
        }
    }

    var shortLabel: String {
        switch self {
        case .about: return "About"
        case .debug: return "Debug"
        case .support: return "Support"
        default: return title
        }
    }

    var isCredential: Bool {
        switch self {
        case .claudeAI, .apiConsole, .cliAccount:
            return true
        default:
            return false
        }
    }

    var isProfileSetting: Bool {
        switch self {
        case .appearance, .general, .history:
            return true
        default:
            return false
        }
    }

    var isProFeature: Bool {
        switch self {
        case .proFeatures, .aiProviders:
            return true
        default:
            return false
        }
    }

    var isBottomBarItem: Bool {
        switch self {
        case .about, .debug, .support:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.captionMedium)
                    .foregroundColor(isSelected ? AppTheme.Colors.accentHover : AppTheme.Colors.textMuted)
                    .frame(width: 16)

                Text(title)
                    .font(isSelected ? AppTheme.Typography.captionMedium : AppTheme.Typography.caption)
                    .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(isSelected ? AppTheme.Colors.accentMuted : (isHovered ? AppTheme.Colors.cardElevated : Color.clear))
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.35) : Color.clear, lineWidth: 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(description)
    }
}

// MARK: - Providers Sidebar Section

struct ProvidersSidebarSection: View {
    @Binding var selectedSection: SettingsSection
    @Binding var focusedProvider: AIProvider?
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var featureFlags = FeatureFlags.shared

    private var providers: [AIProvider] {
        AIProvider.allCases
    }

    private func isConnected(_ provider: AIProvider, profile: Profile) -> Bool {
        switch provider {
        case .claude:
            return profile.hasUsageCredentials
        case .codex:
            return profile.hasCodexCredentials
        case .gemini:
            return profile.hasGeminiCredentials
        case .copilot:
            return profile.hasCopilotCredentials
        case .kimi:
            return profile.hasKimiCredentials
        case .deepseek:
            return profile.hasDeepSeekCredentials
        case .glm:
            return profile.hasGLMCredentials
        case .qwen:
            return profile.hasQwenCredentials
        case .minimax:
            return profile.hasMiniMaxCredentials
        }
    }

    private func isLocked(_ provider: AIProvider) -> Bool {
        featureFlags.isFree && !provider.isFreeTier
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ForEach(providers) { provider in
                let profile = profileManager.activeProfile
                let connected = profile.map { isConnected(provider, profile: $0) } ?? false
                let locked = isLocked(provider)

                Button {
                    if locked {
                        // Open Pro upgrade on locked providers
                        if let url = LicenseManager.shared.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        focusedProvider = provider
                        selectedSection = .aiProviders
                    }
                } label: {
                    ProviderSidebarRow(
                        provider: provider,
                        isConnected: connected,
                        isLocked: locked,
                        isSelected: selectedSection == .aiProviders && focusedProvider == provider
                    )
                }
                .buttonStyle(.plain)
                .disabled(profile == nil)
            }
        }
    }
}

struct ProviderSidebarRow: View {
    let provider: AIProvider
    let isConnected: Bool
    let isLocked: Bool
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: provider.icon)
                .font(AppTheme.Typography.captionMedium)
                .foregroundColor(isLocked ? AppTheme.Colors.textMuted.opacity(0.5) : (isConnected ? provider.brandColor : AppTheme.Colors.textMuted))
                .frame(width: 16)

            Text(provider.shortName)
                .font(isSelected ? AppTheme.Typography.captionMedium : AppTheme.Typography.caption)
                .foregroundColor(isLocked ? AppTheme.Colors.textMuted.opacity(0.6) : (isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary))
                .lineLimit(1)

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(AppTheme.Typography.microSemibold)
                    .foregroundColor(AppTheme.Colors.warning)
            } else if isConnected {
                Circle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(AppTheme.Colors.textMuted.opacity(0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(isSelected ? AppTheme.Colors.accentMuted : (isHovered ? AppTheme.Colors.cardElevated : Color.clear))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.35) : Color.clear, lineWidth: 0.5)
        }
        .onHover { isHovered = $0 }
    }
}

struct SettingMiniButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(AppTheme.Typography.captionMedium)
                .foregroundColor(isSelected ? AppTheme.Colors.accentHover : AppTheme.Colors.textMuted)
                .frame(width: 16)

            // Title
            Text(title)
                .font(isSelected ? AppTheme.Typography.captionMedium : AppTheme.Typography.caption)
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .fill(isSelected ? AppTheme.Colors.accentMuted : (isHovered ? AppTheme.Colors.cardElevated : Color.clear))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.35) : Color.clear, lineWidth: 0.5)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
