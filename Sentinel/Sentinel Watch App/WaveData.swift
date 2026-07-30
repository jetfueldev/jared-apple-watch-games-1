import Foundation

/// Pure-data wave table (no SpriteKit) so it can be compiled + sanity-checked headless
/// with `swiftc WaveData.swift Platoon.swift Tools/verify-sentinel.swift`.
///
/// M4: 10 hand-authored, mechanically-distinct waves. Difficulty comes from a mix of
/// count, enemy HP (tanky types take multiple hits), and descent speed — not a single
/// monotonic dial. Wave 10 is a boss (one high-HP enemy; breaching it = game over).
/// `fireInterval` is a per-wave *reference* single-unit cadence (kept for the headless
/// winnability eyeball); actual fire rate is driven by platoon/turret tiers at runtime.
struct Wave {
    let rows: Int
    let cols: Int
    let enemySpeed: Double      // points/sec descending
    let enemyHP: Int            // hits to destroy one enemy
    let fireInterval: Double    // reference single-unit cadence
    let emoji: String           // enemy glyph (word-free)
    let isBoss: Bool

    init(rows: Int, cols: Int, enemySpeed: Double, enemyHP: Int = 1,
         fireInterval: Double, emoji: String, isBoss: Bool = false) {
        self.rows = rows
        self.cols = cols
        self.enemySpeed = enemySpeed
        self.enemyHP = enemyHP
        self.fireInterval = fireInterval
        self.emoji = emoji
        self.isBoss = isBoss
    }

    var enemyCount: Int { isBoss ? 1 : rows * cols }
    var totalHP: Int { enemyCount * enemyHP }
}

enum WaveData {
    static let totalWaves = 10

    static func wave(_ number: Int) -> Wave {
        let n = max(1, min(number, totalWaves))
        switch n {
        case 1:  return Wave(rows: 1, cols: 4, enemySpeed: 10,             fireInterval: 0.45, emoji: "👾")
        case 2:  return Wave(rows: 2, cols: 4, enemySpeed: 12,             fireInterval: 0.42, emoji: "👾")
        case 3:  return Wave(rows: 2, cols: 5, enemySpeed: 12, enemyHP: 2, fireInterval: 0.40, emoji: "🛸")  // tankier
        case 4:  return Wave(rows: 2, cols: 5, enemySpeed: 16,             fireInterval: 0.38, emoji: "👾")  // fast swarm
        case 5:  return Wave(rows: 3, cols: 5, enemySpeed: 14, enemyHP: 2, fireInterval: 0.36, emoji: "🛸")
        case 6:  return Wave(rows: 3, cols: 5, enemySpeed: 16, enemyHP: 2, fireInterval: 0.34, emoji: "🤖")
        case 7:  return Wave(rows: 3, cols: 6, enemySpeed: 15, enemyHP: 3, fireInterval: 0.32, emoji: "🤖")  // tanky + dense
        case 8:  return Wave(rows: 3, cols: 6, enemySpeed: 19,             fireInterval: 0.30, emoji: "👽")  // fast + dense
        case 9:  return Wave(rows: 4, cols: 6, enemySpeed: 17, enemyHP: 3, fireInterval: 0.30, emoji: "👽")  // gauntlet
        case 10: return Wave(rows: 1, cols: 1, enemySpeed: 7,  enemyHP: 40, fireInterval: 0.30, emoji: "👹", isBoss: true)
        default: return wave(totalWaves)
        }
    }
}
