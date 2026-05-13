import SwiftUI

struct CardView: View {
    let card: Card
    let cardSize: CGFloat

    private var isShowingFront: Bool {
        card.isFaceUp || card.isMatched
    }

    var body: some View {
        ZStack {
            if isShowingFront {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.15))
                CardSymbolView(symbol: card.symbol, size: cardSize * 0.6)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue.opacity(0.6))
            }
        }
        .frame(width: cardSize, height: cardSize)
        .rotation3DEffect(
            .degrees(isShowingFront ? 0 : 180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .opacity(card.isMatched ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: card.isFaceUp)
        .animation(.easeInOut(duration: 0.3), value: card.isMatched)
    }
}
