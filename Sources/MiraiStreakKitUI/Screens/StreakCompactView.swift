import SwiftUI
import MiraiStreakKit

/// A small themed pill showing the current streak — perfect for nav bars and tab headers.
///
/// Drop-in replacement for `MiraiStreakKit.StreakView` that picks up the active `StreakTheme`.
public struct StreakCompactView: View {
    @Environment(StreakManager.self) private var manager
    @Environment(\.streakTheme) private var theme

    public init() {}

    public var body: some View {
        let length = manager.getStreakLength()
        let state: AnimatedFlameView.State = {
            if length <= 0 { return .broken }
            if manager.config.tokenMilestone > 0 && length >= manager.config.tokenMilestone {
                return .milestone
            }
            return .active
        }()

        HStack(spacing: 6) {
            AnimatedFlameView(state: state, size: 22, animated: true, interactive: false)
            Text(verbatim: "\(length)")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(theme.primaryText)
                .contentTransition(.numericText(value: Double(length)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.cardBackground, in: Capsule())
        .animation(.smooth(duration: 0.4), value: length)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Streak \(length) days"))
    }
}
