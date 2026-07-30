// Headless sanity check for Sentinel's pure wave data.
// Compile the pure-Foundation WaveData together with this one and run:
//
//   cat "Sentinel/Sentinel Watch App/WaveData.swift" \
//       Sentinel/Tools/verify-sentinel.swift > /tmp/snmain.swift && swiftc /tmp/snmain.swift -o /tmp/sn && /tmp/sn
//
// Verifies: table is well-formed and boss invariants hold (difficulty is intentionally
// varied, not monotonic — mechanically-distinct waves are curated by hand, so we print a
// per-wave proxy for eyeballing rather than asserting a single dial).
// (Growth is now driven by shooting descending gates — a player-choice mechanic, so it's
// playtest-gated rather than sim-checkable here.)

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

if failures.isEmpty {
    print("")
    print("✅ all \(WaveData.totalWaves) waves valid (\(bossCount) boss)")
    exit(0)
} else {
    print("❌ \(failures.count) failure(s):")
    failures.forEach { print("  - \($0)") }
    exit(1)
}
