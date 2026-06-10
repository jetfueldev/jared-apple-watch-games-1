import SwiftUI
import WatchGameKit

struct GameView: View {
    let stageNumber: Int
    @StateObject private var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    init(stageNumber: Int) {
        self.stageNumber = stageNumber
        let stage = StageData.stage(stageNumber)
        self._engine = StateObject(wrappedValue: GameEngine(stage: stage))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                sequenceIndicator
                    .padding(.bottom, 4)

                PadGridView(
                    colors: engine.stage.colors,
                    litPad: engine.litPad,
                    isInputEnabled: engine.phase == .input,
                    onTap: { color in engine.padTapped(color) }
                )
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)
            .padding(.bottom, 6)

            if engine.phase == .stageComplete {
                StageCompleteView(stageNumber: stageNumber) {
                    dismiss()
                }
            }

            if engine.phase == .roundSuccess {
                Color.green.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if engine.phase == .roundFail {
                Color.red.opacity(0.2)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .watchBackButton()
        .onAppear {
            engine.startGame()
        }
    }

    private var sequenceIndicator: some View {
        HStack(spacing: 4) {
            let total = engine.sequence.count
            let filled = engine.phase == .input ? engine.inputIndex : 0
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < filled
                        ? Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.8)
                        : .white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 10)
        .animation(.easeInOut(duration: 0.2), value: engine.inputIndex)
    }
}
