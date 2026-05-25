import Foundation
import MiraiStreakKit

#if canImport(WidgetKit)
import WidgetKit
#endif

/// A value-type snapshot of streak state for use in widget timeline entries.
///
/// Widgets must provide a `TimelineEntry`-conforming value to WidgetKit; this
/// struct wraps a `Streak` plus the milestone configuration so widget views
/// can render the correct flame state without holding a `StreakManager`.
public struct StreakWidgetEntry: Sendable, Codable, Equatable {
    /// The render-time anchor (typically `.now`).
    public let date: Date

    /// The streak data captured at `date`.
    public let streak: Streak

    /// Mirror of `StreakManager.Config.tokenMilestone` so the flame can switch to
    /// the milestone gradient.
    public let milestone: Int

    public init(date: Date, streak: Streak, milestone: Int = 7) {
        self.date = date
        self.streak = streak
        self.milestone = milestone
    }
}

#if canImport(WidgetKit)
extension StreakWidgetEntry: TimelineEntry {}
#endif

public extension StreakWidgetEntry {
    /// Loads the latest streak from a shared persistence store.
    ///
    /// Pair with `AppGroupStore` so widgets read the same data the host app writes.
    /// Returns an entry with an empty `Streak` if the store is empty or unreadable.
    static func current(
        from store: any StreakStore,
        date: Date = .now,
        milestone: Int = 7
    ) -> StreakWidgetEntry {
        let streak: Streak
        if let data = store.read() {
            streak = (try? JSONDecoder().decode(Streak.self, from: data)) ?? Streak()
        } else {
            streak = Streak()
        }
        return StreakWidgetEntry(date: date, streak: streak, milestone: milestone)
    }

    /// A placeholder entry useful for `TimelineProvider.placeholder(in:)`.
    static func placeholder(date: Date = .now, milestone: Int = 7) -> StreakWidgetEntry {
        StreakWidgetEntry(
            date: date,
            streak: Streak(length: 7, lastDate: date, bestStreak: 14, freezeTokens: 2),
            milestone: milestone
        )
    }
}
