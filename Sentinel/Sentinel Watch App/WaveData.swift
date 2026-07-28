import Foundation

/// Pure-data wave table (no SpriteKit) so it can be compiled + sanity-checked headless
/// with `swiftc WaveData.swift verify-sentinel.swift` (Xcode is not on the build machine).
///
/// M1 scope: single-HP enemies descending in a formation. Difficulty ramps via enemy
/// speed + count; the base's auto-fire interval tightens slightly per wave. No merge,
/// turrets, or economy yet — those are M2/M3 (see docs/DESIGN.md).
struct Wave {
    let rows: Int
    let cols: Int
    let enemySpeed: Double      // points/sec descending
    let fireInterval: Double    // seconds between base auto-shots
    let emoji: String           // enemy glyph (word-free)

    var enemyCount: Int { rows * cols }
}

enum WaveData {
    static let totalWaves = 5

    static func wave(_ number: Int) -> Wave {
        let n = max(1, min(number, totalWaves))
        switch n {
        case 1: return Wave(rows: 1, cols: 4, enemySpeed: 10, fireInterval: 0.45, emoji: "👾")
        case 2: return Wave(rows: 2, cols: 4, enemySpeed: 12, fireInterval: 0.42, emoji: "👾")
        case 3: return Wave(rows: 2, cols: 5, enemySpeed: 14, fireInterval: 0.40, emoji: "🛸")
        case 4: return Wave(rows: 3, cols: 5, enemySpeed: 16, fireInterval: 0.38, emoji: "🤖")
        case 5: return Wave(rows: 3, cols: 6, enemySpeed: 18, fireInterval: 0.36, emoji: "👽")
        default: return wave(totalWaves)
        }
    }
}
