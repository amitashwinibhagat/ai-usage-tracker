//
//  Spacing.swift
//  Claude Usage - Settings Design System
//
//  DEPRECATED: Aliased into AppTheme. Use `AppTheme.Spacing.*` for new code.
//

import SwiftUI

enum Spacing {
    static let xs:  CGFloat = AppTheme.Spacing.xs
    static let sm:  CGFloat = AppTheme.Spacing.sm
    static let md:  CGFloat = AppTheme.Spacing.mdCompact
    static let lg:  CGFloat = AppTheme.Spacing.md
    static let xl:  CGFloat = AppTheme.Spacing.sectionCompact
    static let xxl: CGFloat = AppTheme.Spacing.lg
    static let xxxl: CGFloat = AppTheme.Spacing.xl

    static let sectionSpacing:           CGFloat = AppTheme.Spacing.sectionCompact
    static let cardSpacing:              CGFloat = AppTheme.Spacing.md
    static let cardPadding:              CGFloat = AppTheme.Spacing.sectionCompact
    static let inputSpacing:             CGFloat = AppTheme.Spacing.input
    static let inputPadding:             CGFloat = AppTheme.Spacing.inputPadding
    static let contentPadding:           CGFloat = AppTheme.Spacing.contentLarge
    static let compactPadding:           CGFloat = AppTheme.Spacing.compact
    static let toggleDescriptionSpacing: CGFloat = AppTheme.Spacing.xs
    static let iconTextSpacing:          CGFloat = AppTheme.Spacing.iconText
    static let buttonRowSpacing:         CGFloat = AppTheme.Spacing.buttonRow
    static let formRowSpacing:           CGFloat = AppTheme.Spacing.input

    static let radiusSmall:    CGFloat = AppTheme.Radius.tiny
    static let radiusMedium:   CGFloat = AppTheme.Radius.compact
    static let radiusStandard: CGFloat = AppTheme.Radius.small
    static let radiusLarge:    CGFloat = AppTheme.Radius.standard
    static let radiusXLarge:   CGFloat = AppTheme.Radius.large
}

extension View {
    func cardPadding() -> some View { self.padding(Spacing.cardPadding) }
    func contentPadding() -> some View { self.padding(Spacing.contentPadding) }
    func compactPadding() -> some View { self.padding(Spacing.compactPadding) }
}
