import SwiftUI

struct ThemePickerView: View {
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let cellSize = (geo.size.width - spacing - 16) / 2

            LazyVGrid(columns: [
                GridItem(.fixed(cellSize), spacing: spacing),
                GridItem(.fixed(cellSize), spacing: spacing)
            ], spacing: spacing) {
                ForEach(Themes.all) { theme in
                    NavigationLink(value: theme) {
                        CardSymbolView(symbol: theme.displayIcon, size: cellSize * 0.5)
                            .frame(width: cellSize, height: cellSize)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity)
        }
        .navigationDestination(for: Theme.self) { theme in
            SizePickerView(theme: theme)
        }
    }
}
