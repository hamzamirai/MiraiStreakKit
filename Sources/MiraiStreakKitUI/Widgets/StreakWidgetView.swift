import SwiftUI
import MiraiStreakKit

#if canImport(WidgetKit)
import WidgetKit

/// The main entry-point view for streak widgets.
///
/// Place this in your `Widget`'s body and pass a `StreakWidgetEntry`. The view
/// automatically dispatches to the right family-specific subview based on
/// `\.widgetFamily`.
///
/// ```swift
/// struct StreakWidget: Widget {
///     var body: some WidgetConfiguration {
///         StaticConfiguration(kind: "StreakWidget", provider: Provider()) { entry in
///             StreakWidgetView(entry: entry)
///                 .streakTheme(.duolingo)
///                 .streakWidgetContainer(theme: .duolingo)
///         }
///     }
/// }
/// ```
@available(iOS 17.0, macOS 14.0, watchOS 10.0, visionOS 26.0, *)
public struct StreakWidgetView: View {
    private let entry: StreakWidgetEntry

    @Environment(\.widgetFamily) private var family

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            StreakSmallWidget(entry: entry)
        case .systemMedium:
            StreakMediumWidget(entry: entry)
        case .systemLarge:
            StreakLargeWidget(entry: entry)
        #if os(iOS) || os(watchOS) || os(macOS)
        case .accessoryCircular:
            StreakAccessoryCircular(entry: entry)
        case .accessoryRectangular:
            StreakAccessoryRectangular(entry: entry)
        case .accessoryInline:
            StreakAccessoryInline(entry: entry)
        #endif
        default:
            StreakSmallWidget(entry: entry)
        }
    }
}
#else
/// Fallback that lets non-WidgetKit platforms compile cleanly.
public struct StreakWidgetView: View {
    private let entry: StreakWidgetEntry

    public init(entry: StreakWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        StreakSmallWidget(entry: entry)
    }
}
#endif

public extension View {
    /// Applies a widget-appropriate background using the given theme.
    ///
    /// On WidgetKit platforms (iOS 17+, macOS 14+, watchOS 10+, visionOS 26+)
    /// this uses `.containerBackground(for: .widget)`; elsewhere it falls back
    /// to a plain `.background`.
    @ViewBuilder
    func streakWidgetContainer(theme: StreakTheme = .duolingo) -> some View {
        #if canImport(WidgetKit)
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, visionOS 26.0, *) {
            self.containerBackground(theme.background, for: .widget)
        } else {
            self.background(theme.background)
        }
        #else
        self.background(theme.background)
        #endif
    }
}
