import CoreGraphics

struct SimulationResult {
    let level: Int
    let solvable: Bool
    let solutionAngle: CGFloat?
    let bounces: Int
    let path: [CGPoint]
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

        var best: (angle: CGFloat, bounces: Int, path: [CGPoint])? = nil

        for i in 0...angleSteps {
            let angle = minAngle + step * CGFloat(i)
            let result = castRay(angle: angle, level: level)
            if result.hit {
                if let current = best {
                    if result.bounces < current.bounces ||
                       (result.bounces == current.bounces && pathLength(result.path) < pathLength(current.path)) {
                        best = (angle, result.bounces, result.path)
                    }
                } else {
                    best = (angle, result.bounces, result.path)
                }
            }
        }

        if let best {
            return SimulationResult(
                level: level.number,
                solvable: true,
                solutionAngle: best.angle,
                bounces: best.bounces,
                path: best.path
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

    private static func pathLength(_ path: [CGPoint]) -> CGFloat {
        var total: CGFloat = 0
        for i in 1..<path.count {
            total += hypot(path[i].x - path[i - 1].x, path[i].y - path[i - 1].y)
        }
        return total
    }

    private struct RayResult {
        let hit: Bool
        let bounces: Int
        let path: [CGPoint]
    }

    private static func castRay(angle: CGFloat, level: Level) -> RayResult {
        let dx = -sin(angle)
        let dy = cos(angle)

        var pos = CGPoint(
            x: playerPos.x + dx * spawnDist,
            y: playerPos.y + dy * spawnDist
        )
        var dir = CGPoint(x: dx, y: dy)
        var path: [CGPoint] = [pos]

        let sideWalls: [(CGPoint, CGPoint, Bool)] = [
            (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: sceneH), true),
            (CGPoint(x: sceneW, y: 0), CGPoint(x: sceneW, y: sceneH), true),
        ]

        let voidWalls: [(CGPoint, CGPoint, Bool)] = [
            (CGPoint(x: 0, y: sceneH), CGPoint(x: sceneW, y: sceneH), false),
            (CGPoint(x: 0, y: 0), CGPoint(x: sceneW, y: 0), false),
        ]

        var allWalls: [(CGPoint, CGPoint, Bool)] = []
        allWalls.append(contentsOf: sideWalls)
        allWalls.append(contentsOf: voidWalls)

        for obstacle in level.obstacles {
            let canBounce = obstacle.type == .ricochet
            allWalls.append((obstacle.from, obstacle.to, canBounce))
        }

        for bounce in 0...maxBounces {
            let targetHitT = rayCircleIntersection(
                origin: pos, dir: dir,
                center: level.targetPosition, radius: targetRadius
            )

            var closestT: CGFloat = .greatestFiniteMagnitude
            var closestWallIndex = -1

            for (i, wall) in allWalls.enumerated() {
                if let t = raySegmentIntersection(
                    origin: pos, dir: dir,
                    a: wall.0, b: wall.1
                ), t > 0.1 && t < closestT {
                    closestT = t
                    closestWallIndex = i
                }
            }

            if let hitT = targetHitT, hitT > 0.1 && hitT < closestT {
                let targetPt = CGPoint(
                    x: pos.x + dir.x * hitT,
                    y: pos.y + dir.y * hitT
                )
                path.append(targetPt)
                return RayResult(hit: true, bounces: bounce, path: path)
            }

            guard closestWallIndex >= 0 else {
                return RayResult(hit: false, bounces: bounce, path: path)
            }

            let wall = allWalls[closestWallIndex]
            let canBounce = wall.2

            if !canBounce {
                return RayResult(hit: false, bounces: bounce, path: path)
            }

            let hitPoint = CGPoint(
                x: pos.x + dir.x * closestT,
                y: pos.y + dir.y * closestT
            )

            let wallDx = wall.1.x - wall.0.x
            let wallDy = wall.1.y - wall.0.y
            let wallLen = hypot(wallDx, wallDy)
            let nx = -wallDy / wallLen
            let ny = wallDx / wallLen

            let dot = dir.x * nx + dir.y * ny
            dir = CGPoint(x: dir.x - 2 * dot * nx, y: dir.y - 2 * dot * ny)
            pos = hitPoint
            path.append(pos)
        }

        return RayResult(hit: false, bounces: maxBounces, path: path)
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
