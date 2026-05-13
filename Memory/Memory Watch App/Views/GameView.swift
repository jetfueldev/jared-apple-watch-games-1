import SwiftUI

struct GameView: View {
    let theme: Theme

    @State private var currentSize: GridSize
    @State private var gameID = UUID()
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme) {
        self.theme = theme
        self._currentSize = State(initialValue: GridSizes.startingSize)
    }

    var body: some View {
        GameBoardView(theme: theme, gridSize: currentSize) {
            if let next = GridSizes.nextSize(after: currentSize) {
                currentSize = next
                gameID = UUID()
            } else {
                dismiss()
            }
        }
        .id(gameID)
    }
}

private struct GameBoardView: View {
    let theme: Theme
    let gridSize: GridSize
    let onWinDismissed: () -> Void

    @StateObject private var state: GameState

    init(theme: Theme, gridSize: GridSize, onWinDismissed: @escaping () -> Void) {
        self.theme = theme
        self.gridSize = gridSize
        self.onWinDismissed = onWinDismissed
        self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 3
            let barHeight: CGFloat = 2
            let cardWidth = (geo.size.width - spacing * CGFloat(gridSize.cols - 1)) / CGFloat(gridSize.cols)
            let cardHeight = (geo.size.height - barHeight - 6 - spacing * CGFloat(gridSize.rows - 1)) / CGFloat(gridSize.rows)
            let cardSize = min(cardWidth, cardHeight)
            let matchedPairs = state.cards.filter { $0.isMatched }.count / 2
            let matchProgress = gridSize.pairs > 0 ? CGFloat(matchedPairs) / CGFloat(gridSize.pairs) : 0

            ZStack(alignment: .leading) {
                VStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.06))
                        Capsule()
                            .fill(.white.opacity(0.25))
                            .frame(width: geo.size.width * matchProgress)
                            .animation(.easeInOut(duration: 0.5), value: matchProgress)
                    }
                    .frame(height: barHeight)

                    Spacer()

                    VStack(spacing: spacing) {
                        ForEach(0..<gridSize.rows, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<gridSize.cols, id: \.self) { col in
                                    let index = row * gridSize.cols + col
                                    if index < state.cards.count {
                                        CardView(card: state.cards[index], cardSize: cardSize)
                                            .onTapGesture {
                                                state.tapCard(at: index)
                                            }
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                }

            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $state.isComplete, onDismiss: onWinDismissed) {
            WinView(state: state, theme: theme, gridSize: gridSize)
        }
    }
}
