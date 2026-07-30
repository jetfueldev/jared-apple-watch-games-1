// Headless combat/balance simulator for Sentinel.
// Plays out the whole 10-wave run with the real DPS + platoon-growth + turret-upgrade math
// (mirrored from GameScene) so waves can be balanced from numbers, not guesses. No SpriteKit.
//
//   cat "Sentinel/Sentinel Watch App/WaveData.swift" "Sentinel/Sentinel Watch App/Platoon.swift" \
//       Sentinel/Tools/balance-sim.swift > /tmp/sim.swift && swiftc /tmp/sim.swift -o /tmp/sim && /tmp/sim
//
// Model + assumptions (kept intentionally conservative):
//  - platoon units + 2 auto-targeting turrets focus-fire the enemy closest to breaching.
//  - platoon bolts land at PLATOON_HIT_RATE (player must steer to aim); turrets auto-aim (100%).
//  - 1 damage per bolt; DPS = Σ 1/interval. Platoon grows every chargeNeeded kills.
//  - each wave is a fresh 3 lives (new scene); platoon + charge carry across waves; turrets
//    upgrade +1 per cleared wave (cap 5). Boss breaching = instant loss.

import Foundation

// Mirrored from GameScene (keep in sync).
let chargeNeeded = 5
let platoonHitRate = 0.65
let floorY = 33.0
let spawnFrontY = 240.0 - 20.0
let rowSpacing = 24.0
let bossSpawnY = 240.0 - 46.0
let turretMaxTier = 5

func fireInterval(_ tier: Int) -> Double { max(0.18, 0.5 - Double(tier - 1) * 0.07) }
func turretInterval(_ tier: Int) -> Double { fireInterval(tier) + 0.25 }

func platoonDPS(_ tiers: [Int]) -> Double {
    tiers.reduce(0.0) { $0 + 1.0 / fireInterval($1) } * platoonHitRate
}
func turretDPS(_ tier: Int) -> Double { 2.0 * (1.0 / turretInterval(tier)) }

struct SimEnemy { var hp: Double; let breachTime: Double; var dead = false; var breached = false }

struct WaveResult {
    let cleared: Bool
    let livesLost: Int
    let timeToClear: Double
    let enteringPlatoon: [Int]
    let turretTier: Int
    let dps: Double
}

// Simulate one wave. Mutates carried platoon/charge; returns the outcome.
func simulate(wave: Wave, waveNumber: Int, platoon: inout [Int?], charge: inout Int) -> WaveResult {
    let turretTier = min(waveNumber, turretMaxTier)   // [1,1] upgrading +1 per cleared wave
    let entering = platoon.compactMap { $0 }

    // build enemies with breach times
    var enemies: [SimEnemy] = []
    if wave.isBoss {
        enemies.append(SimEnemy(hp: Double(wave.enemyHP), breachTime: (bossSpawnY - floorY) / wave.enemySpeed))
    } else {
        for r in 0..<wave.rows {
            let y = spawnFrontY + Double(r) * rowSpacing
            let bt = (y - floorY) / wave.enemySpeed
            for _ in 0..<wave.cols { enemies.append(SimEnemy(hp: Double(wave.enemyHP), breachTime: bt)) }
        }
    }
    enemies.sort { $0.breachTime < $1.breachTime }

    let dt = 0.05
    var t = 0.0
    var lives = 3
    var livesLost = 0
    var clearedTime = 0.0
    let startDPS = platoonDPS(platoon.compactMap { $0 }) + turretDPS(turretTier)

    while lives > 0 {
        // focus = alive enemy closest to breaching
        guard let fi = enemies.firstIndex(where: { !$0.dead && !$0.breached }) else {
            clearedTime = t; break
        }
        t += dt
        let dps = platoonDPS(platoon.compactMap { $0 }) + turretDPS(turretTier)
        enemies[fi].hp -= dps * dt
        if enemies[fi].hp <= 0 {
            enemies[fi].dead = true
            charge += 1
            if charge >= chargeNeeded { charge = 0; platoon = Platoon.grow(platoon) }
        }
        // breaches
        for i in enemies.indices where !enemies[i].dead && !enemies[i].breached && enemies[i].breachTime <= t {
            enemies[i].breached = true
            if wave.isBoss { lives = 0; livesLost = 3 }
            else { lives -= 1; livesLost += 1 }
        }
        if t > 120 { break }   // safety
    }

    let cleared = enemies.allSatisfy { $0.dead } && lives > 0
    return WaveResult(cleared: cleared, livesLost: livesLost, timeToClear: clearedTime,
                      enteringPlatoon: entering, turretTier: turretTier, dps: startDPS)
}

// --- run the full sequence ---
var platoon = Platoon.seed(from: [1])
var charge = 0
var allCleared = true

print("wave │ enter platoon │ turret │  DPS  │ totalHP │ clear(s) │ lives lost │ result")
print("─────┼───────────────┼────────┼───────┼─────────┼──────────┼────────────┼────────")
for n in 1...WaveData.totalWaves {
    let w = WaveData.wave(n)
    let before = platoon.compactMap { $0 }
    let r = simulate(wave: w, waveNumber: n, platoon: &platoon, charge: &charge)
    let verdict = r.cleared ? "OK" : "❌ LOSS"
    if !r.cleared { allCleared = false }
    print(String(format: "%3d  │ %-13@ │ T%d ×2  │ %5.1f │ %7d │ %8.1f │ %10d │ %@%@",
                 n, "\(before)", r.turretTier, r.dps, w.totalHP, r.timeToClear, r.livesLost,
                 verdict, w.isBoss ? " (BOSS)" : ""))
    if !r.cleared { break }   // a real player would be sent back; stop the projection
}
print("")
print(allCleared ? "✅ full run clears with the modeled progression (hit rate \(platoonHitRate))"
                 : "⚠️  run stalls above — tune the flagged wave(s)")
