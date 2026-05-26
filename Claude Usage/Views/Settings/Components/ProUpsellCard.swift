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
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple)

                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .cornerRadius(3)
                }

                Text(message)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Spacer()
                    Text(actionTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.purple)
                }
            }
            .padding(DesignTokens.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(Color.purple.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(isHovered ? Color.purple.opacity(0.03) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
