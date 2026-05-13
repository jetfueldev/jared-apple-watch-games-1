import Foundation

enum GameLogic {
    static func dealCards(theme: Theme, pairs: Int) -> [Card] {
        let pool = theme.symbols.shuffled().prefix(pairs)
        let cards = pool.flatMap { symbol in
            [Card(id: UUID(), symbol: symbol),
             Card(id: UUID(), symbol: symbol)]
        }
        return cards.shuffled()
    }

    static func isMatch(_ first: Card, _ second: Card) -> Bool {
        first.symbol == second.symbol && first.id != second.id
    }

    static func isComplete(_ cards: [Card]) -> Bool {
        cards.allSatisfy { $0.isMatched }
    }
}
