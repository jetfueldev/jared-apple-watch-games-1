import XCTest
@testable import Memory_Watch_App

final class ScoreStoreTests: XCTestCase {

    private let testTheme = "test_\(UUID().uuidString.prefix(8))"

    func testSaveAndLoadBestScore() {
        let score = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())
        ScoreStore.shared.saveBestScore(score, themeID: testTheme, pairs: 2)

        let loaded = ScoreStore.shared.bestScore(themeID: testTheme, pairs: 2)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.moves, 5)
        XCTAssertEqual(loaded?.timeSeconds, 10.0)
    }

    func testBetterScoreReplaceWorse() {
        let worse = BestScore(moves: 10, timeSeconds: 20.0, achievedAt: Date())
        let better = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())

        ScoreStore.shared.saveBestScore(worse, themeID: testTheme, pairs: 3)
        ScoreStore.shared.saveBestScore(better, themeID: testTheme, pairs: 3)

        let loaded = ScoreStore.shared.bestScore(themeID: testTheme, pairs: 3)
        XCTAssertEqual(loaded?.moves, 5)
    }

    func testWorseScoreDoesNotReplace() {
        let better = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())
        let worse = BestScore(moves: 10, timeSeconds: 20.0, achievedAt: Date())

        ScoreStore.shared.saveBestScore(better, themeID: testTheme, pairs: 4)
        ScoreStore.shared.saveBestScore(worse, themeID: testTheme, pairs: 4)

        let loaded = ScoreStore.shared.bestScore(themeID: testTheme, pairs: 4)
        XCTAssertEqual(loaded?.moves, 5)
    }

    func testTiebreakByTime() {
        let slow = BestScore(moves: 5, timeSeconds: 20.0, achievedAt: Date())
        let fast = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())

        ScoreStore.shared.saveBestScore(slow, themeID: testTheme, pairs: 5)
        ScoreStore.shared.saveBestScore(fast, themeID: testTheme, pairs: 5)

        let loaded = ScoreStore.shared.bestScore(themeID: testTheme, pairs: 5)
        XCTAssertEqual(loaded?.timeSeconds, 10.0)
    }

    func testIsNewBestWhenNoPrior() {
        let score = BestScore(moves: 10, timeSeconds: 20.0, achievedAt: Date())
        XCTAssertTrue(ScoreStore.shared.isNewBest(score, themeID: testTheme, pairs: 99))
    }

    func testIsNewBestWithBetterScore() {
        let first = BestScore(moves: 10, timeSeconds: 20.0, achievedAt: Date())
        ScoreStore.shared.saveBestScore(first, themeID: testTheme, pairs: 6)

        let better = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())
        XCTAssertTrue(ScoreStore.shared.isNewBest(better, themeID: testTheme, pairs: 6))
    }

    func testIsNewBestWithWorseScore() {
        let first = BestScore(moves: 5, timeSeconds: 10.0, achievedAt: Date())
        ScoreStore.shared.saveBestScore(first, themeID: testTheme, pairs: 7)

        let worse = BestScore(moves: 15, timeSeconds: 30.0, achievedAt: Date())
        XCTAssertFalse(ScoreStore.shared.isNewBest(worse, themeID: testTheme, pairs: 7))
    }

    func testGameSnapshotSaveAndLoad() {
        let cards = GameLogic.dealCards(theme: Themes.animals, pairs: 2)
        let snapshot = GameSnapshot(
            themeID: testTheme, pairs: 2, cards: cards,
            moves: 3, elapsedTime: 5.0, savedAt: Date()
        )

        ScoreStore.shared.saveGameSnapshot(snapshot)
        let loaded = ScoreStore.shared.loadGameSnapshot(themeID: testTheme)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.pairs, 2)
        XCTAssertEqual(loaded?.moves, 3)
        XCTAssertEqual(loaded?.cards.count, 4)
    }

    func testClearGameSnapshot() {
        let cards = GameLogic.dealCards(theme: Themes.animals, pairs: 2)
        let snapshot = GameSnapshot(
            themeID: testTheme, pairs: 2, cards: cards,
            moves: 1, elapsedTime: 2.0, savedAt: Date()
        )

        ScoreStore.shared.saveGameSnapshot(snapshot)
        ScoreStore.shared.clearGameSnapshot(themeID: testTheme)

        XCTAssertNil(ScoreStore.shared.loadGameSnapshot(themeID: testTheme))
    }
}
