import SwiftUI
import MiraiStreakKit

/// The full Duolingo-style streak detail screen.
///
/// Composes the animated flame, big number, week strip, badges, heatmap, and
/// a primary "Check In" CTA. Tapping the freeze badge presents the redemption
/// sheet; hitting a milestone triggers the celebration overlay.
public struct StreakDetailView: View {
    @Environment(StreakManager.self) private var manager
    @Environment(\.streakTheme) private var theme

    @State private var showingCelebration = false
    @State private var celebrationLength = 0
    @State private var showingFreezeSheet = false

    public init() {}

    public var body: some View {
        let length = manager.getStreakLength()
        let alreadyCheckedIn = manager.hasCompletedStreak()

        return ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    AnimatedFlameView(
                        streak: manager.streak,
                        milestone: manager.config.tokenMilestone,
                        size: 160,
                        animated: true,
                        interactive: true
                    )
                    .padding(.top, 24)

                    VStack(spacing: 4) {
                        StreakNumberView(length: length)
                        Text("day streak")
                            .font(theme.titleFont)
                            .foregroundStyle(theme.secondaryText)
                            .textCase(.uppercase)
                            .tracking(2)
                    }

                    WeekStripView(streak: manager.streak)
                        .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        BestStreakBadge(best: manager.getBestStreak())
                        FreezeTokenBadge(count: manager.getFreezeTokens())
                            .onTapGesture {
                                showingFreezeSheet = true
                            }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your year so far")
                            .font(theme.titleFont)
                            .foregroundStyle(theme.primaryText)
                        StreakHeatmapView(streak: manager.streak, weeks: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)

                    checkInButton(disabled: alreadyCheckedIn)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }

            if showingCelebration {
                MilestoneCelebrationView(
                    length: celebrationLength,
                    isPresented: $showingCelebration
                )
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.4), value: showingCelebration)
        .sheet(isPresented: $showingFreezeSheet) {
            FreezeRedemptionSheet()
                .streakTheme(theme)
        }
    }

    @ViewBuilder
    private func checkInButton(disabled: Bool) -> some View {
        Button {
            performCheckIn()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: disabled ? "checkmark.seal.fill" : "flame.fill")
                Text(disabled ? "Done for Today" : "Check In")
            }
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                disabled
                    ? AnyShapeStyle(Color.gray.opacity(0.5))
                    : AnyShapeStyle(
                        LinearGradient(
                            gradient: theme.flameGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(
                color: disabled ? .clear : theme.glowColor.opacity(0.4),
                radius: 12,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func performCheckIn() {
        let previousLength = manager.streak.length
        manager.updateStreak()
        StreakHaptic.play(.medium)

        let newLength = manager.streak.length
        let milestone = manager.config.tokenMilestone
        let crossedMilestone = newLength > previousLength
            && milestone > 0
            && newLength % milestone == 0

        if crossedMilestone {
            celebrationLength = newLength
            withAnimation(.smooth(duration: 0.4)) {
                showingCelebration = true
            }
        }
    }
}
