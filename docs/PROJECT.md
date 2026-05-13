# PROJECT.md

## Vision

A polished, language-agnostic memory matching game native to Apple Watch. Short sessions, glanceable UI, hardware-aware interactions. No words anywhere — entirely icon and emoji driven so it ships globally without localization. Designed to be enjoyable in 30-second bursts (the actual way people use Apple Watch).

## Why this game, why this watch

- **Apple Watch has almost no real games.** The category is structurally under-competed. Most "watch games" are phone-game ports that feel terrible on a tiny screen.
- **Word-free design is a moat.** Every market, every age, every language — no localization overhead, no translation costs, no missed strings.
- **Memory specifically** was chosen as game 1 because it has the lowest technical risk and exercises every watchOS fundamental (SwiftUI layout, haptics, persistence, animations, App Store submission) without fighting physics, networking, or complex game loops.

## Locked design decisions

These are settled. Don't revisit without flagging them explicitly.

### Word-free everywhere
No text in the UI. Menus, level select, game over, stats — all icon/number/emoji. The only "text" allowed is numerals (0-9) which are universal. Numerals are fine because they read as glyphs across all writing systems.

### Auto-advance after a win
After clearing a level, briefly show stats (~1.5–2s), then auto-advance to the next size. Player can back out to menu at any time. This matches the "one more round" feel that works on watch.

### No try limit in v1
Memory stays a relaxing pattern game, not a pressure game. Scoring is by moves taken and time elapsed — players who want challenge can chase their own bests. A "Challenge Mode" with limited tries is a candidate for v2 as a 1.1 update.

### Everything unlocked from the start
No progression gating in v1. All theme packs, all grid sizes available immediately. Less code, faster to ship, more accessible. Revisit for v2 if engagement data suggests gating would help.

### Three theme packs in v1
Animals, Food, Vacation. See PROGRESSION.md for the full emoji lists. Architecture supports adding more themes as pure data — adding a theme should not require changing game logic.

### Emoji for v1, custom art later
Apple emoji is free to use in any app, gives instant universal recognition, ships fast. Architecture uses a `CardSymbol` abstraction so themes can swap to custom illustrated art in a future version without rewriting game logic.

### Single-player only
No multiplayer in this game. Multiplayer is reserved for other games in the collection (Pong, Artillery). Keeps Memory's scope tight.

### `@AppStorage` for persistence
v1 stores best scores and settings locally only. No iCloud sync, no Game Center for v1. Both are candidates for later updates.

## Open questions — validate on device

These cannot be decided in a markdown file. Prototype and feel them out.

- **16-pair playability.** On a 41mm watch, 32 cards in a 4x8 grid is roughly 8mm per card — below Apple's 44pt tap-target recommendation. If it fails playtesting, cap progression at 12 pairs. Test this *early* so you don't build for a level that won't ship.
- **Mismatch flip-back delay.** Starting value: 0.8s. Tune on device.
- **Card flip animation duration.** Should feel snappy on watch. Probably 0.25–0.35s total. Tune on device.
- **Haptic feel.** Match, mismatch, and win all need distinct haptic signatures. See UX.md for the starting palette.
- **Cell spacing / padding** for each grid size. Each grid likely needs slightly different tuning to maximize tap target while staying readable.

## Out of scope for v1

- Multiplayer
- Game Center leaderboards
- iCloud sync of progress
- Custom illustrated theme packs (emoji only for v1)
- Sound effects (haptics-first; watch users often mute audio)
- Apple Watch complications
- iPhone companion app
- Challenge Mode / try limits
- Daily challenge
- Progression unlocking
- Settings screen (defer until needed — settings are words)

## Why these are out of scope

Each one is a real feature with real value. They're out of scope because **shipping** is the goal. Every feature added before launch delays launch. Most of these are great "1.1" and "1.2" update content that gives the App Store something fresh to feature and gives players a reason to come back.
