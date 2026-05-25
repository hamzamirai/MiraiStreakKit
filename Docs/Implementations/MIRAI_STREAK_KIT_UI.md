# Build MiraiStreakKitUI — Duolingo-style UI + Widget Views

## Context

`MiraiStreakKit` (at `/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit`) currently ships:
- A solid pure-logic core: `Streak` model with `completedDates`, `StreakManager` (`@Observable` `@MainActor`), `StreakStore` protocol with three implementations, `StreakAnalyticsDelegate`, freeze-token system, milestone tracking, best-streak tracking.
- A single minimal `StreakView` (~40 lines): a flame icon + number in a capsule. Functional, but not on par with Duolingo.

The user wants a Duolingo-grade UI layer: animated flame, week strip, full-screen detail view, milestone celebration, freeze redemption — and **widget views** that share the same look in WidgetKit extensions. The core logic stays untouched; this is purely a new SwiftUI module that builds on top.

**Outcome:** any MiraiDevs app (Healora, Aurielle, FindMyBook, TimeTogether, SpatialWorlds) can `import MiraiStreakKitUI` and drop in a Duolingo-quality streak experience in both app and widget targets, themed to match the app's brand.

## Architecture

### Package layout

Add a second target + product to `Package.swift`:

```
MiraiStreakKit/
├── Sources/
│   ├── MiraiStreakKit/        ← unchanged (pure logic)
│   └── MiraiStreakKitUI/      ← NEW (SwiftUI + animations + widget views)
└── Tests/
    ├── MiraiStreakKitTests/   ← unchanged
    └── MiraiStreakKitUITests/ ← NEW
```

`Package.swift` changes:
- Add `.library(name: "MiraiStreakKitUI", targets: ["MiraiStreakKitUI"])`
- Add `.target(name: "MiraiStreakKitUI", dependencies: ["MiraiStreakKit"])`
- Add `.testTarget(name: "MiraiStreakKitUITests", dependencies: ["MiraiStreakKitUI"])`
- Bump platforms: `.watchOS(.v10)` added for widget reach (Liquid Glass / accessory widgets). Existing iOS 17 / macOS 14 / visionOS 2 unchanged.

The existing `StreakView` in `Sources/MiraiStreakKit/StreakView.swift` and `SwiftUI+Integration.swift` stay where they are (back-compat), and `MiraiStreakKitUI` re-exports nothing from them — apps can import either or both.

### Module structure

```
Sources/MiraiStreakKitUI/
├── Theme/
│   ├── StreakTheme.swift              ← color palette, gradients, fonts
│   └── EnvironmentValues+Theme.swift  ← .streakTheme(_:) modifier
├── Components/
│   ├── AnimatedFlameView.swift        ← gradient flame + PhaseAnimator pulse + glow
│   ├── StreakNumberView.swift         ← big rounded digit with .contentTransition(.numericText)
│   ├── WeekStripView.swift            ← Mon–Sun row with checkmarks
│   ├── StreakHeatmapView.swift        ← N-week contribution-graph grid
│   ├── FreezeTokenBadge.swift         ← snowflake + count
│   └── BestStreakBadge.swift          ← trophy + best
├── Screens/
│   ├── StreakDetailView.swift         ← full Duolingo screen w/ Check-In CTA
│   ├── StreakCompactView.swift        ← upgraded top-bar capsule (themed)
│   └── FreezeRedemptionSheet.swift    ← sheet that calls manager.useFreeze()
├── Effects/
│   ├── ConfettiEffect.swift           ← KeyframeAnimator confetti modifier
│   └── MilestoneCelebrationView.swift ← scale + confetti overlay
├── Widgets/
│   ├── StreakWidgetEntry.swift        ← Codable snapshot for TimelineEntry
│   ├── StreakWidgetView.swift         ← entry-point view, dispatches by family
│   ├── StreakSmallWidget.swift        ← flame + number
│   ├── StreakMediumWidget.swift       ← flame + week strip
│   ├── StreakLargeWidget.swift        ← flame + heatmap + best
│   └── StreakAccessoryWidgets.swift   ← circular / rectangular / inline lock-screen
└── Previews/
    └── StreakPreviewSupport.swift     ← #if DEBUG mock data + InMemoryStore
```

Widget views import `WidgetKit` under `#if canImport(WidgetKit)` and use `WidgetFamily` to dispatch. They take a value-type `StreakWidgetEntry` (built from `Streak`) — never a `StreakManager` — so they are safe inside widget extensions where `@Observable` state isn't available across timeline reloads.

