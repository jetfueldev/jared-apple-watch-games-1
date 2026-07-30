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
| **Sentinel** | 8 | Merge/TD defense shooter: moving auto-fire base, merge platoon, side turrets, 10 waves + boss | **M1–M5 built + sim-verified (2026-07-30)**: steer+auto-fire, 3-slot merge platoon (kill-charge economy), auto-targeting edge turrets, 10 hand-authored waves w/ enemy HP + a boss. Left: hands-on playtest tuning + device build. See `Sentinel/docs/` | ✅ |
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

## Environment (important for any coding session)

**Xcode 26.6 IS installed** (`/Applications/Xcode.app`) — the old "CLT only" note was wrong.
`xcode-select` still points at CommandLineTools (switching needs sudo), so prefix Xcode
commands with the env override instead — no sudo required:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -workspace WatchGames.xcworkspace -scheme "Vanguard Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' build
```

- **Full watchOS build + simulator run works here.** Verified 2026-07-28: built Shatter and
  Vanguard, booted the 42mm sim, installed + launched + screenshotted gameplay via `simctl`.
  Watch sims available: Series 11 (42/46mm), Ultra 3 (49mm), SE 3 (40/44mm), watchOS 26.5.
- **Headless-drive tips for `simctl`:** `simctl boot/install/launch`, then
  `simctl io <udid> screenshot out.png`. `simctl` has **no tap command**, so to screenshot
  *gameplay* (past the menu) temporarily point `ContentView` straight at the game view,
  build, shoot, then revert. Menu shots work as-is.
- `swiftc` also works for pure-logic headless checks (e.g. `Ricochet/Tools/verify-portal.swift`,
  `Vanguard/Tools/verify-vanguard.swift`).
- Archive/upload to App Store still best done in the Xcode GUI (signing), but building &
  running is fully doable from this session now.
- Image tooling: `sips` (built-in) and Python **PIL 12.2.0**. Node is available.

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
