import Foundation
import Observation

/// The main observable class for managing streak state.
///
/// `StreakManager` is isolated to the `@MainActor` for safe SwiftUI integration.
/// It uses Swift's Observation framework, so SwiftUI views automatically update
/// when the streak changes.
///
/// ## Example
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .setupMiraiStreak()
///         }
///     }
/// }
///
/// struct ContentView: View {
///     @Environment(StreakManager.self) private var manager
///
///     var body: some View {
///         VStack {
///             Text("Streak: \(manager.getStreakLength())")
///             Button("Check In") {
///                 manager.updateStreak()
///             }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
public final class StreakManager {
    /// Configuration for the streak manager.
    public struct Config: Sendable, Equatable {
        /// The calendar to use for date comparisons.
        public var calendar: Calendar

        /// The streak length at which a freeze token is earned.
        /// Set to 0 to disable freeze token earning. Defaults to 7 days.
        public var tokenMilestone: Int

        /// Creates a new configuration.
        ///
        /// - Parameters:
        ///   - calendar: The calendar to use. Defaults to the current calendar.
        ///   - tokenMilestone: The streak length for earning freeze tokens. Defaults to 7 days.
        public init(calendar: Calendar = .current, tokenMilestone: Int = 7) {
            self.calendar = calendar
            self.tokenMilestone = tokenMilestone
        }
    }

    /// The current streak data (observable).
    ///
    /// SwiftUI views that read this property will automatically update when it changes.
    public private(set) var streak: Streak

    /// The manager's configuration.
    public var config: Config

    /// Optional analytics delegate for tracking streak events.
    ///
    /// Set this to receive notifications about important streak events
    /// such as updates, milestones, breaks, and freeze token usage.
    public weak var analyticsDelegate: (any StreakAnalyticsDelegate)?

    private let store: any StreakStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a new streak manager.
    ///
    /// - Parameters:
    ///   - store: The persistence store to use. Defaults to `UserDefaultsStore()`.
    ///   - config: The manager configuration. Defaults to `.init()`.
    public init(
        store: any StreakStore = UserDefaultsStore(),
        config: Config = .init()
    ) {
        self.store = store
        self.config = config
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.streak = Self.load(from: store, using: decoder) ?? Streak()
    }

    /// Updates the streak for a given date.
    ///
    /// This method:
    /// - Does nothing if already completed today
    /// - Increments the streak if continuing from yesterday
    /// - Resets to 1 if the streak was broken
    /// - Automatically updates best streak if current exceeds it
    /// - Awards freeze tokens at milestone intervals
    /// - Fires analytics events for tracking
    ///
    /// Changes are automatically persisted to the store.
    ///
    /// - Parameter date: The date to update for. Defaults to the current date.
    public func updateStreak(on date: Date = .now) {
        let previousLength = streak.length
        let previousBest = streak.bestStreak
        var streakWasBroken = false

        switch streak.determineOutcome(on: date, calendar: config.calendar) {
        case .alreadyCompletedToday:
            return
        case .streakContinues:
            streak.lastDate = date
            streak.length += 1
            streak.completedDates.append(
                config.calendar.startOfDay(for: date)
            )
        case .streakBroken:
            streakWasBroken = true
            streak.lastDate = date
            streak.length = 1
            streak.completedDates.append(
                config.calendar.startOfDay(for: date)
            )
        }

        let isNewStreak = streak.length == 1

        // Fire streak broken event
        if streakWasBroken && previousLength > 0 {
            analyticsDelegate?.streakEventOccurred(
                .streakBroken(previousLength: previousLength, bestStreak: previousBest),
                manager: self
            )
        }

        // Update best streak if current streak exceeds it
        if streak.length > streak.bestStreak {
            streak.bestStreak = streak.length

            // Fire new best streak event
            if streak.length > previousBest {
                analyticsDelegate?.streakEventOccurred(
                    .newBestStreakAchieved(newBest: streak.length, previousBest: previousBest),
                    manager: self
                )
            }
        }

        // Award freeze token at milestones
        var earnedToken = false
        if config.tokenMilestone > 0 &&
           streak.length % config.tokenMilestone == 0 &&
           streak.length > previousLength {
            streak.freezeTokens += 1
            earnedToken = true
        }

        // Fire milestone event if at milestone
        if config.tokenMilestone > 0 &&
           streak.length % config.tokenMilestone == 0 &&
           streak.length > 0 {
            analyticsDelegate?.streakEventOccurred(
                .milestoneReached(length: streak.length, earnedToken: earnedToken),
                manager: self
            )
        }

        // Fire streak updated event
        analyticsDelegate?.streakEventOccurred(
            .streakUpdated(length: streak.length, isNewStreak: isNewStreak),
            manager: self
        )

        save()
    }

    /// Gets the current streak length, resetting if broken.
    ///
    /// This method checks if the streak is still valid. If it has been broken
    /// (a day was skipped), it resets the streak to 0 and persists the change.
    ///
    /// - Parameter date: The date to check against. Defaults to the current date.
    /// - Returns: The current streak length (may be 0 if broken).
    @discardableResult
    public func getStreakLength(on date: Date = .now) -> Int {
        if streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken {
            streak.length = 0
            streak.lastDate = nil
            save()
        }

        return streak.length
    }

    /// Checks if the streak has been completed on a given date.
    ///
    /// - Parameter date: The date to check. Defaults to the current date.
    /// - Returns: `true` if a check-in occurred on the given date, `false` otherwise.
    public func hasCompletedStreak(on date: Date = .now) -> Bool {
        guard let lastDate = streak.lastDate else {
            return false
        }

        return config.calendar.isDate(date, inSameDayAs: lastDate)
    }

