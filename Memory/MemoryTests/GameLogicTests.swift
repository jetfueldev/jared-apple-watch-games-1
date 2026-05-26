import XCTest
@testable import Memory_Watch_App

final class GameLogicTests: XCTestCase {

    func testDealCardsReturnsCorrectCount() {
        for size in GridSizes.all {
            let cards = GameLogic.dealCards(theme: Themes.animals, pairs: size.pairs)
            XCTAssertEqual(cards.count, size.pairs * 2,
                           "Expected \(size.pairs * 2) cards for \(size.pairs) pairs")
        }
    }

    func testDealCardsContainsExactPairs() {
        let cards = GameLogic.dealCards(theme: Themes.animals, pairs: 6)
        var counts: [CardSymbol: Int] = [:]
        for card in cards {
            counts[card.symbol, default: 0] += 1
        }
        XCTAssertEqual(counts.count, 6, "Should have 6 unique symbols")
        for (symbol, count) in counts {
            XCTAssertEqual(count, 2, "Symbol \(symbol) should appear exactly twice")
        }
    }

    func testDealCardsWorksForAllThemes() {
        for theme in Themes.all {
            let cards = GameLogic.dealCards(theme: theme, pairs: 16)
            XCTAssertEqual(cards.count, 32, "\(theme.id) should deal 32 cards for 16 pairs")
        }
    }

    func testDealCardsHandlesMorePairsThanSymbols() {
        let cards = GameLogic.dealCards(theme: Themes.animals, pairs: 30)
        XCTAssertEqual(cards.count, 60)
    }

    func testIsMatchWithSameSymbol() {
        let symbol = CardSymbol.emoji("🐱")
        let a = Card(id: UUID(), symbol: symbol)
        let b = Card(id: UUID(), symbol: symbol)
        XCTAssertTrue(GameLogic.isMatch(a, b))
    }

    func testIsMatchWithDifferentSymbol() {
        let a = Card(id: UUID(), symbol: .emoji("🐱"))
        let b = Card(id: UUID(), symbol: .emoji("🐶"))
        XCTAssertFalse(GameLogic.isMatch(a, b))
    }

    func testIsMatchRejectsSameCard() {
        let card = Card(id: UUID(), symbol: .emoji("🐱"))
        XCTAssertFalse(GameLogic.isMatch(card, card))
    }

    func testIsCompleteWhenAllMatched() {
        let cards = [
            Card(id: UUID(), symbol: .emoji("🐱"), isMatched: true),
            Card(id: UUID(), symbol: .emoji("🐱"), isMatched: true),
            Card(id: UUID(), symbol: .emoji("🐶"), isMatched: true),
            Card(id: UUID(), symbol: .emoji("🐶"), isMatched: true),
        ]
        XCTAssertTrue(GameLogic.isComplete(cards))
    }

    func testIsCompleteWhenNotAllMatched() {
        let cards = [
            Card(id: UUID(), symbol: .emoji("🐱"), isMatched: true),
            Card(id: UUID(), symbol: .emoji("🐱"), isMatched: true),
            Card(id: UUID(), symbol: .emoji("🐶"), isMatched: false),
            Card(id: UUID(), symbol: .emoji("🐶"), isMatched: false),
        ]
        XCTAssertFalse(GameLogic.isComplete(cards))
    }
}
