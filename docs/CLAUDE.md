# CLAUDE.md

Entry point for Claude Code. Read this first, then read the other docs in the order listed below.

## What this project is

**Memory** — a word-free emoji-matching memory game for Apple Watch. First of a planned series of standalone watchOS games shipping individually to the App Store.

## Required reading (in order)

1. **PROJECT.md** — vision, design decisions, scope, what's locked vs. open
2. **ARCHITECTURE.md** — code structure, types, file organization, key patterns
3. **PROGRESSION.md** — level sizes, grid layouts, theme packs, content data
4. **UX.md** — interaction model, haptics, animations, no-words rules
5. **ROADMAP.md** — build order, definition of done, post-v1 plans
6. **COLLECTION.md** — context on the broader game collection this is part of

## The developer

Jared. Has some Swift experience but is new to watchOS development. Build with clear, idiomatic SwiftUI. Explain non-obvious watchOS-specific decisions inline in comments. Don't over-engineer — this is a small focused game, not an enterprise app.

## Working agreement

- **Ship the smallest playable thing first.** Get the 1-pair tutorial → match → win → menu loop working end-to-end before building anything else. Then add the other grid sizes. Then the second theme. Then the third.
- **Ask before changing design decisions.** If something in these docs blocks implementation or seems wrong, surface it — don't silently work around it.
- **Test on device early.** Several decisions in PROJECT.md are flagged "validate on device" (haptic feel, 16-pair playability, animation timing). Build the harness to test these as soon as possible.
- **No words in the UI.** This is a hard constraint, not a preference. If you find yourself adding a string for the user to read, stop and find another way (icon, number, emoji, animation).
- **Keep the shared code path in mind.** This game is the first of several. Code that's obviously cross-game (haptic helpers, score persistence patterns, theme system) should be written in a way that's easy to extract into a shared Swift package later. Don't extract it yet — wait until game 2 — but don't make it harder than it needs to be.

## Stack

- Swift, SwiftUI
- watchOS 10+ target
- `@AppStorage` for persistence (v1)
- No SpriteKit (Memory doesn't need it)
- No networking (single-player)
- No external dependencies for v1

## Definition of "done" for any task

- Compiles without warnings
- Runs in watchOS simulator (smallest size — 41mm)
- Matches the no-words rule
- Doesn't regress anything that was working before
- New behaviors are reflected in the relevant doc if they change a documented decision
