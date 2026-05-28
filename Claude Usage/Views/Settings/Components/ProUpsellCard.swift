//
//  ProUpsellCard.swift
//  Claude Usage
//
//  Reusable upsell card component for Pro feature prompts.
//

import SwiftUI

struct ProUpsellCard: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.proBadge.opacity(0.16))
                            .frame(width: 32, height: 32)

                        Image(systemName: "sparkles")
                            .font(AppTheme.Typography.smallSemibold)
                            .foregroundColor(AppTheme.Colors.proBadge)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(AppTheme.Typography.smallSemibold)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text(message)
                            .font(AppTheme.Typography.tiny)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("PRO")
                        .font(AppTheme.Typography.badge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.proBadge.opacity(0.22))
                        )
                }

                HStack {
                    Spacer()
                    Text(actionTitle)
                        .font(AppTheme.Typography.captionSemibold)
                        .foregroundColor(AppTheme.Colors.proBadge)
                    Image(systemName: "arrow.right")
                        .font(AppTheme.Typography.tinySemibold)
                        .foregroundColor(AppTheme.Colors.proBadge)
                }
            }
            .padding(AppTheme.Spacing.cardPadding)
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.proBadge.opacity(isHovered ? 0.18 : 0.12),
                        AppTheme.Colors.card.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .strokeBorder(AppTheme.Colors.proBadge.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
