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

// Difficulty bands: min bounce count must climb continuously with level number.
func bandMinBounces(_ n: Int) -> Int {
    switch n {
    case 1...3:   return 0
    case 4...10:  return 1
    case 11...20: return 2
    case 21...30: return 3
    case 31...40: return 4
    default:      return 5
    }
}

func verdict(_ n: Int, _ map: SolutionMap) -> String {
    if !map.solvable { return "✗ UNSOLVABLE" }
    let direct = map.directWidthDeg
    let total = map.totalWidthDeg
    let want = bandMinBounces(n)
    if n >= 4 && direct > 0 { return "✗ DIRECT  — \(String(format: "%.1f", direct))° straight shot leaks through" }
    if map.minBounces < want { return "✗ LOW     — minB \(map.minBounces), band needs \(want)" }
    if total < 0.15 { return "✗ BRUTAL  — only \(String(format: "%.2f", total))° total" }
    return "OK      — \(map.minBounces)+ bounce, \(String(format: "%.1f", total))° window"
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
    print(String(format: "L%02d  win:%2d  tot:%@  dir:%@  minB:%@  %@", n, w, total, direct, minB, verdict(n, map)))
    print("     " + ascii(map))
}

print("\n" + String(repeating: "═", count: 100))
print("SUMMARY")
let unsolvable = rows.filter { !$0.1.solvable }
let directLeaks = rows.filter { $0.0 >= 4 && $0.1.directWidthDeg > 0 }
let lowBounce = rows.filter { $0.1.solvable && $0.1.minBounces < bandMinBounces($0.0) }
let brutal = rows.filter { $0.1.solvable && $0.1.totalWidthDeg < 0.15 }
print("Unsolvable:   \(unsolvable.map { String($0.0) }.joined(separator: ", "))")
print("Direct leaks: \(directLeaks.map { String($0.0) }.joined(separator: ", "))")
print("Below band:   \(lowBounce.map { String($0.0) }.joined(separator: ", "))")
print("Brutal:       \(brutal.map { String($0.0) }.joined(separator: ", "))")
print("minB curve:   " + rows.map { $0.1.solvable ? String($0.1.minBounces) : "-" }.joined())
print("width curve:  " + rows.map { String(format: "%5.1f", $0.1.totalWidthDeg) }.joined())

// In-game shots travel at 250pt/s and die after 6s → solutions must be under ~1400pt.
print("\nSolution path lengths (max budget 1400pt):")
for n in 1...LevelGenerator.totalLevels {
    let level = LevelGenerator.generate(number: n)
    let result = LevelSimulator.simulate(level: level)
    guard result.solvable else { continue }
    var len: CGFloat = 0
    for i in 1..<result.path.count {
        len += hypot(result.path[i].x - result.path[i - 1].x, result.path[i].y - result.path[i - 1].y)
    }
    let flag = len > 1400 ? "  ✗ TOO LONG" : ""
    if len > 800 || !flag.isEmpty {
        print(String(format: "L%02d  %4.0fpt  (%d bounces)%@", n, len, result.bounces, flag))
    }
}
