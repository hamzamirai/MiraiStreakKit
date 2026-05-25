import SwiftUI
import MiraiStreakKit

#if canImport(WidgetKit)
import WidgetKit
#endif

/// Lock-screen / Smart Stack circular accessory: flame + streak length.
public struct StreakAccessoryCircular: View {
    private let entry: StreakWidgetEntry

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        ZStack {
            #if canImport(WidgetKit)
            if #available(iOS 16.0, macOS 13.0, watchOS 9.0, visionOS 26.0, *) {
                AccessoryWidgetBackground()
            } else {
                Circle().fill(Color.gray.opacity(0.2))
            }
            #else
            Circle().fill(Color.gray.opacity(0.2))
            #endif
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(verbatim: "\(entry.streak.length)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .minimumScaleFactor(0.5)
            }
        }
        .accessibilityLabel(Text("Streak \(entry.streak.length) days"))
    }
}

/// Lock-screen rectangular accessory: flame + streak length + best.
public struct StreakAccessoryRectangular: View {
    private let entry: StreakWidgetEntry

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(verbatim: "\(entry.streak.length)")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                    Text("days")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                Text(verbatim: "Best \(entry.streak.bestStreak) · ❄ \(entry.streak.freezeTokens)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(Text("Streak \(entry.streak.length) days, best \(entry.streak.bestStreak)"))
    }
}

/// Lock-screen inline accessory: a single line.
public struct StreakAccessoryInline: View {
    private let entry: StreakWidgetEntry

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        Label {
            Text(verbatim: "\(entry.streak.length) day streak")
        } icon: {
            Image(systemName: "flame.fill")
        }
    }
}
