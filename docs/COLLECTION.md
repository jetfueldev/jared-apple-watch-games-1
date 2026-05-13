# COLLECTION.md

Context on the broader watchOS game collection that this app is part of. Read this last — it's background, not implementation guidance.

## The bigger picture

Memory is **game 1 of a planned 5-game watchOS collection**. Each game ships as its own standalone App Store listing. An App Bundle is planned to upsell users on the full set once enough games are live.

## Strategic pillars

Two things define the collection:

1. **watchOS-native design.** Games built around the Digital Crown, haptics, and motion sensors — not phone game ports. The category is structurally under-competed because no one is doing this seriously.
2. **Local multiplayer (watch-to-watch).** A genuine differentiator. Bundled mega-pack competitors structurally cannot do this. At least 2 of the 5 final slots will support local Bluetooth multiplayer via Multipeer Connectivity.

## Why word-free

Every game in the collection is entirely word-free. This is a core design constraint shared across all games.

- Ships in every market without localization
- Works for every age, including pre-readers
- Removes translation overhead from every update
- Forces better visual / haptic design (the right kind of constraint)
- Cross-game style consistency that helps the bundle feel cohesive

## Why standalone apps, not one mega-app

- Each game gets its own App Store listing, screenshots, reviews, keywords
- Users can buy/download only what they want
- Bundle pricing lets you upsell the full set
- Updates to one game don't risk regressions in others
- Each game ships when it's ready, not gated by the slowest sibling

## Lineup candidates

Currently more candidates than slots. Final 5 will be chosen as games are built.

### Single-player

- **Memory** — game 1 (in progress)
- **Simon Says** — haptic-first; uses watch hardware brilliantly
- **Asteroids** — Crown rotates ship (killer interaction), tap to fire, long-press to thrust. SpriteKit. Builds physics foundation reusable for Space Invaders, Missile Command, runner.
- **Missile Command** — Crown for reticle, tap to fire
- **Space Invaders** — tilt to move ship, tap to fire
- **Runner / shooter** — weapon progression, paintball/bigger-guns feel
- **Paintball-over-mountain** — could be solo or multiplayer

### Local multiplayer

- **Pong** — Crown for paddle, Multipeer between two watches
- **Artillery** (Scorched Earth / Gorillas / Worms lineage) — Crown for angle, tap-and-hold for power, lob over terrain, two-watch turn-based. Original art and name.
- **Dots and Boxes**
- **Battleship-style hidden grid**
- **Reaction duel** — Wild West haptic-signal draw
- **Connect Four variant**

### Slap (platform concept, not one game)

Core engine: stimulus + label, "slap" if accurate, withhold if not. Solo + local multiplayer. Each flavor (educational, party trivia, brain training, kid-focused, niche) would ship as its own standalone listing with distinct branding and pricing. Specific flavor names TBD.

## Architecture implications for Memory

Memory is being built clean, single-purpose, no premature sharing. **Don't extract shared code yet.** When game 2 starts, the real shared API will become clear — that's the right time to factor things into a Swift package.

What's most likely to become shared:
- Haptic helpers (`Haptics.swift`)
- Score persistence patterns (`ScoreStore` style)
- Multipeer Connectivity wrapper (for the multiplayer games — Memory doesn't touch this)
- Theme/asset system (`CardSymbol` abstraction generalizes to other visual-asset-driven games)

Write Memory's versions of these cleanly so they're easy to lift later. But don't generalize them now.

## Why Memory first

- Lowest technical risk (no physics, no networking, no real-time loop)
- Exercises every watchOS fundamental (SwiftUI, haptics, persistence, animations, App Store submission)
- Validates the no-words design across menus and game screens
- Small enough scope to ship in a reasonable timeline
- The next game (likely Simon Says) shares ~70% of Memory's skeleton, so once this ships, game 2 goes fast

## What you don't need to worry about (yet)

When working on Memory specifically:
- Multipeer Connectivity (not used in this game)
- SpriteKit (not used in this game)
- Game-to-game shared code (extract later)
- Cross-promotion between games (post-launch concern)
- Bundle pricing structure (App Store Connect concern, not code)

Focus on shipping a great Memory. The rest follows.
