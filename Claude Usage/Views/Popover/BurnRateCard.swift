import SwiftUI

struct BurnRateCard: View {
    let usage: ClaudeUsage
    let profileId: UUID

    @State private var prediction: BurnRatePrediction?
    @State private var sparklinePoints: [Double] = []

    var body: some View {
        content
            .onAppear {
                computePrediction()
                loadSparklineData()
            }
            .onChange(of: usage.sessionTokensUsed) { _, _ in
                computePrediction()
                loadSparklineData()
            }
    }

    private var hasUsableForecast: Bool {
        guard let prediction = prediction else { return false }
        return prediction.isReliable && usage.sessionTokensUsed > 0
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.info)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.info.opacity(0.12))
                    )

                Text("Pace forecast")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                if hasUsableForecast, let prediction = prediction {
                    HStack(spacing: 3) {
                        Image(systemName: prediction.trend.icon)
                            .font(AppTheme.Typography.tinySemibold)
                        Text(prediction.trend.description)
                            .font(AppTheme.Typography.tinyMedium)
                    }
                    .foregroundColor(trendColor(prediction.trend))
                }
            }

            if hasUsableForecast {
                forecastBody
            } else {
                insufficientDataBody
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .fill(AppTheme.Colors.card.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.standard)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
    }

    private var forecastBody: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if hasMeaningfulSparkline {
                SparklineView(points: sparklinePoints)
                    .frame(height: 28)
                    .padding(.horizontal, AppTheme.Spacing.xs)
            }

            if let minutes = limitingMinutes, minutes < 7 * 24 * 60 {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("At this pace, limit in")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text(formatMinutes(minutes))
                        .font(AppTheme.Typography.roundedSemibold)
                        .foregroundColor(minutes < 15 ? AppTheme.Colors.error : AppTheme.Colors.warning)
                }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("Current pace is sustainable")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("plenty of headroom")
                        .font(AppTheme.Typography.roundedSemibold)
                        .foregroundColor(AppTheme.Colors.success)
                }
            }
        }
    }

    private var insufficientDataBody: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(AppTheme.Typography.tinySemibold)
                .foregroundColor(AppTheme.Colors.textMuted)
                .frame(width: 16, height: 16)

            Text("Not enough usage yet to forecast pace")
                .font(AppTheme.Typography.tiny)
                .foregroundColor(AppTheme.Colors.textMuted)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var limitingMinutes: Double? {
        guard let prediction = prediction else { return nil }
        let candidates = [prediction.minutesToLimit, prediction.weeklyMinutesToLimit].compactMap { $0 }
        guard !candidates.isEmpty else { return nil }
        return candidates.min()
    }

    private var hasMeaningfulSparkline: Bool {
        guard sparklinePoints.count >= 3 else { return false }
        let minVal = sparklinePoints.min() ?? 0
        let maxVal = sparklinePoints.max() ?? 0
        return maxVal - minVal > 0.5
    }

    private func formatMinutes(_ minutes: Double) -> String {
        if minutes <= 0 { return "Limit reached soon" }
        if minutes < 1 { return "Less than a minute" }
        if minutes < 60 {
            return "\(Int(minutes)) min"
        }
        let hours = minutes / 60.0
        if hours < 24 {
            return String(format: "%.1f hours", hours)
        }
        return String(format: "%.1f days", hours / 24.0)
    }

    private func trendColor(_ trend: BurnTrend) -> Color {
        switch trend {
        case .accelerating: return AppTheme.Colors.error
        case .steady: return AppTheme.Colors.warning
        case .decelerating: return AppTheme.Colors.success
        case .unknown: return AppTheme.Colors.textMuted
        }
    }

    private func computePrediction() {
        let fullPrediction = BurnRatePredictor.shared.predict(for: profileId, currentUsage: usage)
        if fullPrediction.isReliable {
            prediction = fullPrediction
        } else {
            prediction = BurnRatePredictor.shared.quickPredict(currentUsage: usage)
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
                    guard let firstPoint = points.first else { return }
                    let firstX: CGFloat = 0
                    let firstY = height * CGFloat(1.0 - (firstPoint - minVal) / range)
                    path.move(to: CGPoint(x: firstX, y: firstY))

                    for (index, point) in points.enumerated().dropFirst() {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let y = height * CGFloat(1.0 - (point - minVal) / range)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    if let last = points.last {
                        let lastX = width * CGFloat(points.count - 1) / CGFloat(max(points.count - 1, 1))
                        path.addLine(to: CGPoint(x: lastX, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                }
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.warning.opacity(0.15),
                            AppTheme.Colors.warning.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

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
            }
        }
    }
}

#Preview {
    BurnRateCard(
        usage: ClaudeUsage.empty,
        profileId: UUID()
    )
    .padding()
    .background(AppTheme.Colors.background)
    .preferredColorScheme(.dark)
}
