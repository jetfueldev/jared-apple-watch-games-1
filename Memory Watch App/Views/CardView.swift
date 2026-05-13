import SwiftUI

struct CardView: View {
    let card: Card
    let cardSize: CGFloat

    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.15))
                CardSymbolView(symbol: card.symbol, size: cardSize * 0.6)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue.opacity(0.6))
            }
        }
        .frame(width: cardSize, height: cardSize)
        .opacity(card.isMatched ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: card.isFaceUp)
        .animation(.easeInOut(duration: 0.3), value: card.isMatched)
    }
}
