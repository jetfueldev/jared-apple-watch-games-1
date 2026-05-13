import SwiftUI

struct GameView: View {
    let theme: Theme
    let gridSize: GridSize

    @StateObject private var state: GameState

    init(theme: Theme, gridSize: GridSize) {
        self.theme = theme
        self.gridSize = gridSize
        self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let cardWidth = (geo.size.width - spacing * CGFloat(gridSize.cols - 1)) / CGFloat(gridSize.cols)
            let cardHeight = (geo.size.height - 20 - spacing * CGFloat(gridSize.rows - 1)) / CGFloat(gridSize.rows)
            let cardSize = min(cardWidth, cardHeight)

            VStack(spacing: 2) {
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                        Text("\(state.moves)")
                            .font(.caption2.monospacedDigit())
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text(formatTime(state.elapsedTime))
                            .font(.caption2.monospacedDigit())
                    }
                }
                .padding(.horizontal, 4)

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
            }
        }
        .navigationBarBackButtonHidden(state.isComplete)
        .fullScreenCover(isPresented: $state.isComplete) {
            WinView(state: state, theme: theme, gridSize: gridSize)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
