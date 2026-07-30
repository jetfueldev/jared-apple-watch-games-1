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
        if wave >= WaveData.totalWaves {
            // whole run complete → record the peak and loop back to a fresh run
            highestWave = WaveData.totalWaves
            currentWave = 1
        } else {
            let next = wave + 1
            currentWave = next
            if next > highestWave { highestWave = next }
        }
    }

    static func reset() {
        currentWave = 1
        highestWave = 1
    }
}
