import Foundation

enum ProgressStore {
    private static let defaults = UserDefaults.standard
    private static let levelKey = "ricochet_currentLevel"
    private static let highestKey = "ricochet_highestLevel"

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
        currentLevel = next
        if next > highestLevel {
            highestLevel = next
        }
    }
}
