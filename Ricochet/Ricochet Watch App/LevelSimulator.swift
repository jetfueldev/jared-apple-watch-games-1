import CoreGraphics
import Foundation

struct SimulationResult {
    let level: Int
    let solvable: Bool
    let solutionAngle: CGFloat?
    let bounces: Int
    let path: [CGPoint]
    /// Indices i where path[i] was reached by a portal jump from path[i-1] (not travel).
    var teleports: Set<Int> = []
}

struct SolutionWindow {
    let startDeg: CGFloat
    let endDeg: CGFloat
    let minBounces: Int
    var widthDeg: CGFloat { endDeg - startDeg }
}

struct SolutionMap {
    let level: Int
    /// -1 = miss, otherwise bounce count of the hit at that sample
    let samples: [Int]
    let windows: [SolutionWindow]

    var solvable: Bool { !windows.isEmpty }
    var totalWidthDeg: CGFloat { windows.reduce(0) { $0 + $1.widthDeg } }
    var directWidthDeg: CGFloat {
        windows.filter { $0.minBounces == 0 }.reduce(0) { $0 + $1.widthDeg }
    }
    var minBounces: Int { windows.map(\.minBounces).min() ?? -1 }
    var widestWindowDeg: CGFloat { windows.map(\.widthDeg).max() ?? 0 }
}

enum LevelSimulator {

    private static let sceneW: CGFloat = 200
    private static let sceneH: CGFloat = 240
    private static let playerPos = CGPoint(x: 100, y: 28)
    private static let targetRadius: CGFloat = 16
    private static let maxBounces = 20
    private static let spawnDist: CGFloat = 20

    static func simulateAll(
        from: Int = 1,
        to: Int = LevelGenerator.totalLevels,
        onResult: @escaping (SimulationResult) -> Void,
        onComplete: @escaping ([SimulationResult]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [SimulationResult] = []
            for n in from...to {
                let level = LevelGenerator.generate(number: n)
                let result = simulate(level: level)
                results.append(result)
                DispatchQueue.main.async { onResult(result) }
            }
            DispatchQueue.main.async { onComplete(results) }
        }
    }

    static func simulate(level: Level, angleSteps: Int = 720) -> SimulationResult {
        let minAngle: CGFloat = -2.8
        let maxAngle: CGFloat = 2.8
        let step = (maxAngle - minAngle) / CGFloat(angleSteps)

        var best: (angle: CGFloat, result: RayResult)? = nil

        for i in 0...angleSteps {
            let angle = minAngle + step * CGFloat(i)
            let result = castRay(angle: angle, level: level)
            if result.hit {
                if let current = best {
                    if result.bounces < current.result.bounces ||
                       (result.bounces == current.result.bounces && pathLength(result) < pathLength(current.result)) {
                        best = (angle, result)
                    }
                } else {
                    best = (angle, result)
                }
            }
        }

        if let best {
            return SimulationResult(
                level: level.number,
                solvable: true,
                solutionAngle: best.angle,
                bounces: best.result.bounces,
                path: best.result.path,
                teleports: best.result.teleports
            )
        }

        return SimulationResult(
            level: level.number,
            solvable: false,
            solutionAngle: nil,
            bounces: 0,
            path: []
        )
    }

    // MARK: - Solution Map (full angle sweep)

    static func solutionMap(level: Level, stepDeg: CGFloat = 0.05) -> SolutionMap {
        let minAngle: CGFloat = -2.8
        let maxAngle: CGFloat = 2.8
        let stepRad = stepDeg * .pi / 180
        let count = Int((maxAngle - minAngle) / stepRad)

        var samples = [Int](repeating: -1, count: count + 1)
        for i in 0...count {
            let angle = minAngle + stepRad * CGFloat(i)
            let result = castRay(angle: angle, level: level)
            if result.hit { samples[i] = result.bounces }
        }

        var windows: [SolutionWindow] = []
        var runStart = -1
        var runMinBounces = Int.max

        func closeRun(at endIndex: Int) {
            guard runStart >= 0 else { return }
            let startDeg = (minAngle + stepRad * CGFloat(runStart)) * 180 / .pi
            let endDeg = (minAngle + stepRad * CGFloat(endIndex)) * 180 / .pi
            windows.append(SolutionWindow(startDeg: startDeg, endDeg: endDeg, minBounces: runMinBounces))
            runStart = -1
            runMinBounces = Int.max
        }

        for i in 0...count {
            if samples[i] >= 0 {
                if runStart < 0 { runStart = i }
                runMinBounces = min(runMinBounces, samples[i])
            } else {
                closeRun(at: i - 1)
            }
        }
        closeRun(at: count)

        return SolutionMap(level: level.number, samples: samples, windows: windows)
    }

    private static func pathLength(_ result: RayResult) -> CGFloat {
        let path = result.path
        var total: CGFloat = 0
        for i in 1..<path.count where !result.teleports.contains(i) {
            total += hypot(path[i].x - path[i - 1].x, path[i].y - path[i - 1].y)
        }
        return total
    }

    private struct RayResult {
        let hit: Bool
        let bounces: Int
        let path: [CGPoint]
        var teleports: Set<Int> = []
    }

    private enum HitKind { case wall, bumper, portal }

