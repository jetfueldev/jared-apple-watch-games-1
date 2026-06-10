import SwiftUI
import WatchGameKit

struct GameView: View {
    let theme: Theme
    let startSize: GridSize
    let resumeSnapshot: GameSnapshot?

    @State private var currentSize: GridSize
    @State private var gameID = UUID()
    @State private var activeSnapshot: GameSnapshot?
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, startSize: GridSize? = nil, snapshot: GameSnapshot? = nil) {
        self.theme = theme
        let size = startSize
            ?? ScoreStore.shared.firstUnbeatenSize(themeID: theme.id)
            ?? GridSizes.startingSize
        self.startSize = size
        self.resumeSnapshot = snapshot
        self._currentSize = State(initialValue: size)
        self._activeSnapshot = State(initialValue: snapshot)
    }

    var body: some View {
        GameBoardView(theme: theme, gridSize: currentSize, snapshot: activeSnapshot) {
            if let next = GridSizes.nextSize(after: currentSize) {
                currentSize = next
                activeSnapshot = nil
                gameID = UUID()
            } else {
                ScoreStore.shared.clearGameSnapshot(themeID: theme.id)
                dismiss()
            }
        }
        .id(gameID)
    }
}

private struct GameBoardView: View {
    let theme: Theme
    let gridSize: GridSize
    let snapshot: GameSnapshot?
    let onWinDismissed: () -> Void

    @StateObject private var state: GameState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, gridSize: GridSize, snapshot: GameSnapshot? = nil, onWinDismissed: @escaping () -> Void) {
        self.theme = theme
        self.gridSize = gridSize
        self.snapshot = snapshot
        self.onWinDismissed = onWinDismissed
        if let snapshot {
            self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize, snapshot: snapshot))
        } else {
            self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 3
            let barHeight: CGFloat = 2
            let cols = gridSize.cols
            let cardSize = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)

            let matchedPairs = state.cards.filter { $0.isMatched }.count / 2
            let matchProgress = gridSize.pairs > 0 ? CGFloat(matchedPairs) / CGFloat(gridSize.pairs) : 0

            VStack(spacing: 2) {
                ProgressCapsule(progress: Double(matchProgress), width: geo.size.width, height: barHeight)
                    .animation(.easeInOut(duration: 0.5), value: matchProgress)

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(cardSize), spacing: spacing), count: cols), spacing: spacing) {
                        ForEach(0..<state.cards.count, id: \.self) { index in
                            CardView(card: state.cards[index], cardSize: cardSize)
                                .onTapGesture {
                                    state.tapCard(at: index)
                                }
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .watchBackButton()
        .fullScreenCover(isPresented: $state.isComplete, onDismiss: onWinDismissed) {
            WinView(state: state, theme: theme, gridSize: gridSize)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                if !state.isComplete && !GameLogic.isComplete(state.cards) {
                    ScoreStore.shared.saveGameSnapshot(state.snapshot())
                }
            }
        }
        .onDisappear {
            if !state.isComplete && !GameLogic.isComplete(state.cards) {
                ScoreStore.shared.saveGameSnapshot(state.snapshot())
            }
        }
        .onAppear {
            if GameLogic.isComplete(state.cards) {
                state.isComplete = true
            } else {
                ScoreStore.shared.saveGameSnapshot(state.snapshot())
            }
        }
    }
}
