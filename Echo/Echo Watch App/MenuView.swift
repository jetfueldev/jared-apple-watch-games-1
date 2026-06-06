import SwiftUI

struct MenuView: View {
    @AppStorage("echo_currentStage") private var currentStage = 1
    @AppStorage("echo_highestStage") private var highestStage = 1

    private var hasProgress: Bool { currentStage > 1 }
    private var progress: Double {
        Double(max(currentStage - 1, 0)) / Double(StageData.totalStages)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.5))

                Text("\(currentStage)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.08))
                    Capsule()
                        .fill(.blue.opacity(0.4))
                        .frame(width: max(4, progress * 140))
                }
                .frame(width: 140, height: 3)
                .padding(.bottom, 4)

                NavigationLink(destination: GameView(stageNumber: currentStage)) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        if hasProgress {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.15))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if hasProgress {
                    NavigationLink(destination: GameView(stageNumber: 1)) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("1")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
