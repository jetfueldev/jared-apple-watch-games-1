import Foundation

enum ProgressStore {
    private static let defaults = UserDefaults.standard
    private static let stageKey = "echo_currentStage"
    private static let highestKey = "echo_highestStage"

    static var currentStage: Int {
        get {
            let v = defaults.integer(forKey: stageKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: stageKey) }
    }

    static var highestStage: Int {
        get {
            let v = defaults.integer(forKey: highestKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: highestKey) }
    }

    static func completeStage(_ stage: Int) {
        let next = stage + 1
        currentStage = min(next, StageData.totalStages)
        if next > highestStage {
            highestStage = min(next, StageData.totalStages + 1)
        }
    }

    static func reset() {
        currentStage = 1
        highestStage = 1
    }
}
