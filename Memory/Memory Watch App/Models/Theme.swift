import Foundation

struct Theme: Identifiable, Hashable {
    let id: String
    let displayIcon: CardSymbol
    let symbols: [CardSymbol]
}
