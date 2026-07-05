# CLAUDE.md

> **New session? Read `claude_status.md` first** — it's the collection dashboard
> (all 4 games, ship readiness, environment constraints). `claude_appstore.md` is the
> submission runbook. This CLAUDE.md documents the **Memory** game specifically; its
> hard rules (no words, zen tone, slow transitions) apply collection-wide.
>
> Key facts as of 2026-07-05: 4 games built (Memory, Echo, Shatter, Ricochet) + shared
> WatchGameKit. App icons DONE for all 4. Nothing submitted yet — remaining work is
> Apple paperwork + a device build. **Xcode is not installed here (CLT only); the app
> build/archive/upload happens on Jared's machine.** Launch #1 = Memory.

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
xcodebuild -scheme "Memory Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' build

# Run tests
xcodebuild -scheme "Memory Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' test
```

## Project structure

```
Memory/
├── Memory.xcodeproj/
├── Memory Watch App/
│   ├── MemoryApp.swift
│   ├── Models/          — CardSymbol, Theme, GridSize, Card, BestScore
│   ├── Game/            — GameState, GameLogic, ScoreStore
│   ├── Content/         — Themes.swift (4 themes), GridSizes.swift (pure data)
│   ├── Haptics/         — Haptics.swift (thin WKInterfaceDevice wrapper)
│   ├── Views/           — RootView, ThemePickerView, GameView, CardView, WinView
│   └── Assets.xcassets/
├── docs/                — Design docs (PROJECT, ARCHITECTURE, UX, ROADMAP, etc.)
└── CLAUDE.md            — This file
```

## Key types

- `CardSymbol` — `.emoji(String) | .image(String)` abstraction for future custom art
- `Theme` — id, displayIcon, symbols pool (>= 16 symbols each). 4 themes: Animals, Food, Vacation, Space
- `GridSize` — pairs, rows, cols
- `Card` — id, symbol, isFaceUp, isMatched
- `GameState` — ObservableObject holding runtime level state
- `BestScore` — moves, timeSeconds, achievedAt (Codable, stored per theme+size)

## Navigation flow

```
ThemePickerView (2x2 grid) → GameView (auto-starts at 2 pairs, auto-advances through all 8 sizes) → WinView (auto-dismiss 2.5s) → next size or back to menu
```

## Design direction

Zen / meditative. The game should feel like a calming mental health moment, not a competitive challenge. Muted colors (white.opacity 0.08-0.12), no 3D card effects, silent mismatch haptic, ghost-like win stats, no Liquid Glass. Everything whisper-soft.

## Transition timing

State transitions must be slow enough for human comprehension. Don't rush phase changes — each distinct step (feedback → explanation → reset) needs at least 0.8–1.0s to land. Target ~3s for fail-to-restart, ~2.5s for win-to-next. If you watch a transition cold and can't follow what happened, it's too fast. Applies to all games.

## Current milestone

**Milestones 0-3 complete.** Xcode project running in watchOS simulator. 4 themes (Animals, Food, Vacation, Space) in a 2x2 picker. All 8 grid sizes playable with auto-advance. Zen redesign applied. SizePickerView removed. **App icon added (2026-07-05).** Current focus: polish, clock positioning, and playtesting — then App Store submission as collection launch #1 (see `claude_appstore.md`).

## Definition of done (any task)

- Compiles without warnings
- Runs in watchOS simulator (41mm target)
- Matches the no-words rule
- Doesn't regress existing functionality
