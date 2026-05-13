import SwiftUI

struct WinView: View {
    let state: GameState
    let theme: Theme
    let gridSize: GridSize

    @Environment(\.dismiss) private var dismiss
    @State private var showStar = false

    private var score: BestScore {
        BestScore(moves: state.moves, timeSeconds: state.elapsedTime, achievedAt: Date())
    }

    private var isNewBest: Bool {
        ScoreStore.shared.isNewBest(score, themeID: theme.id, pairs: gridSize.pairs)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Image(systemName: "hand.tap")
                        .font(.caption)
                    Text("\(state.moves)")
                        .font(.title3.bold().monospacedDigit())
                }

                VStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(formatTime(state.elapsedTime))
                        .font(.title3.bold().monospacedDigit())
                }
            }

            if showStar {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            let newBest = isNewBest
            ScoreStore.shared.saveBestScore(score, themeID: theme.id, pairs: gridSize.pairs)

            if newBest {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showStar = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
