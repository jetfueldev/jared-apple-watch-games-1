import SwiftUI

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

            if engine.phase == .roundFail {
                VStack {
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(6)
                        .background(Circle().fill(.red.opacity(0.15)))
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .onAppear {
            engine.startGame()
        }
    }

    private var sequenceIndicator: some View {
        HStack(spacing: 3) {
            let total = engine.sequence.count
            let filled = engine.phase == .input ? engine.inputIndex : 0
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < filled ? .white.opacity(0.6) : .white.opacity(0.12))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.2), value: engine.inputIndex)
    }
}
