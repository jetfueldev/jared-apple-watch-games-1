# ARCHITECTURE.md

How the code is organized. Read this before writing or refactoring code.

## Guiding principles

- **Small game, simple architecture.** No DI containers, no Combine acrobatics, no async actor systems. SwiftUI + plain Swift types + `ObservableObject` view models where state needs to be shared.
- **Data, not logic, for content.** Themes and level definitions are data. Adding a theme = adding to a data file, not editing game code.
- **Future-proof the seams that matter.** The `CardSymbol` abstraction and the theme system need to outlive emoji. Everything else can be naive and rewritten if needed.
- **Don't share code with other games yet.** This is game 1. Patterns that look reusable should be written cleanly but kept in-project. Extract to a shared Swift package when game 2 starts — that's when you'll actually know what the shared API should look like.

## File layout (suggested)

```
Memory Watch App/
├── App/
│   └── MemoryApp.swift              // @main, root view
├── Models/
│   ├── CardSymbol.swift             // enum: .emoji(String) | .image(String)
│   ├── Theme.swift                  // id, displayIcon, symbols: [CardSymbol]
│   ├── GridSize.swift               // pairs, rows, cols, role
│   ├── Card.swift                   // id, symbol, isFaceUp, isMatched
│   └── BestScore.swift              // moves, time, achievedAt
├── Game/
│   ├── GameState.swift              // ObservableObject, the level's runtime state
│   ├── GameLogic.swift              // pure functions: shuffle, isMatch, isComplete
│   └── ScoreStore.swift             // reads/writes best scores via @AppStorage
├── Content/
│   ├── Themes.swift                 // static let allThemes: [Theme]
│   └── GridSizes.swift              // static let allSizes: [GridSize]
├── Haptics/
│   └── Haptics.swift                // thin wrapper around WKInterfaceDevice haptics
├── Views/
│   ├── RootView.swift               // navigation entry
│   ├── ThemePickerView.swift        // pick a theme
│   ├── SizePickerView.swift         // pick a grid size
│   ├── GameView.swift               // the game itself
│   ├── CardView.swift               // a single card
│   └── WinView.swift                // post-level stats, auto-advance
└── Assets.xcassets/
```

This is a starting point, not a rigid rule. Move things around if it makes the code clearer.

## Key types

### `CardSymbol`

The abstraction that lets us swap emoji for custom art later without rewriting anything.

```swift
enum CardSymbol: Hashable {
    case emoji(String)
    case image(String)  // asset catalog name
}
```

Render it through a single view that knows how to display either case. Never put a raw emoji string into a view directly — always go through `CardSymbol`.

### `Theme`

Pure data. A theme is its identifier, its display icon (for the picker), and its symbol pool.

```swift
struct Theme: Identifiable, Hashable {
    let id: String
    let displayIcon: CardSymbol  // shown in the theme picker
    let symbols: [CardSymbol]    // must have >= 16 to support the largest grid
}
```

### `GridSize`

```swift
struct GridSize: Identifiable, Hashable {
    let pairs: Int
    let rows: Int
    let cols: Int
    var id: Int { pairs }
}
```

Cards in the grid = `pairs * 2`. Layout = `rows * cols` must equal `pairs * 2`. Validate this in a debug assertion.

### `Card`

```swift
struct Card: Identifiable, Hashable {
    let id: UUID
    let symbol: CardSymbol
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
```

Each pair shares the same `symbol` but has different `id`s. That's how match detection works.

### `GameState`

`ObservableObject` holding the runtime state of the current level. Cards, flips, matches, move count, elapsed time, completion flag. Logic for "what happens when a card is tapped" lives here. Pure helpers (shuffle, etc.) live in `GameLogic.swift`.

### `BestScore`

```swift
struct BestScore: Codable, Hashable {
    let moves: Int
    let timeSeconds: Double
    let achievedAt: Date
}
```

Stored per `(themeID, pairs)` cell. `ScoreStore` reads/writes via `@AppStorage` with JSON-encoded values.

## State management

- **Per-level state** lives in a `GameState` `ObservableObject` owned by `GameView`. Destroyed and recreated when starting a new level. No need for it to outlive the view.
- **Best scores** are global, persisted via `@AppStorage`. A `ScoreStore` singleton or `@EnvironmentObject` is fine — keep it simple.
- **Theme/size selections** are passed by value down the navigation stack. No need to put them in app-global state.

## Navigation

Use SwiftUI `NavigationStack`. The flow is:

```
RootView (theme picker)
  → SizePickerView (after theme tap)
    → GameView (after size tap)
      → WinView (auto-shown on completion, auto-advances)
        → GameView (next size up)
        → ...
        → RootView (after last size cleared, or via back gesture)
```

Keep the navigation state explicit and simple. Don't deep-link or restore state across launches in v1.

## Patterns to follow

- **Functions over methods when state isn't needed.** Match detection, shuffle, grid layout calc — pure functions in `GameLogic.swift`.
- **Avoid `Timer` for animations.** Use SwiftUI animation modifiers. Timers are fine for elapsed-time tracking during a level.
- **Avoid forcing pixel sizes.** Use `GeometryReader` and proportional sizing so cards scale across watch sizes (41mm, 45mm, 49mm).
- **All haptic calls go through `Haptics.swift`.** Don't sprinkle `WKInterfaceDevice` calls around the codebase.

## Patterns to avoid

- **Don't reach for Combine** unless a real need appears. SwiftUI's built-in state tools cover this game.
- **Don't build a settings screen yet.** No settings means no words. If a "toggle haptics" need appears, defer it.
- **Don't add analytics in v1.** Adds complexity, App Store privacy disclosure work, and doesn't help you ship faster.
- **Don't hand-position cards.** Use SwiftUI `Grid` or `LazyVGrid` driven by the `GridSize` data.

## Testing strategy for v1

Light unit tests on the pure logic in `GameLogic.swift` (shuffle correctness, match detection, completion detection). No UI tests for v1 — watchOS UI testing is awkward and the surface is small enough to test manually. Manual testing in simulator + on at least one physical watch before shipping.
