import SwiftUI

struct CardView: View {
    let card: Card
    let cardSize: CGFloat

    private var isShowingFront: Bool {
        card.isFaceUp || card.isMatched
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isShowingFront ? .white.opacity(0.08) : .white.opacity(0.12))

            if isShowingFront {
                CardSymbolView(symbol: card.symbol, size: cardSize * 0.55)
                    .transition(.opacity)
            }
        }
        .frame(width: cardSize, height: cardSize)
        .scaleEffect(card.isMatched ? 0.92 : 1.0)
        .opacity(card.isMatched ? 0.25 : 1.0)
        .animation(.easeInOut(duration: 0.45), value: card.isFaceUp)
        .animation(.easeOut(duration: 0.6), value: card.isMatched)
    }
}
