//
//  AboutView.swift
//  Claude Usage - About and Credits
//
//  Created by Claude Code on 2025-12-20.
//

import SwiftUI
import AppKit

/// About page with app information, direct-distribution details, and support actions.
struct AboutView: View {
    @State private var contributors: [Contributor] = []
    @State private var isLoadingContributors = false
    @State private var contributorsError: String?
    @State private var showResetConfirmation = false

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.section) {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image("AboutLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)

                    VStack(spacing: DesignTokens.Spacing.extraSmall) {
                        Text("app.name".localized)
                            .font(AppTheme.Typography.pageTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("about.version".localized(with: appVersion))
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        // Check for Updates button
                        Button(action: {
                            UpdateManager.shared.checkForUpdates()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 10))
                                Text("about.check_updates".localized)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(AppTheme.Colors.accentHover)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.cardPadding)

                ProductInsightCard(
                    icon: "shippingbox.fill",
                    title: "Direct macOS distribution",
                    message: "AI Usage Tracker is distributed directly with Sparkle updates, so fixes and provider changes can ship faster than an App Store release cycle.",
                    color: AppTheme.Colors.info
                )

                // Creator
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    Text("Built and maintained by")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Button(action: {
                        if let url = URL(string: "https://github.com/amitashwinibhagat") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: DesignTokens.Spacing.medium) {
                            Image(systemName: "person.circle.fill")
                                .font(AppTheme.Typography.cardTitle)
                                .foregroundColor(AppTheme.Colors.accentHover)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("creator.name".localized)
                                    .font(AppTheme.Typography.label)
                                    .foregroundColor(AppTheme.Colors.textPrimary)

                                Text("creator.username".localized)
                                    .font(AppTheme.Typography.small)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(AppTheme.Typography.tinySemibold)
                                .foregroundColor(AppTheme.Colors.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Links
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    Text("about.links".localized)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    VStack(spacing: DesignTokens.Spacing.small) {
                        LinkButton(title: "about.send_feedback".localized, icon: "bubble.left.and.text.bubble.right") {
                            if let url = URL(string: "mailto:support@aiusagetracker.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }

                        Divider()

                        LinkButton(title: "about.run_setup_wizard".localized, icon: "wand.and.stars") {
                            LoggingService.shared.log("AboutView: Setup Wizard button clicked - posting notification")
                            NotificationCenter.default.post(name: .showSetupWizard, object: nil)
                        }

                        LinkButton(
                            title: "about.reset_app_data".localized,
                            icon: "trash",
                            tint: AppTheme.Colors.error,
                            iconTint: AppTheme.Colors.error,
                            trailingIcon: nil
                        ) {
                            showResetConfirmation = true
                        }
                    }
                }
                .alert("about.reset_confirmation_title".localized, isPresented: $showResetConfirmation) {
                    Button("common.cancel".localized, role: .cancel) { }
                    Button("about.reset_confirm".localized, role: .destructive) {
                        resetAppData()
                    }
                } message: {
                    Text("about.reset_confirmation_message".localized)
                }

                // Footer
                VStack(spacing: DesignTokens.Spacing.extraSmall) {
                    Text("Free macOS app — all features included")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textMuted)

                    Text("© \(String(Calendar.current.component(.year, from: Date()))) Amit Ashwini Bhagat")
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.medium)

                Spacer()
            }
            .padding(28)
        }
        .onAppear { }
    }

    private func resetAppData() {
        LoggingService.shared.log("AboutView: Resetting app data...")

        // Reset all app data (standard container only)
        MigrationService.shared.resetAppData()

        // Quit the app - user will need to relaunch and set up again
        LoggingService.shared.log("AboutView: App data reset complete, quitting app")
        NSApplication.shared.terminate(nil)
    }

    private func fetchContributors() {
        isLoadingContributors = true
        contributorsError = nil

        Task {
            do {
                let fetchedContributors = try await GitHubService.shared.fetchContributors()
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        self.contributors = fetchedContributors
                        self.isLoadingContributors = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.contributorsError = error.localizedDescription
                    self.isLoadingContributors = false
                }
            }
        }
    }
}

// MARK: - Link Button

struct LinkButton: View {
    let title: String
    let icon: String
    let tint: Color
    let iconTint: Color
    let trailingIcon: String?
    let action: () -> Void

    init(
        title: String,
        icon: String,
        tint: Color = AppTheme.Colors.textPrimary,
        iconTint: Color = AppTheme.Colors.textSecondary,
        trailingIcon: String? = "arrow.up.right",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.iconTint = iconTint
        self.trailingIcon = trailingIcon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.iconText) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.Icons.small))
                    .foregroundColor(iconTint)
                    .frame(width: DesignTokens.Spacing.cardPadding)

                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(tint)

                Spacer()

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contributors Grid View

struct ContributorsGridView: View {
    let contributors: [Contributor]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 40, maximum: 44), spacing: DesignTokens.Spacing.small)
        ], spacing: DesignTokens.Spacing.small) {
            ForEach(contributors) { contributor in
                ContributorAvatar(contributor: contributor)
            }
        }
    }
}

struct ContributorAvatar: View {
    let contributor: Contributor
    @State private var imageData: Data?
    @State private var isLoadingImage = true

    var body: some View {
        Button(action: {
            if let url = URL(string: contributor.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }) {
            ZStack {
                if let data = imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppTheme.Colors.borderSubtle)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Group {
                                if isLoadingImage {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary.opacity(0.3))
                                }
                            }
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .help(contributor.login)
        .onAppear {
            loadAvatar()
        }
    }

    private func loadAvatar() {
        guard let url = URL(string: contributor.avatarUrl) else {
            isLoadingImage = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.imageData = data
                    self.isLoadingImage = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    AboutView()
        .frame(width: 520, height: 600)
}
