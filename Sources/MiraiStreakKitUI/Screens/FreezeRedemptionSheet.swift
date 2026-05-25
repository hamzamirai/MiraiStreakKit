import SwiftUI
import MiraiStreakKit

/// A modal sheet for redeeming a freeze token to protect a broken streak.
///
/// Shows the available token count, eligibility, and a primary action that
/// calls `manager.useFreeze()` from the environment.
public struct FreezeRedemptionSheet: View {
    @Environment(StreakManager.self) private var manager
    @Environment(\.streakTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var didRedeem = false

    public init() {}

    public var body: some View {
        let count = manager.getFreezeTokens()
        let canRedeem = manager.canUseFreeze()

        VStack(spacing: 24) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(theme.freezeColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: "snowflake")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(theme.freezeColor)
                    .scaleEffect(didRedeem ? 1.2 : 1.0)
                    .opacity(didRedeem ? 0.4 : 1.0)
                    .animation(.bouncy(duration: 0.6), value: didRedeem)
            }

            VStack(spacing: 8) {
                Text("Freeze Tokens")
                    .font(theme.titleFont)
                    .foregroundStyle(theme.primaryText)

                Text(verbatim: "\(count) available")
                    .font(theme.bodyFont)
                    .foregroundStyle(theme.secondaryText)
            }

            Text(messageText(count: count, canRedeem: canRedeem, didRedeem: didRedeem))
                .multilineTextAlignment(.center)
                .font(theme.bodyFont)
                .foregroundStyle(theme.secondaryText)
                .padding(.horizontal, 32)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button {
                    redeem()
                } label: {
                    Text(didRedeem ? "Streak Saved!" : "Use Freeze Token")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            (canRedeem && !didRedeem) ? theme.freezeColor : theme.freezeColor.opacity(0.4),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!canRedeem || didRedeem)

                Button {
                    dismiss()
                } label: {
                    Text(didRedeem ? "Done" : "Not Now")
                        .font(theme.bodyFont.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
        .background(theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func redeem() {
        guard manager.useFreeze() else { return }
        StreakHaptic.play(.success)
        withAnimation(.bouncy(duration: 0.6)) {
            didRedeem = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            dismiss()
        }
    }

    private func messageText(count: Int, canRedeem: Bool, didRedeem: Bool) -> LocalizedStringKey {
        if didRedeem {
            return "Your streak is safe. Keep it going tomorrow!"
        }
        if count == 0 {
            return "Earn freeze tokens by hitting streak milestones — they protect your streak when you miss a day."
        }
        if canRedeem {
            return "Use a token to save your streak from breaking."
        }
        return "You're all caught up — no freeze needed right now."
    }
}
