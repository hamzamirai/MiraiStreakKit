import SwiftUI

/// A keyframe-driven confetti overlay.
///
/// Drop into any view as a fire-and-forget overlay; emits `count` particles
/// that fall, fade, and rotate over `duration` seconds.
public struct ConfettiView: View {
    private let count: Int
    private let duration: Double
    private let palette: [Color]

    public init(
        count: Int = 36,
        duration: Double = 1.6,
        palette: [Color] = [
            Color(red: 1.00, green: 0.65, blue: 0.20),
            Color(red: 0.95, green: 0.30, blue: 0.30),
            Color(red: 0.30, green: 0.75, blue: 0.45),
            Color(red: 0.30, green: 0.65, blue: 0.95),
            Color(red: 0.95, green: 0.85, blue: 0.30),
            Color(red: 0.75, green: 0.45, blue: 0.95)
        ]
    ) {
        self.count = count
        self.duration = duration
        self.palette = palette
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    Particle(
                        index: index,
                        size: proxy.size,
                        duration: duration,
                        color: palette[index % palette.count]
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private struct Particle: View {
        let index: Int
        let size: CGSize
        let duration: Double
        let color: Color

        var body: some View {
            let startX = randomX(seed: index)
            let endX = startX + driftX(seed: index)
            let endY = size.height + 80
            let rotationEnd = Double(((index &* 137) % 360) + 540) // 540°-900°
            let shape = Shape.fromIndex(index)
            let widthValue = CGFloat(8 + (index % 5))
            let heightValue = CGFloat(12 + ((index &* 31) % 10))

            shape
                .fill(color)
                .frame(width: widthValue, height: heightValue)
                .keyframeAnimator(
                    initialValue: ParticleState(
                        x: startX,
                        y: -40,
                        rotation: 0,
                        opacity: 1
                    )
                ) { content, state in
                    content
                        .position(x: state.x, y: state.y)
                        .rotationEffect(.degrees(state.rotation))
                        .opacity(state.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.x) {
                        CubicKeyframe(endX, duration: duration)
                    }
                    KeyframeTrack(\.y) {
                        CubicKeyframe(endY, duration: duration)
                    }
                    KeyframeTrack(\.rotation) {
                        LinearKeyframe(rotationEnd, duration: duration)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1.0, duration: duration * 0.7)
                        LinearKeyframe(0.0, duration: duration * 0.3)
                    }
                }
        }

        private func randomX(seed: Int) -> CGFloat {
            let normalized = CGFloat((seed &* 2_654_435_761) % 1000) / 1000.0
            return normalized * size.width
        }

        private func driftX(seed: Int) -> CGFloat {
            let normalized = CGFloat((seed &* 1_597_334_677) % 1000) / 1000.0
            return (normalized - 0.5) * 160
        }
    }

    private struct ParticleState {
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var opacity: Double
    }

    private enum Shape {
        case rectangle, capsule, circle

        @ViewBuilder
        func fill<S: ShapeStyle>(_ style: S) -> some View {
            switch self {
            case .rectangle: RoundedRectangle(cornerRadius: 1.5).fill(style)
            case .capsule:   Capsule().fill(style)
            case .circle:    Circle().fill(style)
            }
        }

        static func fromIndex(_ i: Int) -> Shape {
            switch i % 3 {
            case 0:  return .rectangle
            case 1:  return .capsule
            default: return .circle
            }
        }
    }
}
