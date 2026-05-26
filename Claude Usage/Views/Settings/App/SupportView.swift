//
//  SupportView.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-01-30.
//

import SwiftUI
import AppKit

/// Support the project view - Buy Me a Coffee
struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("support.title".localized)
                        .font(.system(size: 24, weight: .bold))

                    Text("support.subtitle".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Main message
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("support.all_features_free".localized)
                                .font(.system(size: 14, weight: .semibold))
                            Text("support.all_features_desc".localized)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("support.open_source".localized)
                                .font(.system(size: 14, weight: .semibold))
                            Text("support.open_source_desc".localized)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("support.no_tracking".localized)
                                .font(.system(size: 14, weight: .semibold))
                            Text("support.no_tracking_desc".localized)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .background(DesignTokens.Colors.cardBackground)
                .cornerRadius(12)

                // Support section
                VStack(spacing: 16) {
                    Text("support.message".localized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        if let url = URL(string: "https://www.buymeacoffee.com/hamedelfayome") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 16))
                            Text("support.buy_coffee".localized)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 1.0, green: 0.87, blue: 0.0)) // Buy Me a Coffee yellow
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Text("support.footer".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                // Pro upgrade CTA
                VStack(spacing: 12) {
                    Text("Unlock more features")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Button(action: {
                        if let url = LicenseManager.shared.proCheckoutURL {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                            Text("Upgrade to Pro")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(28)
        }
    }
}

// MARK: - Previews

#Preview {
    SupportView()
        .frame(width: 520, height: 600)
}
