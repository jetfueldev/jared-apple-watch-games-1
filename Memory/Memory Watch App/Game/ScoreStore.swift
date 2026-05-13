import Foundation
import SwiftUI

class ScoreStore {
    static let shared = ScoreStore()

    func bestScore(themeID: String, pairs: Int) -> BestScore? {
        let key = "bestScore.\(themeID).\(pairs)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(BestScore.self, from: data)
    }

    func saveBestScore(_ score: BestScore, themeID: String, pairs: Int) {
        let key = "bestScore.\(themeID).\(pairs)"
        if let existing = bestScore(themeID: themeID, pairs: pairs) {
            if score.moves < existing.moves ||
               (score.moves == existing.moves && score.timeSeconds < existing.timeSeconds) {
                save(score, forKey: key)
            }
        } else {
            save(score, forKey: key)
        }
    }

    func isNewBest(_ score: BestScore, themeID: String, pairs: Int) -> Bool {
        guard let existing = bestScore(themeID: themeID, pairs: pairs) else { return true }
        return score.moves < existing.moves ||
               (score.moves == existing.moves && score.timeSeconds < existing.timeSeconds)
    }

    private func save(_ score: BestScore, forKey key: String) {
        if let data = try? JSONEncoder().encode(score) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
