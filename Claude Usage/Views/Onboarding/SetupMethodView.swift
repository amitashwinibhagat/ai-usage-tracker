import SwiftUI

enum OnboardingMethod: String, CaseIterable {
    case claudeAI
    case claudeCode
    case apiConsole

    var iconName: String {
        switch self {
        case .claudeAI: return "globe"
        case .claudeCode: return "apple.terminal.fill"
        case .apiConsole: return "dollarsign.circle.fill"
        }
    }

    var titleKey: String {
        switch self {
        case .claudeAI: return "onboarding.method.claudeai.title"
        case .claudeCode: return "onboarding.method.claudecode.title"
        case .apiConsole: return "onboarding.method.apiconsole.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .claudeAI: return "onboarding.method.claudeai.description"
        case .claudeCode: return "onboarding.method.claudecode.description"
        case .apiConsole: return "onboarding.method.apiconsole.description"
        }
    }
}

struct SetupMethodView: View {
    @Binding var selectedMethods: Set<OnboardingMethod>
    @State private var cliDetected = false
    @State private var isDetecting = true
    @State private var detectedCredentials: String?
    var onContinue: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("onboarding.method.title".localized)
                            .font(AppTheme.Typography.pageTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("onboarding.method.subtitle".localized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(OnboardingMethod.allCases, id: \.self) { method in
                            MethodCard(
                                method: method,
                                isSelected: selectedMethods.contains(method),
                                isDetected: method == .claudeCode && cliDetected,
                                isDetecting: method == .claudeCode && isDetecting,
                                onTap: {
                                    toggleMethod(method)
                                }
                            )
                        }
                    }

                    if !selectedMethods.isEmpty && !canContinue {
                        Text("onboarding.method.select_one".localized)
                            .font(AppTheme.Typography.tiny)
                            .foregroundColor(AppTheme.Colors.caution)
                            .padding(.top, -8)
                    }
                }
                .padding(AppTheme.Spacing.xl)
            }

            Divider()
                .overlay(AppTheme.Colors.divider)

            HStack {
                Button(action: onBack) {
                    Text("common.back".localized)
                        .font(AppTheme.Typography.bodySmall)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: onContinue) {
                    Text("common.continue".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .frame(minWidth: 80)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue)
            }
            .padding(AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.sm)
        }
        .frame(width: 420, height: 380)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            detectCLI()
        }
    }

    private var canContinue: Bool {
        let validMethods = selectedMethods.filter { method in
            if method == .claudeCode && cliDetected { return true }
            return method != .claudeCode || cliDetected
        }
        return !selectedMethods.isEmpty && !validMethods.isEmpty
    }

    private func toggleMethod(_ method: OnboardingMethod) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }

    private func detectCLI() {
        Task {
            do {
                if let credentials = try ClaudeCodeSyncService.shared.readSystemCredentials(),
                   let _ = ClaudeCodeSyncService.shared.extractAccessToken(from: credentials),
                   !ClaudeCodeSyncService.shared.isTokenExpired(credentials) {
                    await MainActor.run {
                        cliDetected = true
                        detectedCredentials = credentials
                        self.selectedMethods.insert(.claudeCode)
                        isDetecting = false
                    }
                    return
                }
            } catch {
                LoggingService.shared.log("CLI detection failed: \(error.localizedDescription)")
            }

            await MainActor.run {
                cliDetected = false
                detectedCredentials = nil
                isDetecting = false
            }
        }
    }
}

struct MethodCard: View {
    let method: OnboardingMethod
    let isSelected: Bool
    var isDetected = false
    var isDetecting = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: method.iconName)
                    .font(AppTheme.Typography.subtitle)
                    .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.Colors.accentMuted : AppTheme.Colors.elevated)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(method.titleKey.localized)
                            .font(AppTheme.Typography.label)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if isDetected {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(AppTheme.Typography.nano)
                                Text("onboarding.method.detected".localized)
                                    .font(AppTheme.Typography.nanoSemibold)
                            }
                            .foregroundColor(AppTheme.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.success.opacity(0.12))
                            )
                        }

                        if isDetecting {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        }
                    }

                    Text(method.descriptionKey.localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.borderActive)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .fill(isSelected ? AppTheme.Colors.cardElevated : AppTheme.Colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                    .strokeBorder(
                        isSelected ? AppTheme.Colors.accent : AppTheme.Colors.borderSubtle,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SetupMethodView(
        selectedMethods: .constant([.claudeAI]),
        onContinue: {},
        onBack: {}
    )
}
