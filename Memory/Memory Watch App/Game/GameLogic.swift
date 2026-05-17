import Foundation

enum GameLogic {
    static func dealCards(theme: Theme, pairs: Int) -> [Card] {
        var pool: [CardSymbol]
        if pairs <= theme.symbols.count {
            pool = Array(theme.symbols.shuffled().prefix(pairs))
        } else {
            let allSymbols = Themes.all.flatMap { $0.symbols }
            let unique = Array(Set(allSymbols)).shuffled()
            pool = Array(unique.prefix(pairs))
            while pool.count < pairs {
                pool.append(pool[pool.count % unique.count])
            }
        }

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
