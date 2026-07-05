import CoreGraphics
import Foundation

// Verifies the Swift port of bumpers + portals against the HTML/JS solver.
// Reads slots 67-76 (recipe format) from editor-library.json, converts each to a
// Level, runs LevelSimulator, and prints solvable + min-bounce + window so the
// result can be diffed against `node Ricochet/Tools/mech.js`.
//
//   swiftc -O "Ricochet/Ricochet Watch App/Level.swift" \
//          "Ricochet/Ricochet Watch App/LevelData.swift" \
//          "Ricochet/Ricochet Watch App/LevelSimulator.swift" \
//          Ricochet/Tools/verify-portal.swift -o /tmp/verifyportal && /tmp/verifyportal

let targetY: CGFloat = 188

func d(_ a: Any?) -> CGFloat { CGFloat((a as? NSNumber)?.doubleValue ?? 0) }

func levelFrom(_ board: [String: Any], number: Int) -> Level {
    let tx = d(board["tx"])
    let recipes = board["recipes"] as? [[String: Any]] ?? []
    var obstacles: [Obstacle] = []
    var bumpers: [Bumper] = []
    var portals: [Portal] = []
    for r in recipes {
        switch r["kind"] as? String {
        case "line":
            let type: ObstacleType = (r["abs"] as? Bool == true) ? .absorb : .ricochet
            obstacles.append(Obstacle(
                from: CGPoint(x: d(r["x1"]), y: d(r["y1"])),
                to: CGPoint(x: d(r["x2"]), y: d(r["y2"])),
                type: type))
        case "box":
            // Expand to 4 ricochet walls, matching JS flatten().
            let type: ObstacleType = (r["abs"] as? Bool == true) ? .absorb : .ricochet
            let lo = min(d(r["x1"]), d(r["x2"])), hi = max(d(r["x1"]), d(r["x2"]))
            let bo = min(d(r["y1"]), d(r["y2"])), to = max(d(r["y1"]), d(r["y2"]))
            let corners = [
                (CGPoint(x: lo, y: bo), CGPoint(x: hi, y: bo)),
                (CGPoint(x: hi, y: bo), CGPoint(x: hi, y: to)),
                (CGPoint(x: hi, y: to), CGPoint(x: lo, y: to)),
                (CGPoint(x: lo, y: to), CGPoint(x: lo, y: bo)),
            ]
            for (a, b) in corners { obstacles.append(Obstacle(from: a, to: b, type: type)) }
        case "bumper":
            bumpers.append(Bumper(center: CGPoint(x: d(r["cx"]), y: d(r["cy"])), radius: d(r["r"])))
        case "portal":
            portals.append(Portal(
                a: CGPoint(x: d(r["ax"]), y: d(r["ay"])),
                b: CGPoint(x: d(r["bx"]), y: d(r["by"])),
                radius: d(r["r"])))
        default:
            break
        }
    }
    return Level(number: number, targetPosition: CGPoint(x: tx, y: targetY),
                 obstacles: obstacles, alienIndex: 0, bumpers: bumpers, portals: portals)
}

let libURL = URL(fileURLWithPath: "Ricochet/editor-library.json")
let data = try! Data(contentsOf: libURL)
let boards = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]

print("Swift port verification — slots 67-88")
print(String(repeating: "─", count: 60))
var exported: [[String: Any]] = []
for slot in 67...min(88, boards.count) {
    let level = levelFrom(boards[slot - 1], number: slot)
    let result = LevelSimulator.simulate(level: level)
    let map = LevelSimulator.solutionMap(level: level)
    let minB = map.windows.filter { $0.widthDeg >= 0.15 }.map(\.minBounces).min() ?? -1
    let widest = map.windows.filter { $0.widthDeg >= 0.15 }.map(\.widthDeg).max() ?? 0
    let tpCount = result.teleports.count
    let hasBump = !level.bumpers.isEmpty
    let kind = level.portals.isEmpty ? (hasBump ? "bumper" : "line") : "portal"
    let flag = result.solvable ? "✓" : "✗"
    print(String(format: "%@ slot%d  tx%-3.0f  %@  solv:%@  minB:%d  win:%.1f°  tp:%d%@",
                 flag, slot, level.targetPosition.x, kind.padding(toLength: 6, withPad: " ", startingAt: 0),
                 result.solvable ? "yes" : "no", minB, widest, tpCount, hasBump ? " bump" : ""))
    let hit = result.path.last ?? .zero
    exported.append([
        "slot": slot,
        "angle": Double(result.solutionAngle ?? 0),
        "bounces": result.bounces,
        "hx": Double(hit.x), "hy": Double(hit.y),
    ])
}
let outData = try! JSONSerialization.data(withJSONObject: exported)
try! outData.write(to: URL(fileURLWithPath: "/tmp/swift-sol.json"))
