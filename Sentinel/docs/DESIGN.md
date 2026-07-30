# Sentinel — Design (game 5, WORKING TITLE)

> Word-free vertical defense shooter for Apple Watch. Fifth game in the Jet Fuel Labs
> collection. Inspired by "Galaxy Defense" style ads: a base at the bottom that steers
> left/right and auto-fires up at enemies descending from the top — layered with a
> merge/upgrade economy.
>
> **Working title "Sentinel"** (front-line squad + defense). Name not locked — alt
> candidates: Salvo, Barrage, Bulwark, Rampart, Bastion, Volley. Word-free in-game, so
> the name only matters for the App Store listing.

## ⚠️ REDESIGN 2026-07-30 — gate-shooter (supersedes the merge/turret model below)

Playtesting the merge/turret build, Jared redirected the core: **no side guns, no
auto-merge economy.** The new loop:

- **Bottom:** a growing **cluster of shooters**, all auto-firing straight up; steer with
  the Crown. More shooters = a wider wall of fire (and more field coverage).
- **Left lane:** a continuous stream of **"+shooter" gates** — shoot one (a few hits) to
  break it → +1 shooter.
- **Right lane:** a stream of **ENCASED power-ups** — the boost is behind concrete/glass;
  it takes *many* hits to crack the casing (which visibly clears as you shoot) → +1 gun
  power (more damage per bolt). Sometimes cracking one is the only way to out-gun a wave.
- **Middle:** enemies descend — stop them or lose lives.
- **Use it or lose it:** a gate that reaches the bottom is gone, but another is always
  coming. Still **one input** — steering *is* the decision (defend the middle vs. dip into
  a side lane to invest). This replaced the auto side-turrets, the kill-charge auto-grow,
  and the 3-slot merge/tier platoon. Implemented in `GameScene.swift`; `Platoon.swift` +
  the old `balance-sim.swift` were retired (growth is now player-choice, so playtest-gated).

Everything from here down is the earlier (superseded) merge/TD design, kept for history.

---

## The pitch in one line

Steer your platoon back and forth along the bottom; it auto-fires upward. Kills charge
a meter; the meter grants new units; matching units **merge** into stronger tiers; side
turrets can be **upgraded**. Survive hand-crafted descending waves.

## Locked decisions (from 2026-07-28 design session)

- **Core loop depth: full merge/TD** — not just a bare survival shooter. Merge economy +
  upgrade tree are in scope (layered across milestones, not all at once).
- **Firing: auto-fire.** The base fires continuously straight up. The player only steers.
  True one-input. Aiming == positioning.
- **Progression: discrete waves.** Numbered, hand-authored formations (per the collection's
  "human-crafted levels only" rule). Clear a wave → 2.5 s → next wave. Like Shatter/Ricochet.
- **Control: Digital Crown** steers the base left↔right (identical input model to Shatter's
  paddle). No tap needed for firing.

## The reconciliation: "moving base" vs "tower defense"

Classic TD has *stationary* turrets. The ad shows a mostly-fixed squad. Jared's instinct
("the thing you control just goes back and forth") is the literal control we keep. We
reconcile the two like this:

- **The base is a MOBILE PLATOON, not a fixed turret line.** It is the one thing you steer.
  It carries a short row of **unit-slots** (start 1, grow to ~3–4). Every unit in the
  platoon auto-fires straight up. Steering is how you concentrate fire and dodge.
- **The side TURRETS are the stationary TD half.** Fixed x-positions at the screen edges
  (the left column in the reference art). They also auto-fire and are **upgraded** by
  spending charge. This is the "upgrade tree" without a fixed grid of tower slots.
- **MERGE lives on the platoon.** Two same-tier units combine into the next tier. Tier is
  shown word-free by **color + pip count**, never a number label.
- **ECONOMY = a kill-charge meter** (blue capsule, per collection rule `.blue.opacity(0.4)`).
  Kills fill it; full meter drops a `+1` base-tier unit into the platoon (or a tappable
  token — TBD in M2). No coins, no shop text. Everything is icons/pips/color.

