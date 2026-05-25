import SwiftUI

/// Full-screen celebration overlay shown when a streak milestone is reached.
///
/// Renders a scaled-up flame, the milestone count, congrats text, and confetti.
/// Auto-dismisses after `displayDuration` seconds via the supplied binding.
public struct MilestoneCelebrationView: View {
    private let length: Int
    @Binding private var isPresented: Bool
    private let displayDuration: Double

    @Environment(\.streakTheme) private var theme
    @State private var animateIn: Bool = false

    public init(
        length: Int,
        isPresented: Binding<Bool>,
        displayDuration: Double = 2.4
    ) {
        self.length = length
        self._isPresented = isPresented
        self.displayDuration = displayDuration
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                AnimatedFlameView(state: .milestone, size: 140, animated: true, interactive: false)
                    .scaleEffect(animateIn ? 1.0 : 0.4)
                    .opacity(animateIn ? 1 : 0)

                Text(verbatim: "\(length)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: theme.flameMilestoneGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(animateIn ? 1.0 : 0.6)
                    .opacity(animateIn ? 1 : 0)

                Text("MILESTONE!")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .opacity(animateIn ? 1 : 0)
            }
            .shadow(color: theme.glowColor.opacity(0.6), radius: 30)
        }
        .onAppear {
            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.3)) {
                animateIn = true
            }
            StreakHaptic.play(.success)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
                withAnimation(.smooth(duration: 0.4)) {
                    isPresented = false
                }
            }
        }
    }
}
