import SwiftUI
import WatchGameKit

struct MemorySimulationView: View {
    @State private var testIndex = 0
    @State private var passCount = 0
    @State private var failCount = 0
    @State private var isDone = false
    @Environment(\.dismiss) private var dismiss

    private var tests: [(Theme, GridSize)] {
        Themes.all.flatMap { theme in
            GridSizes.all.map { size in (theme, size) }
        }
    }

    var body: some View {
        ZStack {
            if !isDone, testIndex < tests.count {
                AutoPlayGameView(
                    theme: tests[testIndex].0,
                    gridSize: tests[testIndex].1
                ) { success in
                    if success { passCount += 1 } else { failCount += 1 }
                    testIndex += 1
                    if testIndex >= tests.count { isDone = true }
                }
                .id(testIndex)
            }

            VStack {
                if testIndex < tests.count {
                    HStack(spacing: 4) {
                        CardSymbolView(symbol: tests[testIndex].0.displayIcon, size: 12)
                        Text("\(tests[testIndex].1.pairs)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .padding(.top, 2)
                }

                Spacer()

                HStack {
                    Text("\(testIndex)/\(tests.count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8))
                            Text("\(passCount)")
                                .font(.system(size: 10, design: .rounded))
                        }
                        .foregroundStyle(.green.opacity(0.7))

                        if failCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8))
                                Text("\(failCount)")
                                    .font(.system(size: 10, design: .rounded))
                            }
                            .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }

            if isDone {
                VStack(spacing: 6) {
                    Image(systemName: failCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(failCount == 0 ? .green : .orange)
                    Text("\(passCount)/\(tests.count)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.7))
                .onTapGesture { dismiss() }
            }
        }
        .watchBackButton()
    }
}

private struct AutoPlayGameView: View {
    let theme: Theme
    let gridSize: GridSize
    let onComplete: (Bool) -> Void

    @StateObject private var state: GameState
    @State private var moveTimer: Timer?
    @State private var stuckCounter = 0

    init(theme: Theme, gridSize: GridSize, onComplete: @escaping (Bool) -> Void) {
        self.theme = theme
        self.gridSize = gridSize
        self.onComplete = onComplete
        self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
    }

    var body: some View {
        GeometryReader { geo in
            let cols = gridSize.cols
            let spacing: CGFloat = 2
            let cardSize = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cardSize), spacing: spacing), count: cols),
                    spacing: spacing
                ) {
                    ForEach(0..<state.cards.count, id: \.self) { index in
                        CardView(card: state.cards[index], cardSize: cardSize)
                    }
                }
            }
        }
        .onChange(of: state.isComplete) { _, complete in
            if complete {
                moveTimer?.invalidate()
                moveTimer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete(true)
                }
            }
        }
        .onAppear {
            moveTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                playNextPair()
            }
        }
        .onDisappear {
            moveTimer?.invalidate()
            moveTimer = nil
        }
    }

    private func playNextPair() {
        guard !state.isComplete else { return }

        let faceUpUnmatched = state.cards.filter { $0.isFaceUp && !$0.isMatched }
        guard faceUpUnmatched.isEmpty else { return }

        guard let (i, j) = findUnmatchedPair() else {
            stuckCounter += 1
            if stuckCounter > 10 {
                moveTimer?.invalidate()
                moveTimer = nil
                onComplete(false)
            }
            return
        }
        stuckCounter = 0

        state.tapCard(at: i)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            state.tapCard(at: j)
        }
    }

    private func findUnmatchedPair() -> (Int, Int)? {
        let cards = state.cards
        for i in 0..<cards.count {
            guard !cards[i].isMatched, !cards[i].isFaceUp else { continue }
            for j in (i + 1)..<cards.count {
                guard !cards[j].isMatched, !cards[j].isFaceUp else { continue }
                if cards[i].symbol == cards[j].symbol {
                    return (i, j)
                }
            }
        }
        return nil
    }
}