This keeps the screen legible on 41 mm: **one moving thing** (platoon), a couple of fixed
turrets at the edges, a charge capsule, life dots, a wave numeral. Nothing scrolls, no text.

## Screen layout (41 mm target, ~200×240 pt scene like Shatter)

```
        [wave numeral]              ← top-center, faint, numerals only
  👾  👾   👾   👾                    ← enemies descend from top
        👾   👾
 ┌─┐                    ┌─┐
 │T│                    │T│          ← side turrets (fixed x; M3)
 └─┘                    └─┘
        ▲ ▲ ▲                        ← auto-fire streams up
      [■■□] platoon  ← steer L/R (Crown)   tier = color+pips
 ▂▂▂▂▂▂▂▂▂▂  ← blue charge capsule
   ● ● ●     ← lives (white dots, like Shatter)
```

## Word-free vocabulary

| Concept        | Representation                                                    |
|----------------|------------------------------------------------------------------|
| Enemies        | Reuse Ricochet's `Aliens/` art set (ufo, robot, cyclops, …) or shapes |
| Unit tier      | Fill color + pip dots (1 pip = T1, 2 = T2, …). No numerals.       |
| Charge/economy | Blue capsule filling `.blue.opacity(0.4)`                         |
| Lives          | White dots (Shatter pattern), fade out on loss                   |
| Wave number    | Numerals 0–9 only, faint, top-center                             |
| Merge          | Two units slide together + pip-up flash + haptic                 |
| Turret upgrade | Pip count / color shift on the turret icon                       |
| Win/lose       | Green / red screen-flash + success/failure haptic (collection)   |

## Milestones (ship smallest playable thing first)

- **M0 — scaffold.** ✅ **DONE 2026-07-28.** Folder + Swift sources authored;
  `Sentinel/Sentinel.xcodeproj` created (cloned from Shatter — synchronized-folder group,
  WatchGameKit linked) + added to `WatchGames.xcworkspace`. Builds and runs in the watch
  sim (Xcode 26.6 is on the machine — see `claude_status.md`). Placeholder empty AppIcon.

- **M1 — smallest playable (NO merge, NO turrets, NO economy).** ✅ **Swift authored
  2026-07-28** (`Sentinel/Sentinel Watch App/*.swift` + `Tools/verify-sentinel.swift`;
  headless wave-table check passes). Single base unit, steers L/R via Crown, auto-fires up.
  5 hand-authored descending waves. Enemy crossing the defense line costs a life (3 dots).
  Clear the wave → green flash → next. **Pending:** Xcode target (M0 steps in `BUILD.md`)
  + sim/device playtest to tune feel & timing.

- **M2 — merge platoon + economy.** ✅ **Built + verified in sim 2026-07-28.** 3-slot platoon
  (`Platoon.swift`, pure/testable), kill-charge blue capsule, each fill auto-grows the platoon
  (fill empty slots → merge T1 up → bump lowest), tier shown by color + pips, higher tier fires
  faster, each unit fires its own tier-colored bolt column. Platoon + charge persist across
  waves (carried by container); game-over restores the wave's starting platoon. Growth curve
  headless-checked in `verify-sentinel.swift`: `[1]→[1,1]→[1,1,1]→[2,1,1]→…→[5,4,4]`.
  **Kept one-input (steer only)** — auto-grow/auto-merge; player-directed merge deferred (see Q1).
  **Pending:** playtest to tune chargeNeeded / fire-rate curve / feel.

