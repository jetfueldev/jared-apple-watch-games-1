import SwiftUI

struct GameView: View {
    let theme: Theme
    let initialSize: GridSize

    @State private var currentSize: GridSize
    @State private var gameID = UUID()
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, gridSize: GridSize) {
        self.theme = theme
        self.initialSize = gridSize
        self._currentSize = State(initialValue: gridSize)
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
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, gridSize: GridSize, onWinDismissed: @escaping () -> Void) {
        self.theme = theme
        self.gridSize = gridSize
        self.onWinDismissed = onWinDismissed
        self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let statsHeight: CGFloat = 14
            let cardWidth = (geo.size.width - spacing * CGFloat(gridSize.cols - 1)) / CGFloat(gridSize.cols)
            let cardHeight = (geo.size.height - statsHeight - spacing * CGFloat(gridSize.rows - 1)) / CGFloat(gridSize.rows)
            let cardSize = min(cardWidth, cardHeight)

            VStack(spacing: 1) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .onTapGesture { dismiss() }
                    HStack(spacing: 2) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 8))
                        Text("\(state.moves)")
                            .font(.system(size: 10).monospacedDigit())
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "timer")
                            .font(.system(size: 8))
                        Text(formatTime(state.elapsedTime))
                            .font(.system(size: 10).monospacedDigit())
                    }
                }
                .frame(height: statsHeight)
                .padding(.horizontal, 2)

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
        .ignoresSafeArea(edges: .horizontal)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $state.isComplete, onDismiss: onWinDismissed) {
            WinView(state: state, theme: theme, gridSize: gridSize)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
