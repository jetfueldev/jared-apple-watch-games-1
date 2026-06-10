import CoreGraphics
import Foundation

// CLI driver: compile with
//   swiftc -O "Ricochet/Ricochet Watch App/Level.swift" "Ricochet/Ricochet Watch App/LevelData.swift" \
//          "Ricochet/Ricochet Watch App/LevelSimulator.swift" Ricochet/Tools/solution-map-main.swift -o /tmp/solmap
// Prints a solution map for every level: solution windows, widths, bounce counts, verdict.

func ascii(_ map: SolutionMap, cols: Int = 64) -> String {
    let n = map.samples.count
    var out = ""
    for c in 0..<cols {
        let lo = c * n / cols
        let hi = max(lo + 1, (c + 1) * n / cols)
        var minB = Int.max
        for i in lo..<hi where map.samples[i] >= 0 {
            minB = min(minB, map.samples[i])
        }
        if minB == Int.max {
            out += "."
        } else if minB > 9 {
            out += "+"
        } else {
            out += String(minB)
        }
    }
    return out
}

func verdict(_ map: SolutionMap) -> String {
    if !map.solvable { return "✗ UNSOLVABLE" }
    let direct = map.directWidthDeg
    let total = map.totalWidthDeg
    if direct >= 3.0 { return "BORING  — direct shot, \(String(format: "%.1f", direct))° window" }
    if direct > 0 { return "WEAK    — direct shot exists (\(String(format: "%.1f", direct))°)" }
    if total < 0.2 { return "BRUTAL  — only \(String(format: "%.2f", total))° total" }
    if total > 6.0 { return "EASY    — bounce needed but \(String(format: "%.1f", total))° forgiving" }
    return "GOOD    — \(map.minBounces)+ bounce, \(String(format: "%.1f", total))° window"
}

let zones = ["EARTH", "MOON", "STAR", "PLANET", "SUN"]

print("Ricochet Solution Map — 50 levels, 0.05° sweep, -160°..160°")
print("digits = min bounces to hit in that angle bucket, '.' = miss")
print(String(repeating: "═", count: 100))

var rows: [(Int, SolutionMap)] = []

for n in 1...LevelGenerator.totalLevels {
    let level = LevelGenerator.generate(number: n)
    let map = LevelSimulator.solutionMap(level: level)
    rows.append((n, map))

    if (n - 1) % 10 == 0 {
        print("\n── ZONE \( (n - 1) / 10 + 1 ): \(zones[(n - 1) / 10]) " + String(repeating: "─", count: 70))
    }

    let w = map.windows.count
    let total = String(format: "%5.1f°", map.totalWidthDeg)
    let direct = String(format: "%5.1f°", map.directWidthDeg)
    let minB = map.solvable ? "\(map.minBounces)" : "-"
    print(String(format: "L%02d  win:%2d  tot:%@  dir:%@  minB:%@  %@", n, w, total, direct, minB, verdict(map)))
    print("     " + ascii(map))
}

print("\n" + String(repeating: "═", count: 100))
print("SUMMARY")
let unsolvable = rows.filter { !$0.1.solvable }
let boring = rows.filter { $0.1.directWidthDeg >= 3.0 }
let weak = rows.filter { $0.1.directWidthDeg > 0 && $0.1.directWidthDeg < 3.0 }
let bounceRequired = rows.filter { $0.1.solvable && $0.1.directWidthDeg == 0 }
print("Unsolvable:        \(unsolvable.map { String($0.0) }.joined(separator: ", "))")
print("Boring (≥3° direct): \(boring.map { String($0.0) }.joined(separator: ", "))")
print("Weak (direct exists): \(weak.map { String($0.0) }.joined(separator: ", "))")
print("Bounce required:   \(bounceRequired.map { String($0.0) }.joined(separator: ", "))")
