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

    static let totalLevels = 50
    static let sceneW: CGFloat = 200
    static let sceneH: CGFloat = 240

    static func generate(number: Int) -> Level {
        let n = max(1, min(number, totalLevels))
        let def = LevelData.build(level: n)
        return Level(
            number: n,
            targetPosition: CGPoint(x: def.targetX, y: sceneH - 52),
            obstacles: def.obstacles,
            alienIndex: (n - 1) % 6
        )
    }

    static func zoneName(_ level: Int) -> String {
        switch (level - 1) / 10 {
        case 0: return "🌍"
        case 1: return "🌙"
        case 2: return "⭐"
        case 3: return "🪐"
        default: return "☀️"
        }
    }
}
