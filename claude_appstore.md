# claude_appstore.md — App Store submission runbook

Step-by-step path to publish a game. Written for **Memory** (launch #1); the same
steps apply to Echo / Shatter / Ricochet. Most steps require **full Xcode + Jared's
Apple Developer account** — they can't be done from a Command Line Tools session.

Status legend: ✅ done · ⬜ to do · 🧑 needs Jared (account/device/art call)

## Pre-flight (code + assets)

- ✅ **App icon** — 1024×1024, no alpha, in `Memory/Memory Watch App/Assets.xcassets/AppIcon.appiconset`.
  (First-pass generated art; replace anytime via `Assets/make_app_icons.py`.)
- ⬜ **Build clean in Xcode** — open `WatchGames.xcworkspace`, select the Memory scheme,
  build for a watchOS Simulator. Must compile with no warnings (project's definition of done).
- 🧑 **Run on a physical Apple Watch** — simulator isn't enough for final sign-off
  (haptics, Crown feel, performance). Requires a paired device + dev signing.
- 🧑 **Signing** — set the team to **Jet Fuel Labs LLC** in Signing & Capabilities for
  both the app and the watchkitapp target. Automatic signing is fine.

## App Store Connect setup (🧑 Jared, needs account)

- ⬜ Create the app record: bundle id `Jet-Fuel-Labs-LLC.Memory`, platform watchOS,
  primary language English, category **Games** (sub: Puzzle/Board).
- ⬜ **Age rating** questionnaire → will land at 4+.
- ⬜ **Privacy**: the app collects no data → "Data Not Collected" nutrition label. Simplest path.
- ⬜ **Pricing**: $2.99 (Tier 3). Enroll in the **Apple Small Business Program** (15% commission).
- ⬜ **Screenshots**: required per watch case size currently shipping (e.g. 45/49mm).
  Capture from the simulator (Cmd+S in Simulator) — wordless gameplay screens.
- ⬜ **Description / keywords / promo text**: allowed to be minimal. Keep it wordless-brand-
  consistent in spirit; App Store metadata itself may use words (store listing ≠ in-app UI).
- 🧑 **Support URL / marketing URL**: needs a real reachable URL (a simple page is fine).

## Ship it

- ⬜ **Archive**: Xcode → Product → Archive (Release config, "Any watchOS Device").
- ⬜ **Upload**: Organizer → Distribute App → App Store Connect.
- ⬜ **TestFlight**: install the uploaded build on the watch, final smoke test.
- ⬜ **Submit for review**: attach build to the version, answer export-compliance
  (no non-exempt encryption → No), submit.
- ⬜ Review typically 24–48h. Watch for icon/metadata rejections (icons are the usual one —
  already handled).

## Gotchas seen in this project

- Empty `AppIcon.appiconset` (Contents.json only, no PNG) = instant rejection. Fixed 2026-07-05.
- Icons must have **no alpha channel** — the generator already flattens to RGB.
- watchOS masks icons to a **circle**; keep art centered (the generated icons already are).
- The "no words" rule is about the **in-app UI**, not the store listing — don't block on that.

## Reusing for the other games

Repeat with bundle id `Jet-Fuel-Labs-LLC.<Game>`. Ricochet should NOT ship until the
bumper/portal expansion is either finished-and-wired or explicitly deferred to a later
version (see `claude_status.md`). Consider an **App Bundle** once ≥2 are live.
