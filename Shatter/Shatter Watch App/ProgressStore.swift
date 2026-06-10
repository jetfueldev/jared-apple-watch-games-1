import Foundation

enum ProgressStore {
    private static let defaults = UserDefaults.standard
    private static let levelKey = "shatter_currentLevel"
    private static let highestKey = "shatter_highestLevel"

    static var currentLevel: Int {
        get {
            let v = defaults.integer(forKey: levelKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: levelKey) }
    }

    static var highestLevel: Int {
        get {
            let v = defaults.integer(forKey: highestKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: highestKey) }
    }

    static func completeLevel(_ level: Int) {
        let next = level + 1
        currentLevel = min(next, LevelData.totalLevels + 1)
        if next > highestLevel {
            highestLevel = min(next, LevelData.totalLevels + 1)
        }
    }

    static func reset() {
        currentLevel = 1
        highestLevel = 1
    }
}