## Design details

### `StreakTheme` (configurable)

```swift
public struct StreakTheme: Sendable, Equatable {
    public var flameGradient: Gradient        // active flame
    public var flameInactiveColor: Color      // grayscale when broken
    public var flameMilestoneGradient: Gradient // gold "Streak Society" past milestone
    public var checkmarkColor: Color          // green by default
    public var freezeColor: Color             // blue
    public var trophyColor: Color             // gold
    public var background: Color
    public var cardBackground: Color
    public var primaryText: Color
    public var secondaryText: Color
    public var headlineFont: Font             // .system(.largeTitle, design: .rounded).weight(.heavy)
    public var bodyFont: Font

    public static let duolingo: Self = .init(...)  // default
    public static let healora: Self = .init(...)   // teal/dawn-gold
    public static let aurielle: Self = .init(...)  // purple
}
```

Injected via `EnvironmentKey`:

```swift
public extension View {
    func streakTheme(_ theme: StreakTheme) -> some View
}
```

All UI components read `@Environment(\.streakTheme)`. Defaults to `.duolingo`.

### `AnimatedFlameView` (the centerpiece)

- Renders `Image(systemName: "flame.fill")` masked with a `LinearGradient(theme.flameGradient, ...)` + a soft `Image(systemName: "flame.fill").blur(radius:).opacity(0.6)` glow layer.
- Idle pulse via `PhaseAnimator([0, 1, 2])` driving scale `[1.0, 1.04, 0.98]` and glow opacity `[0.5, 0.7, 0.5]` over ~1.6s.
- On tap (when `interactive: true`): `withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3))` scale-up to 1.15 then back, fires haptic via `Haptic.impact(.medium)` (tiny internal helper, conditionally compiled to no-op on macOS/widgets).
- Three states: `.active` (gradient), `.broken` (grayscale + drooped via `.rotationEffect(.degrees(-8))`), `.milestone` (gold gradient, brighter glow). Resolved from `Streak` via init: `AnimatedFlameView(streak: streak, milestone: 7)`.
- Accepts `size: CGFloat` (default 120) so the same view scales from widget (40pt) to detail screen (160pt).

### `StreakNumberView`

- `Text(verbatim: "\(length)")` — **`verbatim:` per CLAUDE.md** (this is a computed value, not a localization key).
- `.font(theme.headlineFont)` and `.contentTransition(.numericText(value: Double(length)))` so increments roll smoothly.
- `.transaction { $0.animation = .smooth(duration: 0.4) }` wrapped around the data binding so SwiftUI animates length changes.

### `WeekStripView`