    private static func castRay(angle: CGFloat, level: Level) -> RayResult {
        let dx = -sin(angle)
        let dy = cos(angle)

        var pos = CGPoint(
            x: playerPos.x + dx * spawnDist,
            y: playerPos.y + dy * spawnDist
        )
        var dir = CGPoint(x: dx, y: dy)
        var path: [CGPoint] = [pos]
        var teleports: Set<Int> = []

        // (a, b, canBounce): side walls bounce, top/bottom void absorbs.
        var walls: [(CGPoint, CGPoint, Bool)] = [
            (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: sceneH), true),
            (CGPoint(x: sceneW, y: 0), CGPoint(x: sceneW, y: sceneH), true),
            (CGPoint(x: 0, y: sceneH), CGPoint(x: sceneW, y: sceneH), false),
            (CGPoint(x: 0, y: 0), CGPoint(x: sceneW, y: 0), false),
        ]
        for obstacle in level.obstacles {
            walls.append((obstacle.from, obstacle.to, obstacle.type == .ricochet))
        }

        for bounce in 0...maxBounces {
            let targetHitT = rayCircleIntersection(
                origin: pos, dir: dir,
                center: level.targetPosition, radius: targetRadius
            )

            var closest: CGFloat = .greatestFiniteMagnitude
            var kind: HitKind? = nil
            var hitWall: (CGPoint, CGPoint, Bool)? = nil
            var hitBumper: Bumper? = nil
            var portalExit: (center: CGPoint, radius: CGFloat)? = nil

            for wall in walls {
                if let t = raySegmentIntersection(origin: pos, dir: dir, a: wall.0, b: wall.1),
                   t > 0.1, t < closest {
                    closest = t; kind = .wall; hitWall = wall
                }
            }
            for bumper in level.bumpers {
                if let t = rayCircleIntersection(origin: pos, dir: dir, center: bumper.center, radius: bumper.radius),
                   t > 0.1, t < closest {
                    closest = t; kind = .bumper; hitBumper = bumper
                }
            }
            for portal in level.portals {
                if let t = rayCircleIntersection(origin: pos, dir: dir, center: portal.a, radius: portal.radius),
                   t > 0.1, t < closest {
                    closest = t; kind = .portal; portalExit = (portal.b, portal.radius)
                }
                if let t = rayCircleIntersection(origin: pos, dir: dir, center: portal.b, radius: portal.radius),
                   t > 0.1, t < closest {
                    closest = t; kind = .portal; portalExit = (portal.a, portal.radius)
                }
            }

            if let hitT = targetHitT, hitT > 0.1, hitT < closest {
                path.append(CGPoint(x: pos.x + dir.x * hitT, y: pos.y + dir.y * hitT))
                return RayResult(hit: true, bounces: bounce, path: path, teleports: teleports)
            }

            guard let kind else {
                return RayResult(hit: false, bounces: bounce, path: path, teleports: teleports)
            }

            switch kind {
            case .wall:
                let wall = hitWall!
                if !wall.2 {
                    path.append(CGPoint(x: pos.x + dir.x * closest, y: pos.y + dir.y * closest))
                    return RayResult(hit: false, bounces: bounce, path: path, teleports: teleports)
                }
                pos = CGPoint(x: pos.x + dir.x * closest, y: pos.y + dir.y * closest)
                let wdx = wall.1.x - wall.0.x, wdy = wall.1.y - wall.0.y
                let len = hypot(wdx, wdy)
                let nx = -wdy / len, ny = wdx / len
                let dot = dir.x * nx + dir.y * ny
                dir = CGPoint(x: dir.x - 2 * dot * nx, y: dir.y - 2 * dot * ny)
                path.append(pos)

            case .bumper:
                let bumper = hitBumper!
                pos = CGPoint(x: pos.x + dir.x * closest, y: pos.y + dir.y * closest)
                let nx = (pos.x - bumper.center.x) / bumper.radius
                let ny = (pos.y - bumper.center.y) / bumper.radius
                let dot = dir.x * nx + dir.y * ny
                dir = CGPoint(x: dir.x - 2 * dot * nx, y: dir.y - 2 * dot * ny)
                path.append(pos)

            case .portal:
                let exit = portalExit!
                pos = CGPoint(x: pos.x + dir.x * closest, y: pos.y + dir.y * closest)
                path.append(pos)
                pos = CGPoint(x: exit.center.x + dir.x * (exit.radius + 1),
                              y: exit.center.y + dir.y * (exit.radius + 1))
                path.append(pos)
                teleports.insert(path.count - 1)
            }
        }

        return RayResult(hit: false, bounces: maxBounces, path: path, teleports: teleports)
    }

    private static func raySegmentIntersection(
        origin: CGPoint, dir: CGPoint,
        a: CGPoint, b: CGPoint
    ) -> CGFloat? {
        let dx = b.x - a.x
        let dy = b.y - a.y

        let denom = dir.x * dy - dir.y * dx
        guard abs(denom) > 1e-10 else { return nil }

        let t = ((a.x - origin.x) * dy - (a.y - origin.y) * dx) / denom
        let s = ((a.x - origin.x) * dir.y - (a.y - origin.y) * dir.x) / denom

        guard t > 0 && s >= 0 && s <= 1 else { return nil }
        return t
    }

    private static func rayCircleIntersection(
        origin: CGPoint, dir: CGPoint,
        center: CGPoint, radius: CGFloat
    ) -> CGFloat? {
        let ox = origin.x - center.x
        let oy = origin.y - center.y

        let a = dir.x * dir.x + dir.y * dir.y
        let b = 2 * (ox * dir.x + oy * dir.y)
        let c = ox * ox + oy * oy - radius * radius

        let disc = b * b - 4 * a * c
        guard disc >= 0 else { return nil }

        let sqrtDisc = sqrt(disc)
        let t1 = (-b - sqrtDisc) / (2 * a)
        let t2 = (-b + sqrtDisc) / (2 * a)

        if t1 > 0.1 { return t1 }
        if t2 > 0.1 { return t2 }
        return nil
    }
}
