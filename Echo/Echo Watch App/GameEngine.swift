import Foundation
import Combine

enum GamePhase: Equatable {
    case idle
    case playback
    case input
    case roundSuccess
    case roundFail
    case stageComplete
}

class GameEngine: ObservableObject {
    @Published var phase: GamePhase = .idle
    @Published var sequence: [PadColor] = []
    @Published var inputIndex: Int = 0
    @Published var litPad: PadColor? = nil
    @Published var currentRound: Int = 0
    @Published private(set) var stage: Stage

    private var playbackIndex = 0
    private var playbackTimer: Timer?
    private var isShowingPad = false

    init(stage: Stage) {
        self.stage = stage
    }

    func startGame() {
        currentRound = 0
        generateSequence()
        startPlayback()
    }

    func restartStage() {
        currentRound = 0
        generateSequence()
        startPlayback()
    }

    func padTapped(_ color: PadColor) {
        guard phase == .input else { return }

        let expected = sequence[inputIndex]

        litPad = color
        Haptics.playPad(color)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            if self.litPad == color { self.litPad = nil }
        }

        if color == expected {
            inputIndex += 1
            if inputIndex >= sequence.count {
                handleRoundSuccess()
            }
        } else {
            handleRoundFail(correctColor: expected)
        }
    }

    // MARK: - Sequence

    private func generateSequence() {
        sequence = (0..<stage.startLength).map { _ in
            stage.colors.randomElement()!
        }
    }

    private func extendSequence() {
        sequence.append(stage.colors.randomElement()!)
    }

    // MARK: - Playback

    private func startPlayback() {
        phase = .playback
        playbackIndex = 0
        isShowingPad = false
        litPad = nil
        inputIndex = 0

        let litDuration: TimeInterval = 0.55
        let gapDuration: TimeInterval = 0.3
        let stepInterval = litDuration + gapDuration

        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }

            if self.playbackIndex >= self.sequence.count {
                timer.invalidate()
                self.playbackTimer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.phase = .input
                }
                return
            }

            let color = self.sequence[self.playbackIndex]
            self.litPad = color
            Haptics.playPad(color)

            DispatchQueue.main.asyncAfter(deadline: .now() + litDuration) {
                if self.litPad == color {
                    self.litPad = nil
                }
            }

            self.playbackIndex += 1
        }
    }

    // MARK: - Round Resolution

    private func handleRoundSuccess() {
        let sequenceLength = sequence.count
        let isLastRound = sequenceLength >= stage.endLength

        if isLastRound {
            phase = .stageComplete
            Haptics.playStageComplete()
            ProgressStore.completeStage(stage.number)
        } else {
            phase = .roundSuccess
            Haptics.playSuccess()
            currentRound += 1
            extendSequence()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startPlayback()
            }
        }
    }

    private func handleRoundFail(correctColor: PadColor) {
        phase = .roundFail
        Haptics.playFailure()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.litPad = correctColor
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.litPad = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.restartStage()
            }
        }
    }

    deinit {
        playbackTimer?.invalidate()
    }
}
