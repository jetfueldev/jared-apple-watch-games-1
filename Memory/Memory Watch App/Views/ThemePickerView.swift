import SwiftUI
import WatchGameKit

struct ThemePickerView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                let spacing: CGFloat = 10
                let cellSize: CGFloat = 70

                LazyVGrid(columns: [
                    GridItem(.fixed(cellSize), spacing: spacing),
                    GridItem(.fixed(cellSize), spacing: spacing)
                ], spacing: spacing) {
                    ForEach(Themes.all) { theme in
                        let hasSave = ScoreStore.shared.loadGameSnapshot(themeID: theme.id) != nil

                        NavigationLink(value: ThemeDestination(theme: theme)) {
                            ZStack(alignment: .bottomTrailing) {
                                CardSymbolView(symbol: theme.displayIcon, size: cellSize * 0.45)
                                    .frame(width: cellSize, height: cellSize)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.white.opacity(0.08))
                                    )

                                if hasSave {
                                    Circle()
                                        .fill(.white.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                        .offset(x: -6, y: -6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                let testSize: CGFloat = 44
                LazyVGrid(columns: [
                    GridItem(.fixed(testSize), spacing: 6),
                    GridItem(.fixed(testSize), spacing: 6),
                    GridItem(.fixed(testSize), spacing: 6),
                    GridItem(.fixed(testSize), spacing: 6)
                ], spacing: 6) {
                    ForEach(Themes.all) { theme in
                        NavigationLink(value: LargeGridDestination(theme: theme)) {
                            CardSymbolView(symbol: theme.displayIcon, size: testSize * 0.4)
                                .frame(width: testSize, height: testSize)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink(destination: MemorySimulationView()) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                }
                .watchButton()
            }
            .padding(.horizontal, 10)
        }
    }
}

struct ThemeDestination: Hashable {
    let theme: Theme
}

struct LargeGridDestination: Hashable {
    let theme: Theme
}
