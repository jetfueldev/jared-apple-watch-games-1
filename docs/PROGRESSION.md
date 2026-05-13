# PROGRESSION.md

Level sizes, grid layouts, and theme content. This is the data side of the game.

## Difficulty progression

| Pairs | Cards | Grid | Role |
|-------|-------|------|------|
| 1     | 2     | 1x2  | Tutorial — teaches the flip mechanic with zero memory load. Cannot lose. |
| 2     | 4     | 2x2  | First real game, minimal memory load |
| 3     | 6     | 2x3  | Bridge to the sweet spot |
| 4     | 8     | 2x4  | Easy |
| 6     | 12    | 3x4  | Sweet spot, validated default |
| 10    | 20    | 4x5  | Tight but workable |
| 12    | 24    | 4x6  | Tap targets shrinking |
| 16    | 32    | 4x8  | Stretch goal — needs device validation; cap at 12 if tap targets fail |

### Why this ramp

The first four levels (1, 2, 3, 4 pairs) live comfortably inside working memory, so they build confidence fast. 6 is where it starts to feel like a real challenge. 10+ is a genuine memory test.

The 1-pair tutorial doubles as onboarding — no separate tutorial screen needed. Player learns flip → flip → match → haptic feedback with zero failure pressure, then 2 pairs introduces actual memory load.

### 16-pair caveat

On a 41mm watch, 32 cards in a 4x8 grid means each card is roughly 8mm wide, below Apple's 44pt tap-target recommendation. Prototype this size on the smallest target hardware as early as possible. If it's unplayable, cap progression at 12 pairs and ship without 16. Don't ship a level that's frustrating.

### Auto-advance order

After clearing a level, the next size up loads automatically. Sequence: `1 → 2 → 3 → 4 → 6 → 10 → 12 → 16` (or `12` if 16 is cut). After the final size, return to the menu.

## Theme packs (v1)

Each theme must have at least 16 unique symbols to support the largest grid.

### Animals (easy)

🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🐔

Maximum visual distinction. Bold, varied colors. Good first theme.

### Food (easy)

🍕 🍔 🌮 🍜 🍣 🍦 🍩 🍪 🥐 🥗 🍎 🍓 🍇 🍌 🥑 🥕

Bold colors, clear shapes. Globally recognizable.

### Vacation (medium)

🏖️ 🗽 🗼 🎡 🏔️ 🗻 🏝️ 🏜️ 🌋 🏰 ⛺ 🚢 ✈️ 🎢 🎪 🎠

More variety in shape and color, slightly harder to distinguish at a glance. Good bridge to the future "hard mode" of similar-looking vacation spots.

## Theme picker icons

Each theme needs a single representative `CardSymbol` for the picker. Suggested:

- Animals → 🐱
- Food → 🍕
- Vacation → 🏖️

These can be tuned in `Themes.swift` and don't affect game logic.

## Symbol selection per level

When starting a level with N pairs, take N random symbols from the theme's symbol pool. Each of those N symbols gets duplicated to form 2N cards. Shuffle all 2N cards into the grid.

```swift
func dealCards(theme: Theme, pairs: Int) -> [Card] {
    let pool = theme.symbols.shuffled().prefix(pairs)
    let cards = pool.flatMap { symbol in
        [Card(id: UUID(), symbol: symbol),
         Card(id: UUID(), symbol: symbol)]
    }
    return cards.shuffled()
}
```

This is illustrative — the real implementation lives in `GameLogic.swift`.

## Future theme packs (post-v1)

Listed in rough order of expected difficulty:

- **Plants/flowers** (medium) — 🌷 🌹 🌺 🌸 🌼 🌻 🌾 🌿 🍀 🍁 🍂 🌳 🌴 🌵 🪴 🌱
- **Vehicles** (medium-hard) — many visually similar cars/trucks
- **Faces / emotions** (hard) — 😀 😃 😄 😁 — leverages watch-screen smallness as a feature, forces close inspection
- **Sports balls** (hard) — ⚽ 🏀 🏐 ⚾ 🥎 — round and subtle pattern differences

The "look closely" hard themes are a deliberate design move that leans into the small screen instead of fighting it.

### Custom art era (longer term)

Once the emoji-based game is shipped and the engine is proven, swap to original illustrated themes. Vacation landmarks rendered as custom illustrations would be a strong second wave — distinct visual identity, full IP ownership, premium feel. The `CardSymbol` abstraction supports this with zero game-logic changes.

## Best score storage

For each `(themeID, pairs)` combination, store the best `BestScore` (lowest moves, then lowest time as tiebreaker). Keys in `@AppStorage` should look like:

```
"bestScore.animals.6"
"bestScore.food.12"
"bestScore.vacation.16"
```

Encoded as JSON via `BestScore: Codable`.