- 7 circles for the current week (locale-aware first weekday via `Calendar.current.firstWeekday`).
- Each day reads `streak.hasCompleted(on: date)` (already exists in core, [StreakCore.swift:146](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakCore.swift#L146)).
- States: completed → filled circle + checkmark in `theme.checkmarkColor`; today (incomplete) → outlined ring with primary color; future → dimmed; missed → dimmed with subtle `xmark`.
- Stagger-animate fill from leftmost completed → rightmost on appear: `.transition(.scale.combined(with: .opacity))` with `.delay(Double(index) * 0.05)`.

### `StreakHeatmapView`

- Renders last `weeks` weeks (default 12) as a grid: 7 rows × `weeks` cols.
- Cell color from `streak.hasCompleted(on: date)` (existing [StreakCore.swift:146](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakCore.swift#L146)) → `theme.checkmarkColor`; missed days → `theme.cardBackground.opacity(0.4)`; future → clear.
- 4 levels of intensity reserved for future use (multi-completion days) — for now binary, but cell uses `RoundedRectangle(cornerRadius: 3)` so it can extend later.

### `StreakDetailView` (the screen)

```swift
public struct StreakDetailView: View {
    @Environment(StreakManager.self) private var manager
    @Environment(\.streakTheme) private var theme
    @State private var showingCelebration = false
    @State private var showingFreezeSheet = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AnimatedFlameView(streak: manager.streak, size: 160)
                StreakNumberView(length: manager.getStreakLength())
                Text("day streak")
                WeekStripView(streak: manager.streak)
                HStack {
                    BestStreakBadge(best: manager.getBestStreak())
                    FreezeTokenBadge(count: manager.getFreezeTokens())
                        .onTapGesture { showingFreezeSheet = true }
                }
                StreakHeatmapView(streak: manager.streak, weeks: 12)
                Button("Check In") { performCheckIn() }
                    .disabled(manager.hasCompletedStreak())
            }
        }
        .overlay { if showingCelebration { MilestoneCelebrationView(...) } }
        .sheet(isPresented: $showingFreezeSheet) { FreezeRedemptionSheet() }
    }

    private func performCheckIn() {
        let prevLength = manager.streak.length
        manager.updateStreak()
        if manager.streak.length > prevLength,
           manager.config.tokenMilestone > 0,
           manager.streak.length % manager.config.tokenMilestone == 0 {
            showingCelebration = true
        }
    }
}
```

CTA wires directly to `manager.updateStreak()` ([StreakManager.swift:106](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakManager.swift#L106)). Freeze sheet calls `manager.useFreeze()` ([StreakManager.swift:230](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakManager.swift#L230)) and gates UI with `manager.canUseFreeze()` ([StreakManager.swift:268](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakManager.swift#L268)).

### `MilestoneCelebrationView` + `ConfettiEffect`

- Confetti driven by `KeyframeAnimator` — array of 30 particles each with random startX, hue, and rotation. Each particle's keyframes: `y` from -20 to +600 (CubicKeyframe), `opacity` 1→0 over last 30%, `rotation` 0→720°.
- Auto-dismisses after 1.8s via `.task { try? await Task.sleep(...); showingCelebration = false }`.
- Dimmed background `.background(.black.opacity(0.3))`.

### Widget views

```swift
public struct StreakWidgetEntry: TimelineEntry, Codable, Sendable {
    public let date: Date
    public let streak: Streak
    public let milestone: Int   // copy of config.tokenMilestone for UI cues
    public init(date: Date, streak: Streak, milestone: Int = 7)
}

#if canImport(WidgetKit)
import WidgetKit

public struct StreakWidgetView: View {
    public let entry: StreakWidgetEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.streakTheme) private var theme

    public var body: some View {
        switch family {
        case .systemSmall:        StreakSmallWidget(entry: entry)
        case .systemMedium:       StreakMediumWidget(entry: entry)
        case .systemLarge:        StreakLargeWidget(entry: entry)
        case .accessoryCircular:  StreakAccessoryCircular(entry: entry)
        case .accessoryRectangular: StreakAccessoryRectangular(entry: entry)
        case .accessoryInline:    StreakAccessoryInline(entry: entry)
        default:                  StreakSmallWidget(entry: entry)
        }
    }
}
#endif
```

Widget views are static (no `PhaseAnimator` — WidgetKit re-renders aren't continuous). They reuse `AnimatedFlameView` with `interactive: false, animated: false` so the same gradient/glow renders without driving timers.

The consumer's widget extension wraps with `.containerBackground(theme.background, for: .widget)`. Helper provided:

```swift
public extension View {
    @ViewBuilder
    func streakWidgetContainer(theme: StreakTheme = .duolingo) -> some View {
        #if canImport(WidgetKit)
        self.containerBackground(theme.background, for: .widget)
        #else
        self.background(theme.background)
        #endif
    }
}
```

### Helper: building entries in a widget timeline

```swift
public extension StreakWidgetEntry {
    /// Loads the latest streak from a shared App Group store.
    static func current(
        from store: any StreakStore,
        date: Date = .now,
        milestone: Int = 7
    ) -> StreakWidgetEntry {
        let streak: Streak = (try? JSONDecoder().decode(Streak.self, from: store.read() ?? Data())) ?? Streak()
        return StreakWidgetEntry(date: date, streak: streak, milestone: milestone)
    }
}
```

So widget timeline providers become:

```swift
struct Provider: TimelineProvider {
    let store = AppGroupStore(appGroup: "group.com.example.app")
    func getSnapshot(in: Context, completion: ...) {
        completion(StreakWidgetEntry.current(from: store))
    }
    func getTimeline(...) {
        let entry = StreakWidgetEntry.current(from: store)
        // refresh at next midnight so today/missed states stay accurate
        let nextMidnight = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}
```

## Critical files

**New files (all under `Sources/MiraiStreakKitUI/`):**
- `Theme/StreakTheme.swift`, `Theme/EnvironmentValues+Theme.swift`
- `Components/AnimatedFlameView.swift`, `StreakNumberView.swift`, `WeekStripView.swift`, `StreakHeatmapView.swift`, `FreezeTokenBadge.swift`, `BestStreakBadge.swift`
- `Screens/StreakDetailView.swift`, `StreakCompactView.swift`, `FreezeRedemptionSheet.swift`
- `Effects/ConfettiEffect.swift`, `MilestoneCelebrationView.swift`
- `Widgets/StreakWidgetEntry.swift`, `StreakWidgetView.swift`, `StreakSmallWidget.swift`, `StreakMediumWidget.swift`, `StreakLargeWidget.swift`, `StreakAccessoryWidgets.swift`
- `Previews/StreakPreviewSupport.swift` (in-memory store, sample `Streak` factories — `#if DEBUG`)

**New tests under `Tests/MiraiStreakKitUITests/`:**
- `StreakThemeTests.swift` — equality, default values
- `WeekStripViewTests.swift` — week-day computation
- `StreakHeatmapViewTests.swift` — heatmap cell count = `weeks * 7`
- `StreakWidgetEntryTests.swift` — `Codable` round-trip; `.current(from:)` decode behavior including missing data → empty `Streak`

**Modified files:**
- `Package.swift` — add product, target, testTarget, watchOS platform
- `CHANGELOG.md` — `[Unreleased]` → Added: MiraiStreakKitUI module (per CLAUDE.md changelog rule)
- `Docs/Implementations/MIRAI_STREAK_KIT_UI.md` — save this plan post-implementation (per CLAUDE.md implementation-docs rule)

**Files explicitly NOT touched:** core `MiraiStreakKit` sources stay byte-identical. Existing `StreakView` and `SwiftUI+Integration.swift` remain in the core target as-is for backward compat.

## Reused existing API (no duplication)

- `Streak.hasCompleted(on:calendar:)` from [StreakCore.swift:146](/Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit/Sources/MiraiStreakKit/StreakCore.swift#L146) — drives WeekStrip + Heatmap cell states.
- `StreakManager.getStreakLength()`, `.hasCompletedStreak()`, `.getBestStreak()`, `.getFreezeTokens()`, `.canUseFreeze()`, `.useFreeze()`, `.updateStreak()` — wired from screens.
- `StreakManager.config.tokenMilestone` — milestone celebration trigger.
- `Streak`, `StreakStore`, `AppGroupStore` — used by widget entry helper.
- `Streak.Outcome` — not needed in UI; UI reads `length`/`completedDates` directly.

## Concurrency & platform notes

- All views are `@MainActor` (SwiftUI default). `StreakWidgetEntry` is `Sendable` + `Codable` so it's safe to pass across timeline reloads.
- Haptic helper uses `#if canImport(UIKit) && !os(watchOS) && !targetEnvironment(macCatalyst)` guard; no-op elsewhere.
- WidgetKit views guarded by `#if canImport(WidgetKit)` so the library still compiles on Linux/server (in case anyone uses the core there).
- Visual style respects `verbatim:` for all non-localized text per global CLAUDE.md rule (numbers, "day streak", etc. — those that need l10n take a `LocalizedStringKey` parameter).
- All `Color`/gradient values use system colors where possible to respect dark mode automatically.

## Verification

1. **Build the package:**
   ```bash
   cd /Users/mirai/MiraiDevsWork/AppleProjects/MiraiPackages/MiraiStreakKit
   swift build
   swift build --target MiraiStreakKitUI
   ```
2. **Run all tests:**
   ```bash
   swift test
   ```
   Expect existing core tests to still pass + new `MiraiStreakKitUITests` to pass.
3. **Cross-platform compile check:**
   ```bash
   xcodebuild -scheme MiraiStreakKit -destination 'generic/platform=iOS' build
   xcodebuild -scheme MiraiStreakKit -destination 'generic/platform=macOS' build
   xcodebuild -scheme MiraiStreakKit -destination 'generic/platform=visionOS' build
   xcodebuild -scheme MiraiStreakKit -destination 'generic/platform=watchOS' build
   ```
4. **Visual smoke test:** open `Sources/MiraiStreakKitUI/Screens/StreakDetailView.swift` in Xcode → use the `#Preview` (driven by `StreakPreviewSupport`) to verify:
   - Flame pulses at idle
   - Tapping flame triggers bounce
   - Number rolls when streak increments (preview button)
   - Week strip stagger-animates on appear
   - Confetti fires on milestone (set length to 7 in preview)
   - Heatmap renders 12 weeks
5. **Widget preview:** verify each `WidgetFamily` case renders correctly via Xcode widget preview targets in `StreakWidgetView` previews.
6. **Theme override smoke test:** preview wrapper applies `.streakTheme(.healora)` and confirms colors swap end-to-end.
