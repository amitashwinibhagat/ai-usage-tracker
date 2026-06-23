import SwiftUI
import AppKit

// MARK: - Setup Mode (Auto-detect vs Manual)

enum SetupMode {
    case loading
    case cliDetected(credentials: String)
    case manualSetup
}

enum OnboardingStep: String, Hashable {
    case welcome
    case methods
    case credentials
}

/// Onboarding flow for first-time setup.
/// Detects existing Claude Code CLI credentials, then guides the user through
/// connecting their AI accounts.
struct SetupWizardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var setupMode: SetupMode = .loading
    @State private var selectedMethods: Set<OnboardingMethod> = []
    @State private var hasClaudeCodeCredentials = false
    @State private var navigationPath = NavigationPath()
    @State private var lastErrorMessage: String?

    var body: some View {
        Group {
            switch setupMode {
            case .loading:
                loadingView
                    .onAppear { detectCLICredentials() }

            case .cliDetected(let credentials):
                CLIDetectedSetupView(
                    credentials: credentials,
                    onStartTracking: { startTrackingWithCLI(credentials: credentials) },
                    onManualSetup: { setupMode = .manualSetup }
                )

            case .manualSetup:
                NavigationStack(path: $navigationPath) {
                    WelcomeView(
                        onGetStarted: {
                            navigationPath.append(OnboardingStep.methods)
                        },
                        onSkip: {
                            dismiss()
                        }
                    )
                    .navigationDestination(for: OnboardingStep.self) { step in
                        switch step {
                        case .welcome:
                            EmptyView()
                        case .methods:
                            SetupMethodView(
                                selectedMethods: $selectedMethods,
                                onContinue: {
                                    navigationPath.append(OnboardingStep.credentials)
                                },
                                onBack: {
                                    navigationPath.removeLast()
                                }
                            )
                            .onAppear {
                                if hasClaudeCodeCredentials {
                                    selectedMethods.insert(.claudeCode)
                                }
                            }
                        case .credentials:
                            CredentialSetupView(
                                selectedMethods: selectedMethods,
                                onDismiss: { dismiss() }
                            )
                        }
                    }
                }
            }
        }
        .alert("Setup Error", isPresented: Binding(
            get: { lastErrorMessage != nil },
            set: { if !$0 { lastErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { lastErrorMessage = nil }
        } message: {
            Text(lastErrorMessage ?? "")
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
            Text("setup.cli_detecting".localized)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(width: 420, height: 380)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
    }

    private func detectCLICredentials() {
        Task {
            do {
                if let credentials = try ClaudeCodeSyncService.shared.readSystemCredentials(),
                   let _ = ClaudeCodeSyncService.shared.extractAccessToken(from: credentials),
                   !ClaudeCodeSyncService.shared.isTokenExpired(credentials) {
                    await MainActor.run {
                        hasClaudeCodeCredentials = true
                        setupMode = .cliDetected(credentials: credentials)
                    }
                    return
                }
            } catch { }

            await MainActor.run {
                setupMode = .manualSetup
            }
        }
    }

    private func startTrackingWithCLI(credentials: String) {
        // BUG 6 from the click audit: surface a clear error when
        // there is no active profile, instead of silently falling
        // back to manual setup. The user should know what happened.
        guard let profileId = ProfileManager.shared.activeProfile?.id else {
            LoggingService.shared.logError("SetupWizard: no active profile when trying to sync CLI credentials")
            lastErrorMessage = "No active profile exists yet. Please use the manual setup to create a profile first."
            return
        }

        do {
            try ClaudeCodeSyncService.shared.syncToProfile(profileId)
            SharedDataStore.shared.saveHasCompletedSetup(true)
            NotificationCenter.default.post(name: .credentialsChanged, object: nil)
            dismiss()
        } catch {
            LoggingService.shared.logError("Failed to sync CLI credentials: \(error)")
            lastErrorMessage = "Failed to sync Claude Code credentials: \(error.localizedDescription)"
        }
    }
}

// MARK: - CLI Detected Setup View (Simplified)

struct CLIDetectedSetupView: View {
    let credentials: String
    let onStartTracking: () -> Void
    let onManualSetup: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.success.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "terminal.fill")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundColor(AppTheme.Colors.success)
                }

                Text("setup.cli_detected.title".localized)
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("setup.cli_detected.description".localized)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xxl)

                Button(action: onStartTracking) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "chart.bar.fill")
                        Text("setup.cli_detected.start".localized)
                    }
                    .font(AppTheme.Typography.bodyMedium)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onManualSetup) {
                    Text("setup.cli_detected.manual".localized)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(width: 420, height: 380)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SetupWizardView()
}
