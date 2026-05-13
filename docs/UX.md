# UX.md

Interaction patterns, animations, haptics, and the no-words doctrine.

## The no-words rule

No text in the UI. This is non-negotiable. It's the entire commercial premise of the collection (ship globally without localization).

**Allowed:**
- Numerals (0-9). They read as glyphs across all writing systems.
- Emoji.
- Custom icons / SF Symbols.
- Color, shape, animation, haptics.

**Not allowed:**
- Words in any language. Even "OK", "Play", "Back". Even "GAME OVER".
- Localized strings of any kind.
- ASCII art that spells things.

**Practical replacements:**
- "Play" → a play-triangle icon
- "Back" → chevron-left, or rely on the system back gesture / Digital Crown press
- "Score" → just show the number
- "Time" → ⏱ icon + number
- "Moves" → 👆 or similar icon + number
- "Best" → ⭐ + number, or no label at all (highest number visible = your best)

When in doubt, ask "can a 7-year-old who doesn't read English understand this screen?"

## Screen-by-screen flow

### Theme picker (root)
Three large tappable theme cards. Each shows the theme's representative emoji at large size. Tap to select.

### Size picker
After a theme is selected. A vertical or grid arrangement of cards showing the pair counts as numerals: **1, 2, 3, 4, 6, 10, 12, 16**. Each tile could also show a tiny grid preview (small dots in the correct row/col layout) to hint at the actual grid shape.

### Game screen
The grid of cards. Above or alongside:
- Move counter (numeral)
- Elapsed time (mm:ss numerals)

Tap a card to flip. The flip animation should be quick (~0.25s). Mismatches flip back after a delay (~0.8s, tune on device). Matches stay face-up with a brief highlight animation.

### Win screen
Brief (~1.5–2s) celebration:
- Big checkmark or sparkle animation
- Stats: moves and time as numerals
- If new best: ⭐ icon appears next to the new-record stat(s)
- Auto-advance to next size, or auto-return to menu if last size cleared

User can tap to skip the celebration and advance immediately.

## Haptics palette (starting point — tune on device)

All haptic calls route through `Haptics.swift`. `WKInterfaceDevice.current().play(...)`.

| Event | Haptic | Notes |
|-------|--------|-------|
| Card flip | `.click` | Subtle, reinforces the action |
| Match | `.success` | Satisfying confirmation |
| Mismatch | `.retry` or `.failure` | Distinct from match, but not punishing. `.retry` may feel less harsh — test both. |
| Level complete | `.success` x2 with short delay, or `.notification` | Celebration |
| New best score | Stronger pattern — `.success` then `.success` | Distinguishable from regular completion |
| Tap on locked / invalid (e.g. tapping an already-matched card) | `.click` only, no error feedback | Don't punish — just no-op |

Test all of these on a real watch on the wrist, not just in simulator. Haptics in simulator are not representative.

## Animations

Keep them short. Watch sessions are measured in seconds — long animations eat the entire interaction budget.

| Animation | Duration | Notes |
|-----------|----------|-------|
| Card flip | 0.25–0.35s | `rotation3DEffect` around Y axis, swap face at the midpoint |
| Match highlight | 0.3s | Brief glow or scale-up-and-down |
| Mismatch flip-back | After 0.8s pause | Standard flip animation in reverse |
| Level complete celebration | 1.5–2s total | Symbol expansion, stat numbers count up |
| Grid intro on new level | 0.3s | Cards fade or scale in together; avoid staggering long enough to be slow |

All animation timings are starting points. Tune on device.

## Input model

- **Tap** on a card to flip it. This is the entire game input for v1.
- **Digital Crown** is unused in Memory. (Reserved for other games in the collection where it makes sense — Asteroids, Pong, Artillery.)
- **System back gesture / swipe** exits the game to the previous screen. Don't fight the system navigation.
- **Force touch / long-press** unused in v1.

## Accessibility considerations

Even though we have no words, we should still:

- Use sufficient contrast between card backs, faces, and background.
- Make sure emojis render large enough to be recognized on the smallest watch.
- Don't rely on color alone for state (matched vs. unmatched should be obvious from shape/animation, not just a tint).
- Respect "Reduce Motion" — when enabled, simplify or eliminate the flip animation (snap to face-up/face-down instead of rotating).
- Respect "Reduce Transparency" if any blur effects are used.

VoiceOver support is a stretch goal for v1. If added, each card needs an accessibility label that describes its symbol — and yes, those labels are words in the system language, which is allowed because they're an accessibility affordance, not visible UI.

## What "feels right" on watch

A few intuitions that should guide tuning:

- **Faster is better.** 30s on a watch screen is forever. Animations should feel quick, almost too quick.
- **Haptics carry weight.** A good haptic on a match is more rewarding than any visual flourish.
- **Less is more.** Don't add elements just because there's space. If you can remove something and the game still works, remove it.
- **The wrist is in motion.** Don't require precise positioning of the watch face — the player may be walking, on a treadmill, in a coffee line.
