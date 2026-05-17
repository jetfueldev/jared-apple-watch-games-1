import Foundation

struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    let symbol: CardSymbol
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}
