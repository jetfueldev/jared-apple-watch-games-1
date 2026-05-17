import Foundation
import SwiftUI

class ScoreStore {
    static let shared = ScoreStore()

    private let defaults = UserDefaults.standard

    // MARK: - Best Scores

    func bestScore(themeID: String, pairs: Int) -> BestScore? {
        let key = "bestScore.\(themeID).\(pairs)"
        guard let data = defaults.data(forKey: key) else { return nil }
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

    func isCompleted(themeID: String, pairs: Int) -> Bool {
        bestScore(themeID: themeID, pairs: pairs) != nil
    }

    // MARK: - Saved Games (one per theme)

    func saveGameSnapshot(_ snapshot: GameSnapshot) {
        let key = "savedGame.\(snapshot.themeID)"
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }

    func loadGameSnapshot(themeID: String) -> GameSnapshot? {
        let key = "savedGame.\(themeID)"
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GameSnapshot.self, from: data)
    }

    func clearGameSnapshot(themeID: String) {
        let key = "savedGame.\(themeID)"
        defaults.removeObject(forKey: key)
    }

    func allSavedGames() -> [GameSnapshot] {
        Themes.all.compactMap { loadGameSnapshot(themeID: $0.id) }
    }

    // MARK: - Progression

    func firstUnbeatenSize(themeID: String) -> GridSize? {
        GridSizes.all.first { !isCompleted(themeID: themeID, pairs: $0.pairs) }
    }

    func nextUnbeatenSize(after current: GridSize, themeID: String) -> GridSize? {
        guard let currentIndex = GridSizes.all.firstIndex(of: current) else { return nil }
        let remaining = GridSizes.all[(currentIndex + 1)...]
        return remaining.first { !isCompleted(themeID: themeID, pairs: $0.pairs) }
    }

    // MARK: - Private

    private func save(_ score: BestScore, forKey key: String) {
        if let data = try? JSONEncoder().encode(score) {
            defaults.set(data, forKey: key)
        }
    }
}
