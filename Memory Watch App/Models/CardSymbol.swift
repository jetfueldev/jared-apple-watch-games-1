import SwiftUI

enum CardSymbol: Hashable {
    case emoji(String)
    case image(String)
}

struct CardSymbolView: View {
    let symbol: CardSymbol
    let size: CGFloat

    var body: some View {
        switch symbol {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size))
        case .image(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
