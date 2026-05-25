import SwiftUI

/// A snowflake badge showing the count of available freeze tokens.
public struct FreezeTokenBadge: View {
    private let count: Int
    private let compact: Bool

    @Environment(\.streakTheme) private var theme

    public init(count: Int, compact: Bool = false) {
        self.count = count
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "snowflake")
                .font(.system(size: compact ? 13 : 17, weight: .bold))
                .foregroundStyle(theme.freezeColor)
            Text(verbatim: "\(count)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(theme.primaryText)
                .contentTransition(.numericText(value: Double(count)))
                .animation(.smooth(duration: 0.3), value: count)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .background(theme.cardBackground, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(count) freeze tokens"))
    }
}
