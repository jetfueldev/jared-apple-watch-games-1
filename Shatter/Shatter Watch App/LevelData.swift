import SpriteKit

struct Level {
    let rows: Int
    let cols: Int
    let ballSpeed: CGFloat
    let colors: [SKColor]
}

enum LevelData {
    static let totalLevels = 10

    static func level(_ number: Int) -> Level {
        let n = max(1, min(number, totalLevels))
        switch n {
        case 1:
            return Level(rows: 1, cols: 5, ballSpeed: 140,
                         colors: [SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)])
        case 2:
            return Level(rows: 2, cols: 5, ballSpeed: 145,
                         colors: [SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)])
        case 3:
            return Level(rows: 2, cols: 6, ballSpeed: 150,
                         colors: [SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)])
        case 4:
            return Level(rows: 3, cols: 5, ballSpeed: 155,
                         colors: [SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)])
        case 5:
            return Level(rows: 3, cols: 6, ballSpeed: 160,
                         colors: [SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)])
        case 6:
            return Level(rows: 3, cols: 7, ballSpeed: 165,
                         colors: [SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)])
        case 7:
            return Level(rows: 4, cols: 6, ballSpeed: 170,
                         colors: [SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0),
                                  SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)])
        case 8:
            return Level(rows: 4, cols: 7, ballSpeed: 175,
                         colors: [SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)])
        case 9:
            return Level(rows: 5, cols: 6, ballSpeed: 180,
                         colors: [SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)])
        case 10:
            return Level(rows: 5, cols: 7, ballSpeed: 185,
                         colors: [SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0),
                                  SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0),
                                  SKColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)])
        default:
            return level(totalLevels)
        }
    }
}
