import SwiftUI
import MiraiStreakKit

/// The signature animated flame for `MiraiStreakKitUI`.
///
/// Renders a gradient-masked flame with a soft glow halo. When `animated` is
/// true, the flame breathes via `PhaseAnimator` (scale + glow opacity). When
/// `interactive` is true, tapping the flame triggers a bouncy scale-up and a
/// haptic.
///
/// The same view is used in screens (large size + animated) and widgets
/// (smaller size + static).
public struct AnimatedFlameView: View {
    public enum State: Sendable, Equatable {
        case active
        case milestone
        case broken
    }

    private let state: State
    private let size: CGFloat
    private let animated: Bool
    private let interactive: Bool

    @Environment(\.streakTheme) private var theme
    @SwiftUI.State private var bouncePhase: Bool = false

    public init(
        state: State,
        size: CGFloat = 120,
        animated: Bool = true,
        interactive: Bool = false
    ) {
        self.state = state
        self.size = size
        self.animated = animated
        self.interactive = interactive
    }

    /// Convenience initializer that derives state from a `Streak`.
    public init(
        streak: Streak,
        milestone: Int = 7,
        size: CGFloat = 120,
        animated: Bool = true,
        interactive: Bool = false
    ) {
        let resolved: State = {
            if streak.length <= 0 { return .broken }
            if milestone > 0 && streak.length >= milestone { return .milestone }
            return .active
        }()
        self.init(state: resolved, size: size, animated: animated, interactive: interactive)
    }

    public var body: some View {
        Group {
            if animated {
                PhaseAnimator([0, 1, 2]) { phase in
                    flameStack(phase: phase)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }
            } else {
                flameStack(phase: 1)
            }
        }
        .scaleEffect(bouncePhase ? 1.18 : 1.0)
        .rotationEffect(state == .broken ? .degrees(-10) : .zero)
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            StreakHaptic.play(.medium)
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.35)) {
                bouncePhase = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                    bouncePhase = false
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func flameStack(phase: Int) -> some View {
        let scale = scaleForPhase(phase)
        let glowOpacity = glowOpacityForPhase(phase)

        ZStack {
            // Glow halo
            if state != .broken {
                Image(systemName: "flame.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(theme.glowColor)
                    .blur(radius: size * 0.18)
                    .opacity(glowOpacity)
                    .scaleEffect(scale * 1.05)
            }

            // Flame body
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(flameStyle)
                .scaleEffect(scale)
                .shadow(
                    color: state == .broken ? .clear : theme.glowColor.opacity(0.4),
                    radius: size * 0.08,
                    x: 0,
                    y: size * 0.02
                )
        }
    }

    private var flameStyle: AnyShapeStyle {
        switch state {
        case .active:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: theme.flameGradient,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        case .milestone:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: theme.flameMilestoneGradient,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        case .broken:
            return AnyShapeStyle(theme.flameInactiveColor)
        }
    }

    private func scaleForPhase(_ phase: Int) -> CGFloat {
        guard animated, state != .broken else { return 1.0 }
        switch phase {
        case 0: return 1.00
        case 1: return 1.05
        case 2: return 0.97
        default: return 1.0
        }
    }

    private func glowOpacityForPhase(_ phase: Int) -> CGFloat {
        guard animated else { return state == .milestone ? 0.7 : 0.5 }
        let base: CGFloat = state == .milestone ? 0.65 : 0.45
        switch phase {
        case 0: return base
        case 1: return base + 0.25
        case 2: return base + 0.05
        default: return base
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .active:    return "Active streak"
        case .milestone: return "Milestone streak"
        case .broken:    return "Streak broken"
        }
    }
}
