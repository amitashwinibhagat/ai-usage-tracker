import SwiftUI

struct BurnRateCard: View {
    let usage: ClaudeUsage
    let profileId: UUID

    @State private var prediction: BurnRatePrediction?
    @State private var sparklinePoints: [Double] = []

    private var isPro: Bool {
        FeatureFlags.shared.isProOrHigher
    }

    private var freeShouldUpsell: Bool {
        !isPro && usage.effectiveSessionPercentage > 50
    }

    var body: some View {
        Group {
            if isPro {
                proContent
            } else if freeShouldUpsell {
                freeUpsellContent
            }
        }
        .onAppear {
            if isPro {
                prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
                loadSparklineData()
            }
        }
        .onChange(of: usage.sessionTokensUsed) { _, _ in
            prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
            loadSparklineData()
        }
    }

    // MARK: - Pro Content

    private var proContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.warning)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.warning.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pace forecast")
                        .font(AppTheme.Typography.smallSemibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if let prediction = prediction, prediction.isReliable {
                        Text("\(Int(prediction.tokensPerMinute.rounded())) tokens/min")
                            .font(AppTheme.Typography.tiny)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                if let prediction = prediction, prediction.isReliable {
                    Image(systemName: prediction.trend.icon)
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(trendColor(prediction.trend))
                }
            }

            if !sparklinePoints.isEmpty {
                SparklineView(points: sparklinePoints)
                    .frame(height: 32)
                    .padding(.horizontal, AppTheme.Spacing.xs)
            }

            if let prediction = prediction, prediction.isReliable, let minutes = prediction.minutesToLimit {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("At this pace:")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text(minutes < 15 ? "limit soon" : prediction.timeToLimitText)
                        .font(AppTheme.Typography.roundedSemibold)
                        .foregroundColor(minutes < 15 ? AppTheme.Colors.error : AppTheme.Colors.warning)
                }

                Text("\(prediction.trend.description)  \(Int(prediction.tokensPerMinute.rounded())) tokens/min")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            } else if prediction != nil && !(prediction?.isReliable ?? true) {
                Text("Learning your pace")
                    .font(AppTheme.Typography.roundedSemibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            } else {
                Text("Calculating...")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.warning.opacity(0.22), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }

    // MARK: - Free Upsell Content

    private var freeUpsellContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.warning)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.warning.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("You're using tokens faster than usual. Upgrade to Pro for burn rate predictions.")
                        .font(AppTheme.Typography.captionMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: {
                        if let url = LicenseManager.shared.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Upgrade")
                            .font(AppTheme.Typography.tinySemibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.accent)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.accentMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.accent.opacity(0.25), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
    }

    // MARK: - Helpers

    private func trendColor(_ trend: BurnTrend) -> Color {
        switch trend {
        case .accelerating: return AppTheme.Colors.error
        case .steady: return AppTheme.Colors.warning
        case .decelerating: return AppTheme.Colors.success
        case .unknown: return AppTheme.Colors.textMuted
        }
    }

    private func loadSparklineData() {
        let snapshots = UsageHistoryService.shared.getSessionSnapshots(for: profileId)
        let sixHoursAgo = Date().addingTimeInterval(-6 * 60 * 60)
        let recent = snapshots
            .filter { $0.timestamp > sixHoursAgo }
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap { $0.sessionPercentage }
        sparklinePoints = recent.suffix(24)
    }
}

// MARK: - Mini Sparkline

struct SparklineView: View {
    let points: [Double]

    var body: some View {
        GeometryReader { geometry in
            if points.count < 2 {
                Color.clear
            } else {
                let width = geometry.size.width
                let height = geometry.size.height
                let maxVal = points.max() ?? 100
                let minVal = points.min() ?? 0
                let range = max(maxVal - minVal, 1)

                Path { path in
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let y = height * CGFloat(1.0 - (point - minVal) / range)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    AppTheme.Colors.warning,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )

                Path { path in
                    if let last = points.last, let first = points.first {
                        let firstY = height * CGFloat(1.0 - (first - minVal) / range)
                        let lastY = height * CGFloat(1.0 - (last - minVal) / range)
                        path.move(to: CGPoint(x: 0, y: firstY))
                        path.addLine(to: CGPoint(x: width, y: lastY))
                    }
                }
                .stroke(
                    AppTheme.Colors.textMuted.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
            }
        }
    }
}
