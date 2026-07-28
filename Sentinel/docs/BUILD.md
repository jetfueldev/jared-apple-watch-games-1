# Sentinel — build / run

**M0 is done** — `Sentinel/Sentinel.xcodeproj` exists (cloned from Shatter's project:
watchOS 10+, SwiftUI, `PBXFileSystemSynchronizedRootGroup` so every file in
`Sentinel Watch App/` is auto-included; WatchGameKit linked; bundle id
`Jet-Fuel-Labs-LLC.Sentinel[.watchkitapp]`, v1.0/build 1) and is registered in
`WatchGames.xcworkspace`.

## Build + run in the watch simulator (works on this machine)

Xcode 26.6 is installed but `xcode-select` points at CLT, so use the env override (no sudo):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd <repo root>

# build
xcodebuild -workspace WatchGames.xcworkspace -scheme "Sentinel Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' build

# run in the sim
UDID=$(xcrun simctl list devices available | grep "Apple Watch Series 11 (42mm)" | grep -oE '[0-9A-F-]{36}')
APP="$HOME/Library/Developer/Xcode/DerivedData/WatchGames-*/Build/Products/Debug-watchsimulator/Sentinel Watch App.app"
xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" $APP
xcrun simctl launch "$UDID" Jet-Fuel-Labs-LLC.Sentinel.watchkitapp
xcrun simctl io "$UDID" screenshot menu.png
```

`simctl` has **no tap command**, so to screenshot *gameplay* (past the menu), temporarily
point `ContentView` at `GameContainerView(startWave: 1)`, build, screenshot, then revert.

## Expected M1 behavior (definition of done) — VERIFIED 2026-07-28

- Menu: 🛡️ header + wave number + green Play (Shatter-style). ✓
- In-game: base at the bottom, **Digital Crown steers L/R**, **auto-fires** blue bolts up. ✓
- Enemies (👾/🛸/🤖/👽) descend in formation; a bolt pops one (haptic click). ✓
- Enemy crossing the faint red defense line costs a life (3 white dots, failure haptic).
- Clear all enemies → green flash (~2.5 s) → next wave. After wave 5 → back to menu.
- Lose all 3 lives → red flash (~3 s) → retry the same wave.

## Headless wave-table check (no Xcode needed)

```bash
cat "Sentinel/Sentinel Watch App/WaveData.swift" Sentinel/Tools/verify-sentinel.swift > /tmp/vgmain.swift
swiftc /tmp/vgmain.swift -o /tmp/vg-verify && /tmp/vg-verify
```

Validates well-formedness, monotonic difficulty, and winnability of every wave.

## Still to do

- Real app icon (M5) — the current `AppIcon.appiconset` is an empty placeholder.
- Playtest tuning: enemy speed / fire interval / defense-line height (WaveData + GameScene
  geometry constants).
- Confirm signing/archive path for a real device build (simulator needs no signing).
