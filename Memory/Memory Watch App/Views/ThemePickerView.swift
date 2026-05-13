import SwiftUI

struct ThemePickerView: View {
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let cellSize = (geo.size.width - spacing - 20) / 2

            LazyVGrid(columns: [
                GridItem(.fixed(cellSize), spacing: spacing),
                GridItem(.fixed(cellSize), spacing: spacing)
            ], spacing: spacing) {
                ForEach(Themes.all) { theme in
                    NavigationLink(value: theme) {
                        CardSymbolView(symbol: theme.displayIcon, size: cellSize * 0.45)
                            .frame(width: cellSize, height: cellSize)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity)
        }
        .navigationDestination(for: Theme.self) { theme in
            GameView(theme: theme)
        }
    }
}
