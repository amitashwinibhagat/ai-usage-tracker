import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onSkip: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.lg) {
                Image("WizardLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.6)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("onboarding.welcome.title".localized)
                        .font(AppTheme.Typography.hero)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("onboarding.welcome.subtitle".localized)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 12)

                Text("onboarding.welcome.description".localized)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 8)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.success)
                    Text("onboarding.welcome.privacy".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .opacity(isVisible ? 1 : 0)

                Button(action: onGetStarted) {
                    Text("onboarding.welcome.get_started".localized)
                        .font(AppTheme.Typography.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 8)

                Button(action: onSkip) {
                    Text("onboarding.welcome.skip".localized)
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(width: 420, height: 380)
        .background(AppTheme.Colors.background)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {}, onSkip: {})
}
