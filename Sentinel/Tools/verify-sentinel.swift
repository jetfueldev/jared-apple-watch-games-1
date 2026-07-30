// Headless sanity check for Sentinel's wave table.
// Xcode is not on this machine, so the watch app can't be built/run here — but WaveData
// is pure Foundation, so we can compile + exercise it:
//
//   swiftc "Sentinel/Sentinel Watch App/WaveData.swift" Sentinel/Tools/verify-sentinel.swift -o /tmp/vg && /tmp/vg
//
// Verifies: table is well-formed, difficulty is monotonic, and every wave is winnable
// (the base can, in principle, out-shoot the formation before the front row breaches).

import Foundation

// Scene geometry mirrored from GameScene.swift (keep in sync).
let sceneHeight = 240.0
let frontSpawnY = sceneHeight - 20.0   // front row start
let floorY = 22.0                      // defense line
let frontDescent = frontSpawnY - floorY

var failures: [String] = []
func check(_ cond: Bool, _ msg: String) { if !cond { failures.append(msg) } }

check(WaveData.totalWaves >= 1, "totalWaves must be >= 1")

var prevCount = 0
var prevSpeed = 0.0
var prevInterval = Double.greatestFiniteMagnitude

for n in 1...WaveData.totalWaves {
    let w = WaveData.wave(n)
    let tag = "wave \(n)"

    // Well-formed
    check(w.rows >= 1 && w.cols >= 1, "\(tag): rows/cols must be >= 1")
    check(w.enemyCount >= 1, "\(tag): needs at least one enemy")
    check(w.enemySpeed > 0, "\(tag): enemySpeed must be > 0")
    check(w.fireInterval > 0, "\(tag): fireInterval must be > 0")
    check(!w.emoji.isEmpty, "\(tag): emoji must be non-empty")

    // Monotonic difficulty (never gets easier)
    check(w.enemyCount >= prevCount, "\(tag): enemyCount regressed (\(w.enemyCount) < \(prevCount))")
    check(w.enemySpeed >= prevSpeed, "\(tag): enemySpeed regressed")
    check(w.fireInterval <= prevInterval, "\(tag): fireInterval got slower (easier)")

    // Winnability guardrail: shots the base can fire during the front row's descent must
    // exceed the enemy count (loose bound — perfect aim; positioning eats the slack).
    let descentTime = frontDescent / w.enemySpeed
    let maxShots = descentTime / w.fireInterval
    check(maxShots >= Double(w.enemyCount),
          "\(tag): unwinnable — \(String(format: "%.1f", maxShots)) shots < \(w.enemyCount) enemies")

    print(String(format: "wave %d: %2d enemies, speed %.0f, fire %.2fs → up to %.0f shots in %.1fs",
                 n, w.enemyCount, w.enemySpeed, w.fireInterval, maxShots, descentTime))

    prevCount = w.enemyCount
    prevSpeed = w.enemySpeed
    prevInterval = w.fireInterval
}

// --- Platoon economy (M2) ---
// Growth should fill 3 slots first, then climb tiers, never lose a slot or produce a nil-hole
// once full, and total tier value must strictly increase every step.
print("")
var slots = Platoon.seed(from: [1])
check(slots.compactMap { $0 } == [1], "seed([1]) should be a single tier-1 unit")

var prevTotal = slots.compactMap { $0 }.reduce(0, +)
var line = "platoon: [1]"
for step in 1...12 {
    slots = Platoon.grow(slots)
    let filled = slots.compactMap { $0 }
    let total = filled.reduce(0, +)
    check(total > prevTotal, "grow step \(step): total tier must increase (\(total) !> \(prevTotal))")
    if step >= Platoon.slotCount {
        check(filled.count == Platoon.slotCount, "grow step \(step): once full, all \(Platoon.slotCount) slots stay filled")
    }
    line += " → \(filled.sorted(by: >))"
    prevTotal = total
}
print(line)

if failures.isEmpty {
    print("✅ all \(WaveData.totalWaves) waves valid + platoon growth consistent")
    exit(0)
} else {
    print("❌ \(failures.count) failure(s):")
    failures.forEach { print("  - \($0)") }
    exit(1)
}
