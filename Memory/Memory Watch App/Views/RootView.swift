import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            ThemePickerView()
                .navigationDestination(for: ThemeDestination.self) { destination in
                    if let snapshot = ScoreStore.shared.loadGameSnapshot(themeID: destination.theme.id) {
                        ResumeChoiceView(theme: destination.theme, snapshot: snapshot)
                    } else {
                        GameView(theme: destination.theme, startSize: GridSizes.startingSize, snapshot: nil)
                    }
                }
                .navigationDestination(for: ResumeDestination.self) { destination in
                    GameView(theme: destination.theme, startSize: destination.gridSize, snapshot: destination.snapshot)
                }
                .navigationDestination(for: LargeGridDestination.self) { destination in
                    let size = randomLargeSize()
                    let snapshot = partiallyCompletedSnapshot(theme: destination.theme, gridSize: size)
                    GameView(theme: destination.theme, startSize: size, snapshot: snapshot)
                }
        }
    }
}

private func randomLargeSize() -> GridSize {
    let pairs = Int.random(in: 18...32)
    return GridSizes.squareSize(pairs: pairs)
}

private func partiallyCompletedSnapshot(theme: Theme, gridSize: GridSize) -> GameSnapshot {
    var cards = GameLogic.dealCards(theme: theme, pairs: gridSize.pairs)
    let matchPercent = Double.random(in: 0.2...0.6)
    let pairsToMatch = Int(Double(gridSize.pairs) * matchPercent)

    var matched = 0
    var usedSymbols: Set<Int> = []
    for i in 0..<cards.count where matched < pairsToMatch {
        guard !usedSymbols.contains(i), !cards[i].isMatched else { continue }
        for j in (i + 1)..<cards.count {
            if cards[j].symbol == cards[i].symbol && !cards[j].isMatched {
                cards[i].isMatched = true
                cards[j].isMatched = true
                usedSymbols.insert(i)
                usedSymbols.insert(j)
                matched += 1
                break
            }
        }
    }

    let moves = matched * 2 + Int.random(in: 0...matched)
    return GameSnapshot(
        themeID: theme.id,
        pairs: gridSize.pairs,
        cards: cards,
        moves: moves,
        elapsedTime: Double(moves) * 2.5,
        savedAt: Date()
    )
}

struct ResumeDestination: Hashable {
    let theme: Theme
    let gridSize: GridSize
    let snapshot: GameSnapshot?

    static func == (lhs: ResumeDestination, rhs: ResumeDestination) -> Bool {
        lhs.theme == rhs.theme && lhs.gridSize == rhs.gridSize
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(theme)
        hasher.combine(gridSize)
    }
}
