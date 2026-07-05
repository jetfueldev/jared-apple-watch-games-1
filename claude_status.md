# claude_status.md — Collection status (read me first)

**Fast onboarding doc.** This repo is a **5-game standalone watchOS game collection**
by Jet Fuel Labs LLC. Four games are built; game 5 is undecided. Every game ships
**word-free** (emoji / numerals / SF Symbols / color / haptics only) so it sells
globally with no localization. Companion docs: `claude_appstore.md` (submission
runbook), `CLAUDE.md` (Memory game rules + hard rules that apply collection-wide),
`docs/` (per-topic design docs).

Last updated: 2026-07-05.

## Games at a glance

| Game | Swift files | What it is | State | App icon |
|------|------------|-----------|-------|----------|
| **Memory** | 26 | Word-free emoji matching, 4 themes × 8 grid sizes, auto-advance, zen redesign | Most mature. Milestones 0–3 done; focus = polish, clock centering, playtest | ✅ |
| **Echo** | 13 | Simon-style sequence memory, 6 stages, glass pads, screen flashes | Playable, polished transitions | ✅ |
| **Shatter** | 7 | Brick-breaker, 10 levels, Crown paddle, life indicators, glass bricks | Playable | ✅ |
| **Ricochet** | 13 | Bounce-shot: 50 hand-crafted levels, side shields, fire button | Playable at 50 levels; **mid-expansion** (see below) | ✅ |
| **WatchGameKit** | — | Shared Swift package used across games | — | n/a |

## Ship readiness

- **App icons: DONE (2026-07-05).** Was the universal blocker — all 4 icon sets were
  empty. Generated 1024×1024 icons (`Assets/make_app_icons.py`), wired into each
  `AppIcon.appiconset`. Rerun the script to regenerate/replace.
- **Nothing is submitted yet.** Remaining work is Apple paperwork + a real device build,
  not code. See `claude_appstore.md`.
- **Recommended launch #1: Memory** — most mature, scope locked, art direction settled.
- Identifiers already set: `Jet-Fuel-Labs-LLC.<Game>[.watchkitapp]`, v1.0 / build 1.
- Remote: `github.com/jetfueldev/jared-apple-watch-games-1` (private). Everything is
  committed and pushed as of 2026-07-05.

## Environment constraint (important for any coding session)

**Xcode is NOT installed on this machine — only Command Line Tools.**
- `swiftc` works, so pure-logic Swift can be compiled/tested headless (that's how the
  Ricochet physics port was verified — see `Ricochet/Tools/verify-portal.swift`).
- `xcodebuild` does NOT work here. **The actual watchOS app build, archive, device
  run, and upload must happen in full Xcode on Jared's machine.** Don't promise to
  build/run the app from this session.
- Image tooling available: `sips` (built-in) and Python **PIL 12.2.0**. Node is available.

## Ricochet expansion state (the one in-flight thing)

New mechanic verbs **bumpers** (curved carom) and **portals** (teleport, direction
preserved) are fully built and Swift↔JS-verified, but **not yet in the playable game**:
- Engine done in both the SpriteKit game (`Ricochet/Ricochet Watch App/*.swift`) and
  the HTML solver twin / level editor (`Ricochet/RicochetLevelEditor.html`).
- 38 authored levels live in `Ricochet/editor-library.json` (88 total; slots 67–88 are
  the new portal/bumper/misdirection boards).
- **PENDING:** (1) wire chosen new levels into the playable 50 (`LevelData.swift`);
  (2) the editor's Swift export (`caseBlock`) still silently drops bumper/portal recipes.
- Toolchain under `Ricochet/Tools/` (Node): `band6.js` (solver+similarity), `mech.js`
  (load-bearing check), `genset.js`/`misdirect.js` (level search), `apply-*.js`,
  `verify-portal.swift`. Editor bridge: `node Ricochet/editor-server.js` → serves the
  editor at `localhost:8777` and syncs `editor-library.json`.
- Key design finding: the engine has a **wall-bank dominance ceiling** — a new verb only
  buys ~7 genuinely distinct hard levels. Difficulty for portals = *comprehension*
  (which of N identical rings links where), not aim precision. Details in the
  `ricochet-mechanic-ceiling` memory.

## Design rules that apply to ALL games (non-negotiable)

- **No words anywhere in the UI.** Numerals, emoji, SF Symbols, color, shape, haptics only.
- **Zen / meditative tone** — muted colors, whisper-soft, not competitive.
- **Slow transitions** — ~3s fail-to-restart, ~2.5s win-to-next, each phase ≥0.8–1.0s.
- **Human-crafted Ricochet levels only** — no algorithmic level gen shipped to players
  (the search tools are authoring aids that a human curates; Jared is the taste filter).
- Progress bars use `.blue.opacity(0.4)`. watchOS: use `.navigationBarBackButtonHidden`,
  not `.toolbar(.hidden)` (that breaks swipe-back).

## Portfolio strategy

Standalone apps, **$2.99 each**, no IAP / no ads. Plan to use App Bundles and the Apple
Small Business Program (15% cut). See the `portfolio-strategy` memory + `docs/COLLECTION.md`.
