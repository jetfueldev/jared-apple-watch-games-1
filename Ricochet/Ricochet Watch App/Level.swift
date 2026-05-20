import CoreGraphics

enum ObstacleType {
    case ricochet
    case absorb
}

struct Obstacle {
    let from: CGPoint
    let to: CGPoint
    let type: ObstacleType
}

struct Level {
    let number: Int
    let targetPosition: CGPoint
    let obstacles: [Obstacle]
    let alienIndex: Int
}

enum LevelGenerator {

    static let totalLevels = 200
    static let sceneW: CGFloat = 200
    static let sceneH: CGFloat = 240

    static func generate(number: Int) -> Level {
        let n = max(1, min(number, totalLevels))
        let d = Double(n - 1) / Double(totalLevels - 1)

        let tx = sceneW * (0.2 + 0.6 * prand(n, 1))
        let ty = sceneH - 36.0

        var obstacles: [Obstacle] = []

        if n == 1 {
            return Level(number: n, targetPosition: CGPoint(x: sceneW / 2, y: ty),
                         obstacles: [], alienIndex: 0)
        }

        let hCount = horizontalWallCount(n)
        let gapFraction = max(0.13, 0.42 - d * 0.29)
        let gapSize = sceneW * gapFraction

        let playTop = sceneH - 55.0
        let playBot: CGFloat = 55.0

        for i in 0..<hCount {
            let t = Double(i + 1) / Double(hCount + 1)
            let y = playBot + (playTop - playBot) * t

            let gapCenter = sceneW * (0.15 + 0.7 * prand(n, i * 3 + 10))
            let gapLeft = max(0, gapCenter - gapSize / 2)
            let gapRight = min(sceneW, gapCenter + gapSize / 2)

            let useAbsorb = n > 25 && prand(n, i * 3 + 20) > 0.65
            let wallType: ObstacleType = useAbsorb ? .absorb : .ricochet

            if gapLeft > 8 {
                obstacles.append(Obstacle(
                    from: CGPoint(x: 0, y: y),
                    to: CGPoint(x: gapLeft, y: y),
                    type: wallType
                ))
            }
            if sceneW - gapRight > 8 {
                obstacles.append(Obstacle(
                    from: CGPoint(x: gapRight, y: y),
                    to: CGPoint(x: sceneW, y: y),
                    type: wallType
                ))
            }
        }

        if n > 40 {
            let vCount = min((n - 40) / 30 + 1, 3)
            for i in 0..<vCount {
                let x = sceneW * (0.25 + 0.5 * prand(n, i * 3 + 50))
                let yLow = sceneH * (0.25 + 0.15 * prand(n, i * 3 + 60))
                let yHigh = yLow + sceneH * (0.15 + 0.15 * prand(n, i * 3 + 70))

                let useAbsorb = n > 60 && prand(n, i * 3 + 80) > 0.55
                let wallType: ObstacleType = useAbsorb ? .absorb : .ricochet

                obstacles.append(Obstacle(
                    from: CGPoint(x: x, y: yLow),
                    to: CGPoint(x: x, y: min(yHigh, sceneH - 55)),
                    type: wallType
                ))
            }
        }

        if n > 80 {
            let diagCount = min((n - 80) / 40 + 1, 2)
            for i in 0..<diagCount {
                let x1 = sceneW * (0.2 + 0.3 * prand(n, i * 3 + 90))
                let y1 = sceneH * (0.3 + 0.15 * prand(n, i * 3 + 100))
                let x2 = x1 + sceneW * (0.15 + 0.15 * prand(n, i * 3 + 110))
                let y2 = y1 + sceneH * (0.1 + 0.15 * prand(n, i * 3 + 120))

                let useAbsorb = prand(n, i * 3 + 130) > 0.5
                obstacles.append(Obstacle(
                    from: CGPoint(x: x1, y: y1),
                    to: CGPoint(x: min(x2, sceneW), y: min(y2, sceneH - 55)),
                    type: useAbsorb ? .absorb : .ricochet
                ))
            }
        }

        return Level(
            number: n,
            targetPosition: CGPoint(x: tx, y: ty),
            obstacles: obstacles,
            alienIndex: (n - 1) % 6
        )
    }

    private static func horizontalWallCount(_ level: Int) -> Int {
        switch level {
        case 1...3: return 0
        case 4...8: return 1
        case 9...18: return 2
        case 19...35: return 3
        case 36...60: return 4
        case 61...100: return 5
        default: return min(6, 5 + (level - 100) / 50)
        }
    }

    private static func prand(_ level: Int, _ salt: Int) -> Double {
        let x = sin(Double(level * 127 + salt * 311 + 7)) * 43758.5453
        return x - floor(x)
    }

    static func zoneName(_ level: Int) -> String {
        switch (level - 1) / 25 {
        case 0: return "🌍"
        case 1: return "🌙"
        case 2: return "⭐"
        case 3: return "🪐"
        case 4: return "☀️"
        case 5: return "🌌"
        case 6: return "🔥"
        default: return "💫"
        }
    }
}
