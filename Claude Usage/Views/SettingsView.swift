import SwiftUI

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

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable {
    case general
    case profiles
    case credentials
    case notifications
    case appearance
    case account

    var title: String {
        switch self {
        case .general: return "general.title".localized
        case .profiles: return "profiles.title".localized
        case .credentials: return "Credentials"
        case .notifications: return "Notifications"
        case .appearance: return "section.appearance_title".localized
        case .account: return "Account"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .profiles: return "person.2.fill"
        case .credentials: return "key.fill"
        case .notifications: return "bell.fill"
        case .appearance: return "paintbrush.fill"
        case .account: return "star.fill"
        }
    }

    var description: String {
        switch self {
        case .general: return "Launch, updates, language, and developer settings"
        case .profiles: return "Create and manage profiles for different accounts and projects"
        case .credentials: return "Connect AI providers with API keys or OAuth"
        case .notifications: return "Usage threshold alerts and session planning"
        case .appearance: return "Menu bar icon style, colors, and popover layout"
        case .account: return "License, subscription, and app information"
        }
    }
}

// MARK: - Main Settings View

/// Professional, native macOS Settings interface with 6-group sidebar navigation
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    @StateObject private var profileManager = ProfileManager.shared

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selectedSection: $selectedSection)

            Rectangle()
                .fill(AppTheme.Colors.borderSubtle)
                .frame(width: 1)

            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.background)
        }
        .frame(minWidth: 780, maxWidth: 780, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundDeep)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .general:
            GeneralSettingsView()
        case .profiles:
            ProfilesSettingsView()
        case .credentials:
            CredentialsSettingsView()
        case .notifications:
            NotificationsSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .account:
            AccountSettingsView()
        }
    }
}

// MARK: - Settings Sidebar

struct SettingsSidebar: View {
    @Binding var selectedSection: SettingsSection
    @StateObject private var profileManager = ProfileManager.shared

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
                .padding(.top, AppTheme.Spacing.sm)

            profileSwitcherRow
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.mdCompact)

            Divider()
                .overlay(AppTheme.Colors.divider)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
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
                .padding(.horizontal, AppTheme.Spacing.mdCompact)
            }

            Divider()
                .overlay(AppTheme.Colors.divider)
                .padding(.horizontal, AppTheme.Spacing.mdCompact)

            VStack(spacing: AppTheme.Spacing.sm) {
                // BUG 9 from the click audit: removed the duplicate
                // "About" button from the bottom bar — the sidebar
                // already has an "Account" item that shows the same
                // page. The bottom bar now only hosts the Quit
                // action, which has no other surface in the UI.
                HStack(spacing: 0) {
                    bottomBarButton(
                        icon: "power",
                        label: "common.quit".localized,
                        isSelected: false,
                        hoverColor: AppTheme.Colors.error.opacity(0.12)
                    ) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.mdCompact)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .frame(width: 200)
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

    private var profileSwitcherRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("section.active_profile".localized)
                .font(AppTheme.Typography.microSemibold)
                .foregroundColor(AppTheme.Colors.textMuted)

            if let active = profileManager.activeProfile {
                Picker("", selection: Binding(
                    get: { profileManager.activeProfile?.id ?? UUID() },
                    set: { newId in
                        Task { await profileManager.activateProfile(newId) }
                    }
                )) {
                    ForEach(profileManager.profiles) { profile in
                        HStack {
                            Text(profile.name)
                        }
                        .tag(profile.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .tint(AppTheme.Colors.accent)
            } else {
                Text("No profile")
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.72))
        )
    }

    private func bottomBarButton(
        icon: String,
        label: String,
        isSelected: Bool,
        hoverColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
                    .fill(isSelected ? AppTheme.Colors.accentMuted : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .strokeBorder(isSelected ? AppTheme.Colors.accent.opacity(0.35) : Color.clear, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

// MARK: - Sidebar Brand Header

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
            .frame(width: 30, height: 30)

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
