import SwiftUI

/// Visual theme for all `MiraiStreakKitUI` views.
///
/// Apps inject a theme via `.streakTheme(_:)` to re-skin the entire streak surface
/// (flame gradient, accent colors, fonts, backgrounds) without forking views.
///
/// Built-in themes:
/// - `.duolingo` (default): orange flame, green checks, blue freeze, gold trophy.
/// - `.healora`: teal/dawn-gold for the Healora brand.
/// - `.aurielle`: soft purple for the Aurielle brand.
public struct StreakTheme: Sendable, Equatable {
    public var flameGradient: Gradient
    public var flameInactiveColor: Color
    public var flameMilestoneGradient: Gradient
    public var glowColor: Color
    public var checkmarkColor: Color
    public var freezeColor: Color
    public var trophyColor: Color
    public var background: Color
    public var cardBackground: Color
    public var primaryText: Color
    public var secondaryText: Color
    public var headlineFont: Font
    public var titleFont: Font
    public var bodyFont: Font
    public var captionFont: Font

    public init(
        flameGradient: Gradient,
        flameInactiveColor: Color,
        flameMilestoneGradient: Gradient,
        glowColor: Color,
        checkmarkColor: Color,
        freezeColor: Color,
        trophyColor: Color,
        background: Color,
        cardBackground: Color,
        primaryText: Color,
        secondaryText: Color,
        headlineFont: Font,
        titleFont: Font,
        bodyFont: Font,
        captionFont: Font
    ) {
        self.flameGradient = flameGradient
        self.flameInactiveColor = flameInactiveColor
        self.flameMilestoneGradient = flameMilestoneGradient
        self.glowColor = glowColor
        self.checkmarkColor = checkmarkColor
        self.freezeColor = freezeColor
        self.trophyColor = trophyColor
        self.background = background
        self.cardBackground = cardBackground
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.headlineFont = headlineFont
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
    }
}

public extension StreakTheme {
    /// The default Duolingo-inspired theme.
    static let duolingo = StreakTheme(
        flameGradient: Gradient(colors: [
            Color(red: 1.00, green: 0.78, blue: 0.20),
            Color(red: 1.00, green: 0.50, blue: 0.10),
            Color(red: 0.95, green: 0.25, blue: 0.10)
        ]),
        flameInactiveColor: Color.gray.opacity(0.55),
        flameMilestoneGradient: Gradient(colors: [
            Color(red: 1.00, green: 0.90, blue: 0.45),
            Color(red: 1.00, green: 0.75, blue: 0.20),
            Color(red: 0.95, green: 0.55, blue: 0.05)
        ]),
        glowColor: Color(red: 1.00, green: 0.55, blue: 0.10),
        checkmarkColor: Color(red: 0.35, green: 0.80, blue: 0.30),
        freezeColor: Color(red: 0.30, green: 0.65, blue: 0.95),
        trophyColor: Color(red: 0.98, green: 0.78, blue: 0.20),
        background: Color.streakSystemBackground,
        cardBackground: Color.streakSecondarySystemBackground,
        primaryText: Color.streakLabel,
        secondaryText: Color.streakSecondaryLabel,
        headlineFont: .system(size: 72, weight: .heavy, design: .rounded),
        titleFont: .system(.title2, design: .rounded).weight(.bold),
        bodyFont: .system(.body, design: .rounded),
        captionFont: .system(.caption, design: .rounded).weight(.semibold)
    )

    /// Healora brand theme: teal flame, dawn-gold accents.
    static let healora = StreakTheme(
        flameGradient: Gradient(colors: [
            Color(red: 0.60, green: 0.95, blue: 0.90),
            Color(red: 0.20, green: 0.75, blue: 0.75),
            Color(red: 0.10, green: 0.50, blue: 0.65)
        ]),
        flameInactiveColor: Color.gray.opacity(0.55),
        flameMilestoneGradient: Gradient(colors: [
            Color(red: 1.00, green: 0.92, blue: 0.65),
            Color(red: 1.00, green: 0.78, blue: 0.30),
            Color(red: 0.85, green: 0.55, blue: 0.10)
        ]),
        glowColor: Color(red: 0.20, green: 0.75, blue: 0.75),
        checkmarkColor: Color(red: 0.20, green: 0.75, blue: 0.65),
        freezeColor: Color(red: 0.40, green: 0.70, blue: 0.95),
        trophyColor: Color(red: 0.95, green: 0.75, blue: 0.25),
        background: Color.streakSystemBackground,
        cardBackground: Color.streakSecondarySystemBackground,
        primaryText: Color.streakLabel,
        secondaryText: Color.streakSecondaryLabel,
        headlineFont: .system(size: 72, weight: .heavy, design: .rounded),
        titleFont: .system(.title2, design: .rounded).weight(.bold),
        bodyFont: .system(.body, design: .rounded),
        captionFont: .system(.caption, design: .rounded).weight(.semibold)
    )

    /// Aurielle brand theme: soft purple flame.
    static let aurielle = StreakTheme(
        flameGradient: Gradient(colors: [
            Color(red: 0.95, green: 0.75, blue: 1.00),
            Color(red: 0.70, green: 0.45, blue: 0.95),
            Color(red: 0.45, green: 0.20, blue: 0.75)
        ]),
        flameInactiveColor: Color.gray.opacity(0.55),
        flameMilestoneGradient: Gradient(colors: [
            Color(red: 1.00, green: 0.85, blue: 1.00),
            Color(red: 0.85, green: 0.55, blue: 1.00),
            Color(red: 0.55, green: 0.25, blue: 0.85)
        ]),
        glowColor: Color(red: 0.70, green: 0.45, blue: 0.95),
        checkmarkColor: Color(red: 0.55, green: 0.85, blue: 0.55),
        freezeColor: Color(red: 0.45, green: 0.70, blue: 0.95),
        trophyColor: Color(red: 0.98, green: 0.78, blue: 0.20),
        background: Color.streakSystemBackground,
        cardBackground: Color.streakSecondarySystemBackground,
        primaryText: Color.streakLabel,
        secondaryText: Color.streakSecondaryLabel,
        headlineFont: .system(size: 72, weight: .heavy, design: .rounded),
        titleFont: .system(.title2, design: .rounded).weight(.bold),
        bodyFont: .system(.body, design: .rounded),
        captionFont: .system(.caption, design: .rounded).weight(.semibold)
    )
}

extension Color {
    static var streakSystemBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(.systemBackground)
        #elseif canImport(AppKit)
        return Color(.windowBackgroundColor)
        #else
        return Color.black
        #endif
    }

    static var streakSecondarySystemBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }

    static var streakLabel: Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(.label)
        #elseif canImport(AppKit)
        return Color(.labelColor)
        #else
        return Color.primary
        #endif
    }

    static var streakSecondaryLabel: Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(.secondaryLabel)
        #elseif canImport(AppKit)
        return Color(.secondaryLabelColor)
        #else
        return Color.secondary
        #endif
    }
}
