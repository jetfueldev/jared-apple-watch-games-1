# claude_online_project.md

> **Purpose:** This file captures strategic and design decisions made in conversations with Claude on claude.ai (the web/mobile app), separate from any operational instructions or per-game design specs already in the repo. It is reference material, not operating rules. Treat as the "why" behind decisions, not the "how" of implementation.
>
> **Scope:** Portfolio strategy, architecture, pricing, marketing, IP, testing approach, and game candidates. Per-game implementation specs (Memory's grid sizes, card flow, etc.) live in each game's own design doc.

---

## 0. Developer context

Jared (the developer) has **~20 years of extensive application and data development experience in ColdFusion**, with **working knowledge of object-oriented programming concepts** (classes, inheritance, encapsulation, polymorphism, interfaces, composition vs. inheritance, MVC-style separation), and **very limited Swift / iOS / watchOS background**. Implications for how to explain and structure work:

- **Strong foundations to leverage:** application architecture, data modeling, state management, debugging instincts, the entire SDLC, shipping discipline, OOP design patterns, and decades of "what makes software maintainable" intuition. None of this needs explaining.
- **Where to invest explanation effort:** Swift's strict static typing (vs. CF's dynamic typing), **protocol-oriented design** (Swift's twist on interfaces — protocols can have default implementations, conformance can be added retroactively via extensions, and protocols are often preferred over class inheritance), **value vs. reference types** (structs are copied, classes are referenced — this is a major mental shift from most OOP languages), **Swift's optionals and unwrapping**, **SwiftUI's declarative + reactive model** (very different from server-rendered CFML or imperative OOP UI code), the **actor / concurrency model**, and Xcode-specific workflow (schemes, targets, build phases, archive/upload).
- **Useful bridging analogies:** Swift Packages ≈ CF custom tag libraries / shared component dirs / OOP module libraries. SwiftUI views ≈ reactive components, not CFML templates or traditional UI classes. `@State` and `@Binding` ≈ scoped observable properties with auto-rebinding. **Protocols ≈ interfaces with default implementations and retroactive conformance.** **Structs ≈ value-copy classes** (no shared mutation; pass-by-value semantics). Extensions ≈ retroactive class augmentation (no CF equivalent, but conceptually similar to monkey-patching done safely).
- **Don't over-explain:** general programming concepts, control flow, debugging strategy, version control, database thinking, application structure, OOP fundamentals (encapsulation, inheritance, polymorphism, interfaces, separation of concerns). Jared has thought about these for longer than most full-time iOS devs have been coding.
- **Swift-specific OOP differences worth flagging when they come up:** Swift favors **composition over inheritance**, **protocols over base classes**, and **value types over reference types** more aggressively than typical OOP languages. Idiomatic Swift code often looks less class-heavy than CF or Java would. This isn't a style choice — it's how the language is designed to be used.

---

## 1. Project vision

A portfolio of standalone Apple Watch games shipping individually on the App Store, with App Bundles used to sell the collection. Each game is **word-free**, enabling global compatibility across all languages and markets without localization overhead.

**Two strategic pillars:**

1. **watchOS-native design** — games built around the Digital Crown, haptics, and motion sensors, not phone-game ports.
2. **Local multiplayer (watch-to-watch, same vicinity)** — a genuine differentiator on the App Store that mega-pack competitors structurally can't replicate. Target at least 2 of the 5 final game slots to support multiplayer.

**Differentiation summary:** watchOS is severely underserved by quality games and oversaturated by mega-packs. Polished, focused, premium standalones are the strategic gap. Becoming a mega-pack puts the project in the crowded lane.

---

## 2. Portfolio architecture (firm)

- **Each game ships as its own standalone App Store app.** Not bundled in one mega-app.
- **App Bundles** used to upsell users on the full collection.
- **Shared code factored into a Swift Package** at the workspace root.

### Why standalone, not mega-pack (decision considered and rejected)

The "one app with all 5 games unlocked via IAP" model was considered and **deliberately rejected**. It's how most watchOS competitors operate. Standalone was chosen because:

- **Apple editorial features become much less likely with a mega-pack.** Apple features specific games, not bundle collections. Forfeiting feature opportunity = forfeiting the single biggest free marketing lever.
- **A mega-pack is indistinguishable from the dozens of existing watchOS bundle apps.** Standalones occupy the differentiated lane.
- **ASO collapses with a mega-pack.** Five separate App Store search slots become one.
- **Pricing power drops.** Mega-packs anchor at $0.99-$4.99 total. Standalones can charge $2.99-$9.99 each.
- **v2 economics get murky in a mega-pack.** With standalones, v2 is just a new app.
- **Reviews dilute** across the mega-pack experience vs. concentrating per-game.

**This decision is a one-way door.** Once shipped as a mega-pack, returning to standalones confuses customers. The reverse (5 standalones → optional mega-pack later) is much easier if ever needed.

### Xcode workspace structure

```
WatchGames/                          ← Single workspace, single Git repo to start
├── WatchGames.xcworkspace
├── SharedPackage/                   ← Swift Package
│   ├── Package.swift
│   └── Sources/
│       ├── HoneycombGrid/           ← Hex grid + Crown zoom/pan (Memory, Battleship, ...)
│       ├── MultipeerKit/            ← Multipeer Connectivity wrapper (all multiplayer)
│       ├── HapticHelpers/           ← Haptic patterns (every game)
│       └── CardSymbol/              ← Memory's swappable symbol abstraction
├── Memory/                          ← Standalone app
├── Asteroids/                       ← Standalone app
├── Battleship/                      ← Standalone app
└── ...
```

**Each game project imports the shared package.** Bug fixes propagate automatically. Tests for shared code live with the shared code, not duplicated per game.

**Don't pre-build the shared package.** Build Memory first with all code in the Memory project. When game 2 arrives, *then* extract what's actually reusable. Premature abstraction is the killer of solo developer productivity.

Can split into separate repos later if needed; don't bother now.

---

## 3. Pricing structure (firm)

| Product | Price | Tier | Net (Small Biz, 15%) |
|---|---|---|---|
| Standalone game | $2.99 | Tier 3 | $2.54 |
| 3-pack bundle | $6.99 | Tier 7 | $5.94 |
| 5-pack Complete | $9.99 | Tier 10 | $8.49 |

- Leaning toward $3.99 (Tier 4) for polished hero titles or once a strong bundle exists.
- **NO subscriptions, NO in-app purchases, NO ads.** One-time purchase, owned forever.
- **Major upgrades ship as new standalone apps** (Memory 1, Memory 2, etc.) priced separately. Users who want the new version buy it. No automatic v1→v2 discount — that would train customers to wait.
- **App Bundles via App Store Connect.** Enable **Complete My Bundle** — customers who buy a standalone then upgrade to a bundle automatically pay the difference.
- Bundles must be discounted vs. sum of standalones (Apple requirement, satisfied).
- **Apple Small Business Program — apply DAY ONE** of App Store Connect setup. Reduces commission from 30% to 15% for developers under $1M/year. Non-negotiable first step.

---

## 4. Marketing strategy (year 1)

**NO paid advertising.** Cost-per-install on App Store ads averages $2-5; this kills margins on $2.99-3.99 apps.

**Channels in priority order:**

1. **Pitch Apple's watchOS editorial team directly** via App Store Connect's App Promotion form. One feature dwarfs any ad spend. The watchOS team is actively hungry for quality content because so little exists.
2. **Pitch Mac press** — MacStories, 9to5Mac, AppleInsider, The Verge — with free promo codes.
3. **Reddit r/AppleWatch** — engage genuinely, then share. Small but highly engaged community.
4. **ASO (App Store search optimization)** — distinctive app names, keyword-rich subtitles, great screenshots. Free and arguably more important than ads.
5. **A strong app preview video per game.**
6. **Clean one-page website per game.**

**Multiplayer = marketing.** Local Bluetooth multiplayer has an inherent viral mechanic: player A plays with friend B, friend wants their own copy, friend buys. Design multiplayer flows to make second-player purchase irresistible. Consider whether the second player gets a free "lite" join experience that nags toward purchase, or full feature parity that makes them want to own it.

---

## 5. IP / legal stance

Game mechanics are **not copyrightable**. Cloning classic mechanics (Asteroids rotation, Battleship deduction, Outlaw bouncing shots, Scorched Earth artillery, Memory matching) is legally safe.

**Rules to stay clearly safe:**

1. **Never use original product names.** Not Asteroids, not Battleship, not Outlaw, not Scorched Earth, not Connect Four (Hasbro trademark), not Simon (Hasbro trademark). Create entirely original names.
2. **Original art only.** No pixel-perfect recreations of classic sprites. The custom illustrated assets plan for Memory shows the right instinct.
3. **Original sound and music.**
4. **Avoid distinctive trade dress** — don't copy exact color schemes, UI chrome, or fonts of the originals.
5. **Don't market by comparison.** No "It's just like Battleship!" copy. Describe what the game does, not what it's like.

**Extra-careful trademarks:** Hasbro (Connect Four, Battleship, Simon), Atari (Asteroids brand), Team17 (Worms).

**"Memory" is fine** as a name because the underlying game is generic (Concentration) with no single trademark owner.

Consider a $300-500 IP attorney consultation before finalizing App Store names and marketing materials. Not needed for mechanics; useful for validating specific naming/branding choices.

---

## 6. Testing strategy

**Four layers, prioritized for cost vs. value:**

1. **Unit tests (XCTest)** — cheap, high value. Game logic, math, state machines, win conditions. ~30 min to 2 hours per game.
2. **SwiftUI snapshot tests** (`swift-snapshot-testing` library) — moderate cost, very high value for a portfolio. Catches regressions when watchOS updates change rendering. ~3-4 hours initial setup, then ~15 min per new snapshot.
3. **UI tests (XCUITest)** — high time cost (1-3 hours per test scenario + ongoing maintenance). Skip for v1 unless a specific regression demands a guard. Snapshot tests cover most of what UI tests would catch.
4. **Manual on-device smoke testing** — irreplaceable. Haptics, Crown feel, Bluetooth, rendering bugs only appear on physical hardware.

**Money cost: essentially zero.** Snapshot-testing library is free, XCTest is built into Xcode, GitHub Actions CI is free for public repos / ~$0-30/month for private. The cost is time, not dollars.

**Test Harness companion app** (planned for game 2 timeframe, not v1): a separate watchOS app — never shipped — that exercises every shared component manually on device. Honeycomb grid demo, haptic playground, Multipeer test screen, Crown sensitivity test. Open it whenever a new watchOS beta drops to verify the foundation.

**Per-game regression checklist** (markdown, not automated): ~10 minutes per game per release. Start fresh game, all theme packs load, win state shows, audio toggles respected, Reduce Motion respected, VoiceOver basic nav works.

---

## 7. iOS port stance

**Do NOT port 1:1 from watchOS.** A watch game on a 6.7" iPhone screen feels slight — the watch constraints often *are* the game.

**Defer iOS ports** until after game 3 or 4 ships and real winners emerge. Then port *selectively* with iOS-native enhancements (bigger grids, more variety, AI opponents, deeper progression) at higher price points ($4.99-$9.99). Treat watch as the original; iOS as a deluxe edition.

iOS market is overrun; watchOS is the differentiated entry point.

---

## 8. Revenue planning (reference, not target)

5 polished games shipped over ~18 months at $2.99 / $6.99 / $9.99 ladder + Small Business Program:

| Scenario | Steady-state monthly net |
|---|---|
| Conservative | ~$700/month |
| Moderate | ~$2,800/month |
| Optimistic | ~$11,000/month |

**Single biggest variable:** Apple editorial feature or press hit.

**Year 1 typically disappointing** for indie publishing; catalog compounding kicks in year 2-3. The 5-pack bundle is the high-leverage product — push to game 5 with focus.

**Only two controllable levers:** quality and shipping pace. Treat revenue projections as planning anchors, not targets — they're educated guesses for an unshipped indie portfolio.

---

## 9. Game candidates and lineup

### Game 1: Memory (in progress)

Lowest technical risk; exercises all watchOS fundamentals. Detailed design is locked in `Memory/PROJECT.md` (the in-repo design doc). Strategic-level decisions captured here for reference:

- **Difficulty progression:** 1 pair (tutorial) → 2 → 3 → 4 → 6 → 10 → 12 → 16 pairs. Device validation required for the largest grid.
- **v1 theme packs:** Animals (easy), Food (easy), Vacation (medium). Faces and Sports Balls queued for later.
- **`CardSymbol` abstraction layer** keeps emoji swappable for custom illustrated assets without rewriting game logic.
- **No try limits in v1** — Memory stays relaxing, scored by moves and time. Challenge Mode (limited tries) noted as a strong v2 feature.
- **Auto-advance after winning.** Everything unlocked from the start (no progression gating).
- **Honeycomb (hex/staggered) layout** confirmed. Rows and columns labeled by **numbers** (word-free; digits are the closest thing to a universal glyph set). Alternating row/column **color bands** create visual zones — purpose is **spatial orientation when scrolled/zoomed into larger grids (10/12/16 pairs)** where the full board isn't visible at once. Colors are a navigation aid, NOT the primary identifier. Numbers carry the meaning; colors carry the location. Final color scheme TBD; revisit when implementing 6+ pair grids.
- **Crown zoom + pan** is the natural fit for navigating larger grids. Smaller grids (1-4 pairs) fit screen; ~6 pairs is borderline; 10+ requires scroll/zoom.
- **Edge indicators (scroll position feedback)** — applies to BOTH standard grid (larger sizes 10/12/16) and honeycomb mode. When the grid extends beyond the visible screen, lines appear on all four edges (top, bottom, left, right) to communicate scroll position:
  - **Line appears** on any edge where there are more cards off-screen in that direction.
  - **Line grows larger** as the viewport approaches the edge of the grid (less content remaining in that direction).
  - **No line** when the viewport has NOT yet approached that edge (still deep inside the grid with lots of content in that direction).
  - **Line transforms into a border** when the viewport reaches the actual grid boundary — the indicator becomes a solid edge border, signaling "this is the end."
  - The effect is progressive: lines grow from nothing → thin → thick → solid border as you scroll toward any edge. This gives continuous spatial feedback without words.
  - Applies on all four sides independently. A player scrolled to the top-right would see borders on top and right, lines growing on bottom and left.
  - Design should be subtle/zen — thin whisper-weight lines that don't compete with the cards. Same muted `.white.opacity` palette as the rest of the game.
- **Design philosophy:** Memory stays calm and relaxing. Short-session friendly. Reading "I want to play one round" should feel easier than reading "I should put the watch down."

**ASO note for naming:** "Memory" as a literal app name is generic and likely buried in App Store search. Consider a distinctive product name with "memory" or "match" in the subtitle for discoverability. Open question.

### Single-player candidates
- **Asteroids** — Crown rotates ship, tap fires, long-press thrusts. SpriteKit. Builds physics foundation reusable for Space Invaders, Missile Command, runner.
- Simon Says (rename required)
- Missile Command (rename required)
- Pong (rename required)
- Space Invaders (rename required)
- Runner/shooter with weapon progression
- Paintball-over-mountain game

### Local multiplayer candidates
- **Artillery-style** — parabolic, gravity-driven. Crown adjusts angle, tap-and-hold sets power. Lineage: Scorched Earth / Gorillas / Worms.
- **Bounce-shot** — linear shots that carom off walls. Geometric, not parabolic. Progression: open field → 1 wall → multiple/angled walls. Lineage: Atari Outlaw gunfight/bounce mode.
- **Battleship-style** — honeycomb hex grid with Crown zoom, reusing the Memory grid primitive. Difficulty scales by grid size. Icon-based ship/hit/miss for word-free. Solo vs AI + local multiplayer. Strong candidate for a multiplayer slot.
- Dots and Boxes
- Connect Four variant (rename required)
- Reaction duel (Wild West draw with haptic signal)

### Multiplayer scope (firm for v1 of any multiplayer game)
**Same-vicinity Bluetooth only** via Multipeer Connectivity. Two watches, same room, no internet.

Remote/Game Center multiplayer and invite-a-friend flows are **explicitly v2 features**. Rationale: tier-1 Bluetooth alone is the structural moat. Adding Game Center doubles engineering surface before shipping.

### Slap (platform concept, not a single game)
Core engine: stimulus + label (slap if accurate, withhold if not). Solo + local multiplayer. Each flavor ships as its own standalone listing with distinct branding and pricing. Flavors under consideration: educational (math, words, geography, science, code), fun/casual (general, party, trivia), brain training, kid-focused, niche (faith, language).

### Open question
Final 5-slot lineup and which slots are multiplayer. Defer until after Memory ships and real-world signal arrives.

---

## 10. Shared interaction primitives

Belong in the shared Swift package, built once during Memory implementation, designed for reuse:

- **HoneycombGrid + Crown zoom/pan** — Memory, Battleship, possibly more
- **MultipeerKit** — every multiplayer game
- **HapticHelpers** — every game
- **CardSymbol** abstraction — Memory now, possibly Slap flavors later

The honeycomb grid + Crown zoom is the clearest example of the compounding payoff from the portfolio architecture. Build it well for Memory; reap the benefit on Battleship.

---

## 11. Operating principles

- **Ship sequentially, not in parallel.** Build and release one game at a time. Perfect one before starting the next.
- **Memory first.** Lowest risk, exercises every watchOS fundamental, teaches the full pipeline (Xcode → App Store Connect → submission → marketing → reviews).
- **Game mechanics aren't copyrightable.** Original names, original art, original sound.
- **Watch canvas constraints are real.** Tap targets limit grid density. Short-session design matches actual usage.
- **Local multiplayer is a structural moat.** Bundled mega-pack competitors can't easily offer watch-to-watch play.
- **No premature abstraction.** Build for the current game; extract to shared package when the second use case arrives.
- **Quality and shipping pace are the only controllable levers.** Everything else (features, press, virality) is downstream of those two.

---

## 12. Tools and stack

- **SwiftUI + watchOS 10** (primary); **SpriteKit** via `SpriteView` for physics-based games
- **Multiplayer tech:** Multipeer Connectivity over Bluetooth, no internet
- **Dev environment:** Xcode, Claude Code (CLI), claude.ai (strategic conversations)
- **Distribution:** App Store standalone listings per game + App Bundles
- **Testing:** XCTest, `swift-snapshot-testing`, manual on-device

---

*This file is reference material from claude.ai conversations. Operational rules for Claude Code live in `CLAUDE.md`. Per-game implementation specs live in each game's own design doc.*
