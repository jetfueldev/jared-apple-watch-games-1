// Headless sanity check for Sentinel's pure data/logic (WaveData + Platoon).
// Compile the pure-Foundation files together with this one and run:
//
//   cat "Sentinel/Sentinel Watch App/WaveData.swift" "Sentinel/Sentinel Watch App/Platoon.swift" \
//       Sentinel/Tools/verify-sentinel.swift > /tmp/snmain.swift && swiftc /tmp/snmain.swift -o /tmp/sn && /tmp/sn
//
// Verifies: table is well-formed and boss invariants hold (difficulty is intentionally
// varied, not monotonic — mechanically-distinct waves are curated by hand, so we print a
// per-wave proxy for eyeballing rather than asserting a single dial). Also checks the pure
// platoon growth rules.

import Foundation

var failures: [String] = []
func check(_ cond: Bool, _ msg: String) { if !cond { failures.append(msg) } }

check(WaveData.totalWaves >= 1, "totalWaves must be >= 1")

var bossCount = 0
for n in 1...WaveData.totalWaves {
    let w = WaveData.wave(n)
    let tag = "wave \(n)"

    // Well-formed
    check(w.rows >= 1 && w.cols >= 1, "\(tag): rows/cols must be >= 1")
    check(w.enemyCount >= 1, "\(tag): needs at least one enemy")
    check(w.enemyHP >= 1, "\(tag): enemyHP must be >= 1")
    check(w.enemySpeed > 0, "\(tag): enemySpeed must be > 0")
    check(w.fireInterval > 0, "\(tag): fireInterval must be > 0")
    check(!w.emoji.isEmpty, "\(tag): emoji must be non-empty")

    // Boss invariant: a boss, if any, must be the final wave.
    if w.isBoss {
        bossCount += 1
        check(n == WaveData.totalWaves, "\(tag): boss must be the last wave")
    }

    print(String(format: "wave %2d: %2d enemy × %dhp = %2d totalHP, speed %.0f%@",
                 n, w.enemyCount, w.enemyHP, w.totalHP, w.enemySpeed, w.isBoss ? "  [BOSS]" : ""))
}
check(bossCount <= 1, "at most one boss wave allowed (found \(bossCount))")

// --- Platoon economy (M2) ---
// Growth should fill 3 slots first, then climb tiers, plateau at 3×maxTier, never lose a slot
// or exceed the cap. Total must strictly increase until capped, then hold.
print("")
var slots = Platoon.seed(from: [1])
check(slots.compactMap { $0 } == [1], "seed([1]) should be a single tier-1 unit")

let capTotal = Platoon.slotCount * Platoon.maxTier
var prevTotal = slots.compactMap { $0 }.reduce(0, +)
var line = "platoon: [1]"
for step in 1...20 {
    slots = Platoon.grow(slots)
    let filled = slots.compactMap { $0 }
    let total = filled.reduce(0, +)
    check(total >= prevTotal, "grow step \(step): total must not decrease")
    check(total <= capTotal, "grow step \(step): total \(total) exceeds cap \(capTotal)")
    check(filled.allSatisfy { $0 <= Platoon.maxTier }, "grow step \(step): a slot exceeds maxTier")
    if prevTotal < capTotal {
        check(total > prevTotal, "grow step \(step): must increase until capped (\(total) !> \(prevTotal))")
    }
    if step >= Platoon.slotCount {
        check(filled.count == Platoon.slotCount, "grow step \(step): once full, all \(Platoon.slotCount) slots stay filled")
    }
    if total != prevTotal { line += " → \(filled.sorted(by: >))" }
    prevTotal = total
}
print(line + "  (caps at \(capTotal))")
check(prevTotal == capTotal, "platoon should reach the cap \(capTotal); got \(prevTotal)")

if failures.isEmpty {
    print("✅ all \(WaveData.totalWaves) waves valid (\(bossCount) boss) + platoon growth consistent")
    exit(0)
} else {
    print("❌ \(failures.count) failure(s):")
    failures.forEach { print("  - \($0)") }
    exit(1)
}
