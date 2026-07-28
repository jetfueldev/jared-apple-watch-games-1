import Foundation

enum ProgressStore {
    private static let defaults = UserDefaults.standard
    private static let waveKey = "sentinel_currentWave"
    private static let highestKey = "sentinel_highestWave"

    static var currentWave: Int {
        get {
            let v = defaults.integer(forKey: waveKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: waveKey) }
    }

    static var highestWave: Int {
        get {
            let v = defaults.integer(forKey: highestKey)
            return v > 0 ? v : 1
        }
        set { defaults.set(newValue, forKey: highestKey) }
    }

    static func completeWave(_ wave: Int) {
        let next = wave + 1
        currentWave = min(next, WaveData.totalWaves + 1)
        if next > highestWave {
            highestWave = min(next, WaveData.totalWaves + 1)
        }
    }

    static func reset() {
        currentWave = 1
        highestWave = 1
    }
}