- **M3 — side turrets.** ✅ **Built + verified in sim 2026-07-28.** Two fixed edge turrets
  (bottom corners) that **auto-target the lowest / closest-to-breaching enemy** and fire
  angled bolts toward it — covering the edges the centered platoon can't while you steer.
  Tier shown by color + pips (like units); higher tier fires faster. They **upgrade one tier
  per wave cleared** (capped at 5), persisted across waves and restored on game-over. Second
  progression track: platoon grows from *kills*, turrets from *wave-clears* — no new input,
  no currency conflict. **Deferred:** a player-*chosen* upgrade tree (spend to pick which to
  upgrade) — the "TD choice" layer, alongside the deferred player-directed platoon merge.

- **M4 — wave authoring + curve.** ✅ **Built + verified in sim 2026-07-29.** 10 hand-authored,
  mechanically-distinct waves (`WaveData`, 5→10) mixing count / enemy **HP** (tanky multi-hit
  types) / speed — deliberately non-monotonic (variety over a single dial). **Boss wave 10**:
  one high-HP 👹 with a shrinking red HP bar; breaching it ends the run. Non-lethal hits give
  damage feedback (pulse + fade); charge only on kill. Best-wave persists via `ProgressStore`
  (`totalWaves` now 10 → menu/progress follow). Headless verify updated for HP/boss + prints a
  per-wave totalHP/speed proxy for curation.

- **M5 — polish.** ✅ **Mostly done 2026-07-30.** Real **app icon** generated (shield +
  upward chevron + 3 platoon dots, steel-indigo; `Assets/make_app_icons.py` → `sentinel()`),
  replacing the empty placeholder. **Boss-bar / wave-numeral overlap fixed** (numeral to top
  edge, boss spawns lower). Transition timing reviewed and already conforms to the collection
  rules (~2.5 s win-to-next, ~3 s fail-to-restart, ≥0.8 s phases); haptics reviewed —
  non-lethal hits are silent so tanky enemies/boss don't buzz. A **numbers-based balance pass**
  is done via a headless combat sim (`Tools/balance-sim.swift`, plays the full run with real
  DPS/growth/turret math): platoon now **caps at tier 5** (`Platoon.maxTier` — fire rate floors
  there, so higher tiers were dead weight), economy slowed (`chargeNeeded` 3→5) so the platoon
  climbs across the run and plateaus ~wave 8, boss HP 40→150 (a ~11 s fight vs a ~23 s breach
  window). End-of-run now loops to a fresh run (`ProgressStore.completeWave`). **Remaining: final
  feel tuning on-device** (the sim is conservative/idealized — real aim + spatial spread differ).

## Open questions (resolve as we hit each milestone)

1. ~~`+1` delivery in M2~~ — RESOLVED for M2: **auto-grow** (charge fill → `Platoon.grow`),
   no tap, preserves one-input. Player-directed merge (tap slots, or a between-wave breather)
   is a candidate strategic layer for later — the pure `Platoon` model already supports it.
2. When the platoon is full (all slots high tier), what does surplus charge do — overflow
   into turret upgrades, or a fire-rate boost?
3. Enemy floor-breach penalty: lose a life vs. lose a platoon unit? (life is simpler/zen).
4. Endless overlay: after authored waves run out, loop with a difficulty multiplier for a
   high-score chase, or hard-cap at N waves like Ricochet's 50?

## Architecture (mirrors Shatter — the closest existing game)

```
Sentinel/
  Sentinel Watch App/
    SentinelApp.swift          — @main, shows MenuView
    ContentView.swift / MenuView.swift — wave-select or single "start", word-free
    GameContainerView.swift    — SpriteView host, Crown → scene.updateBasePosition()
    GameScene.swift            — SKScene: base, bullets, enemies, waves, contacts
    WaveData.swift             — hand-authored formations (pure data, like LevelData)
    ProgressStore.swift        — UserDefaults best-wave / high score
    Assets.xcassets/           — AppIcon + reused alien art
```

Physics: same category-bitmask pattern as Shatter (base / bullet / enemy / floor / wall).
Bullets are simple upward-velocity nodes; enemies are downward-velocity nodes; contacts
handle bullet↔enemy (destroy + charge) and enemy↔floor (life loss).
