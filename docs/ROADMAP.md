# ROADMAP.md

How to build this game. Order matters — ship the smallest playable thing first.

## Build order

### Milestone 0 — Project scaffolding
- Xcode project created, watchOS app target only
- Docs (this set) in repo root
- Folder structure matches ARCHITECTURE.md
- Builds and runs (blank screen is fine)

### Milestone 1 — Vertical slice
The smallest end-to-end playable game. Prove the loop works.

- One theme (Animals) hardcoded
- One grid size (1 pair, 1x2)
- Tap card → flip → tap second card → match → success haptic → win screen → return to theme picker
- Theme picker shows only Animals
- Size picker shows only 1 pair

**Done when:** you can launch the app, tap through to the game, win it, and return to the menu — all working on simulator and on a real watch.

### Milestone 2 — All grid sizes, single theme
- Add sizes 2, 3, 4, 6, 10, 12, 16
- Auto-advance between sizes after a win
- Move counter and timer visible during game
- Win screen shows moves and time
- 16-pair playtest on 41mm — keep or cut based on result

**Done when:** you can clear all sizes in sequence, end to end.

### Milestone 3 — All themes
- Add Food and Vacation themes
- Theme picker shows all three
- Confirm symbol selection works correctly when pair count < pool size

**Done when:** every (theme × size) combination is playable.

### Milestone 4 — Best scores
- `ScoreStore` reads/writes `BestScore` per `(themeID, pairs)`
- Win screen shows new-best indicator (⭐) when applicable
- Scores persist across app launches

**Done when:** scores survive force-quit and reinstall-from-TestFlight.

### Milestone 5 — Polish
- Haptic tuning pass on a real watch
- Animation timing tuning pass on a real watch
- Visual polish on cards, picker, win screen
- App icon designed (1024x1024 + all watch sizes)
- Accessibility pass: contrast, Reduce Motion, scaling

**Done when:** it looks and feels like a shippable product, not a prototype.

### Milestone 6 — Ship
- App Store Connect listing created
- Screenshots from real watch hardware (all required sizes)
- Description (with words — App Store metadata is allowed to have words, only the *in-app UI* is word-free)
- Privacy disclosure (should be trivial — no data collected in v1)
- TestFlight with at least 3 external testers for a week
- Address feedback, submit for review
- Launch

## Definition of Done — v1

- [ ] 4 themes × 7 or 8 grid sizes all playable (depending on 16-pair decision)
- [ ] Match / mismatch / win haptics tuned on real device
- [ ] Best score (moves + time) persisted per (theme, size)
- [ ] Theme picker + size picker, fully word-free
- [ ] Auto-advance on win, manual back navigation works
- [ ] Tested on smallest (41mm) and largest (49mm) physical watches
- [ ] App icon designed
- [ ] App Store metadata prepared
- [ ] Privacy policy URL ready (Anthropic's `policies` template is fine starting point)
- [ ] TestFlight tested by external testers
- [ ] Submitted, approved, live

## Post-v1 ideas

Not commitments — a parking lot for things deliberately deferred from v1.

- **Honeycomb Challenge Mode** — the flagship v2 feature. Inspired by the classic Apple Watch honeycomb home screen layout. Circular cards in a hex grid, Digital Crown zooms in/out, drag to pan, board extends beyond the screen. Mixed emoji pools across all themes. Much larger grids (20-30+ pairs). Targets adults who want a real challenge — fundamentally different from the standard grid game. Flow: Theme Picker → Difficulty (grid icon vs honeycomb icon, no words) → Game. This is the feature that makes Memory interesting for adults, not just kids.
- **3D scroll indicators** — scroll position indicators (bottom + right) rendered with depth/shadow instead of flat rectangles. Subtle 3D effect to match the honeycomb's spatial feel.
- **Challenge Mode (grid)** — limited tries per level. Strong "1.1" update.
- **Daily Challenge** — one fixed seed per day, shared leaderboard via Game Center.
- **More theme packs** — Plants, Vehicles, Faces (hard), Sports balls (hard).
- **Custom illustrated themes** — replace emoji with original art for premium themes (paid?).
- **Game Center leaderboards** — per (theme, size) leaderboards.
- **iCloud sync of scores** — players who use multiple Apple Watches keep their progress.
- **Watch complication** — show today's best on the watch face.
- **iPhone companion app** — view stats, lifetime totals.
- **Settings screen** — only if a real need surfaces. Settings means words.

## Shipping discipline

When tempted to add a feature before launch, ask:

1. Is it needed for the App Store reviewer to approve the app? If no, defer.
2. Is the game broken without it? If no, defer.
3. Will players in the first week notice it's missing? If no, defer.

Shipping is the goal. Every deferred feature is content for a future update — which is also good for the App Store algorithm and for keeping the app feeling alive.