    /// Gets the best (longest) streak ever achieved.
    ///
    /// - Returns: The best streak length.
    public func getBestStreak() -> Int {
        return streak.bestStreak
    }

    /// Uses a freeze token to protect the streak from breaking.
    ///
    /// This method should be called when a user wants to use a freeze token
    /// to prevent their streak from resetting after missing a day.
    ///
    /// A freeze can only be used if:
    /// - The user has available freeze tokens
    /// - The streak is currently broken (missed days exist)
    /// - A freeze hasn't already been used for this gap
    ///
    /// - Parameter date: The date to apply the freeze for. Defaults to the current date.
    /// - Returns: `true` if the freeze was successfully applied, `false` otherwise.
    @discardableResult
    public func useFreeze(on date: Date = .now) -> Bool {
        // Check if user has tokens
        guard streak.freezeTokens > 0 else {
            return false
        }

        // Check if streak is broken
        guard streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken else {
            return false
        }

        // Check if freeze already used for this gap
        if let lastFreezeDate = streak.lastFreezeDate,
           let lastDate = streak.lastDate,
           config.calendar.isDate(lastFreezeDate, inSameDayAs: lastDate) {
            return false
        }

        // Use the freeze token
        streak.freezeTokens -= 1
        streak.lastFreezeDate = date
        streak.lastDate = date
        // Don't increment length - just maintain it

        // Fire freeze token used event
        analyticsDelegate?.streakEventOccurred(
            .freezeTokenUsed(tokensRemaining: streak.freezeTokens),
            manager: self
        )

        save()
        return true
    }

    /// Checks if a freeze token can be used for the current streak state.
    ///
    /// - Parameter date: The date to check for. Defaults to the current date.
    /// - Returns: `true` if a freeze token can be used, `false` otherwise.
    public func canUseFreeze(on date: Date = .now) -> Bool {
        guard streak.freezeTokens > 0 else {
            return false
        }

        guard streak.determineOutcome(on: date, calendar: config.calendar) == .streakBroken else {
            return false
        }

        if let lastFreezeDate = streak.lastFreezeDate,
           let lastDate = streak.lastDate,
           config.calendar.isDate(lastFreezeDate, inSameDayAs: lastDate) {
            return false
        }

        return true
    }

    /// Gets the number of available freeze tokens.
    ///
    /// - Returns: The number of freeze tokens.
    public func getFreezeTokens() -> Int {
        return streak.freezeTokens
    }

    /// Recomputes the entire streak from a source-of-truth list of completed calendar days.
    ///
    /// Unlike `updateStreak(on:)`, which incrementally advances the streak for a single
    /// check-in, this method rebuilds `length`, `lastDate`, `bestStreak`, and `completedDates`
    /// from scratch based on the full history of completed days. Use this whenever completions
    /// can be logged or edited out of order (e.g. backfilling or editing a past day), since the
    /// incremental approach only ever accounts for the most recent check-in.
    ///
    /// Freeze tokens (`freezeTokens`, `lastFreezeDate`) are left untouched. Changes are
    /// automatically persisted to the store.
    ///
    /// - Parameters:
    ///   - completedDays: Every calendar day the user completed their goal. Need not be sorted or deduplicated.
    ///   - date: The reference "today" used to decide whether the streak is still active. Defaults to now.
    public func recompute(fromCompletedDays completedDays: [Date], on date: Date = .now) {
        let calendar = config.calendar
        let sortedDays = Set(completedDays.map { calendar.startOfDay(for: $0) }).sorted()
        let previousBest = streak.bestStreak

        guard !sortedDays.isEmpty else {
            streak.length = 0
            streak.lastDate = nil
            streak.completedDates = []
            save()
            return
        }

        var bestRun = 1
        var runLength = 1
        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i - 1]
            let currentDay = sortedDays[i]
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: currentDay) {
                runLength += 1
                bestRun = max(bestRun, runLength)
            } else {
                runLength = 1
            }
        }

        var activeRun = 1
        var index = sortedDays.count - 1
        while index > 0 {
            let currentDay = sortedDays[index]
            let previousDay = sortedDays[index - 1]
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: currentDay),
                  calendar.isDate(dayBefore, inSameDayAs: previousDay) else {
                break
            }
            activeRun += 1
            index -= 1
        }

        let lastDay = sortedDays[sortedDays.count - 1]
        let today = calendar.startOfDay(for: date)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let streakIsActive = calendar.isDate(lastDay, inSameDayAs: today) ||
                              calendar.isDate(lastDay, inSameDayAs: yesterday)
        let currentLength = streakIsActive ? activeRun : 0

        streak.length = currentLength
        streak.lastDate = lastDay
        streak.bestStreak = max(bestRun, currentLength, previousBest)
        streak.completedDates = sortedDays

        if streak.bestStreak > previousBest {
            analyticsDelegate?.streakEventOccurred(
                .newBestStreakAchieved(newBest: streak.bestStreak, previousBest: previousBest),
                manager: self
            )
        }

        analyticsDelegate?.streakEventOccurred(
            .streakUpdated(length: streak.length, isNewStreak: false),
            manager: self
        )

        save()
    }

    private func save() {
        guard let data = try? encoder.encode(streak) else { return }
        try? store.write(data)
    }

    private static func load(from store: any StreakStore, using decoder: JSONDecoder) -> Streak? {
        guard let data = store.read() else { return nil }
        return try? decoder.decode(Streak.self, from: data)
    }
}
