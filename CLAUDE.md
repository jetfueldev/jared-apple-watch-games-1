# CLAUDE.md

## What this is

**Memory** — a word-free emoji-matching memory game for Apple Watch. First of a planned 5-game standalone watchOS game collection. Ships globally without localization because the entire UI uses only emojis, numerals, icons, and haptics. Zero words anywhere in the app.

## Stack

- Swift / SwiftUI
- watchOS 10+
- `@AppStorage` for persistence (v1)
- No SpriteKit, no networking, no external dependencies

## Required reading

Detailed design docs live in `docs/`. Read in this order:

1. `docs/PROJECT.md` — vision, locked decisions, open questions, scope
2. `docs/ARCHITECTURE.md` — file layout, key types, state management, patterns
3. `docs/PROGRESSION.md` — grid sizes, theme packs, emoji lists, score storage
4. `docs/UX.md` — no-words rule, screen flow, haptics, animations, accessibility
5. `docs/ROADMAP.md` — milestone build order, definition of done
6. `docs/COLLECTION.md` — broader 5-game collection context (background only)

## Hard rules

- **No words in the UI.** No text in any language. Only numerals (0-9), emoji, SF Symbols, color, shape, animation, haptics. This is the commercial premise — non-negotiable.
- **Ship smallest playable thing first.** Milestone 1 is a 1-pair tutorial loop: flip, match, win, return to menu. Then layer on complexity.
- **Ask before changing design decisions.** If something in the docs blocks implementation, surface it — don't silently work around it.
- **Don't over-engineer.** This is a small focused game. No DI containers, no Combine acrobatics, no async actor systems. Plain SwiftUI + ObservableObject.

## Build commands

```bash
# Build (requires Xcode)
xcodebuild -scheme "Memory Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (41mm)' build

# Run tests
xcodebuild -scheme "Memory Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (41mm)' test
```

## Project structure

```
WatchGames/
├── Memory Watch App/
│   ├── App/MemoryApp.swift
│   ├── Models/          — CardSymbol, Theme, GridSize, Card, BestScore
│   ├── Game/            — GameState, GameLogic, ScoreStore
│   ├── Content/         — Themes.swift, GridSizes.swift (pure data)
│   ├── Haptics/         — Haptics.swift (thin WKInterfaceDevice wrapper)
│   ├── Views/           — All SwiftUI views
│   └── Assets.xcassets/
├── docs/                — Design docs (PROJECT, ARCHITECTURE, UX, etc.)
└── CLAUDE.md            — This file
```

## Key types

- `CardSymbol` — `.emoji(String) | .image(String)` abstraction for future custom art
- `Theme` — id, displayIcon, symbols pool (>= 16 symbols each)
- `GridSize` — pairs, rows, cols
- `Card` — id, symbol, isFaceUp, isMatched
- `GameState` — ObservableObject holding runtime level state
- `BestScore` — moves, timeSeconds, achievedAt (Codable, stored per theme+size)

## Navigation flow

```
ThemePickerView → SizePickerView → GameView → WinView → (auto-advance to next size or back to menu)
```

## Current milestone

**Milestone 0 — Scaffolding.** Project structure created, source files stubbed. Xcode project creation pending (Xcode not yet installed). Next: Milestone 1 — vertical slice with 1-pair Animals tutorial.

## Definition of done (any task)

- Compiles without warnings
- Runs in watchOS simulator (41mm target)
- Matches the no-words rule
- Doesn't regress existing functionality
