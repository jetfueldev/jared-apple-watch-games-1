import Foundation
import Combine

class GameState: ObservableObject {
    let theme: Theme
    let gridSize: GridSize

    @Published var cards: [Card]
    @Published var moves: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var isComplete: Bool = false

    private var firstFlippedIndex: Int?
    private var isProcessing: Bool = false
    private var timer: Timer?
    private var startTime: Date?

    init(theme: Theme, gridSize: GridSize) {
        self.theme = theme
        self.gridSize = gridSize
        self.cards = GameLogic.dealCards(theme: theme, pairs: gridSize.pairs)
    }

    func tapCard(at index: Int) {
        guard !isProcessing,
              !cards[index].isFaceUp,
              !cards[index].isMatched else { return }

        cards[index].isFaceUp = true

        if startTime == nil {
            startTimer()
        }

        if let firstIndex = firstFlippedIndex {
            moves += 1
            firstFlippedIndex = nil

            if GameLogic.isMatch(cards[firstIndex], cards[index]) {
                cards[firstIndex].isMatched = true
                cards[index].isMatched = true
                Haptics.playMatch()

                if GameLogic.isComplete(cards) {
                    stopTimer()
                    Haptics.playWin()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                        self?.isComplete = true
                    }
                }
            } else {
                isProcessing = true
                Haptics.playMismatch()

                let first = firstIndex
                let second = index
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.cards[first].isFaceUp = false
                    self?.cards[second].isFaceUp = false
                    self?.isProcessing = false
                }
            }
        } else {
            firstFlippedIndex = index
            Haptics.playFlip()
        }
    }

    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
