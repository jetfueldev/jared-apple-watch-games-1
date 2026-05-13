import SwiftUI

struct WinView: View {
    let state: GameState
    let theme: Theme
    let gridSize: GridSize

    @Environment(\.dismiss) private var dismiss
    @State private var showStar = false
    @State private var appeared = false

    private var score: BestScore {
        BestScore(moves: state.moves, timeSeconds: state.elapsedTime, achievedAt: Date())
    }

    private var isNewBest: Bool {
        ScoreStore.shared.isNewBest(score, themeID: theme.id, pairs: gridSize.pairs)
    }

    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.5))
                )
                .scaleEffect(appeared ? 1.0 : 0.8)
                .opacity(appeared ? 1.0 : 0.0)

            HStack(spacing: 24) {
                Text("\(state.moves)")
                    .font(.system(size: 16, weight: .ultraLight).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.15))

                Text(formatTime(state.elapsedTime))
                    .font(.system(size: 16, weight: .ultraLight).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.10))
            }
            .opacity(appeared ? 1.0 : 0.0)

            if showStar {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow.opacity(0.5))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }

            let newBest = isNewBest
            ScoreStore.shared.saveBestScore(score, themeID: theme.id, pairs: gridSize.pairs)

            if newBest {
                withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                    showStar = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
