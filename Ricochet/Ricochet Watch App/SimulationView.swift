import SwiftUI
import SpriteKit
import WatchGameKit

struct SimulationView: View {
    @State private var scene: GameScene = {
        let s = GameScene(size: CGSize(width: 200, height: 240))
        s.scaleMode = .aspectFill
        s.autoPlayMode = true
        return s
    }()

    @State private var currentLevel = 0
    @State private var passCount = 0
    @State private var failCount = 0
    @State private var isDone = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        scene.jumpToAutoLevel(currentLevel - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(currentLevel > 1 ? 0.6 : 0.15))
                            .frame(width: 36, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 1) {
                        Text("\(currentLevel)/\(LevelGenerator.totalLevels)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
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
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 8))
                                    Text("\(failCount)")
                                        .font(.system(size: 10, design: .rounded))
                                }
                                .foregroundStyle(.orange.opacity(0.7))
                            }
                        }
                    }

                    Spacer()

                    Button {
                        scene.jumpToAutoLevel(currentLevel + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(currentLevel < LevelGenerator.totalLevels ? 0.6 : 0.15))
                            .frame(width: 36, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }

            if isDone {
                VStack(spacing: 6) {
                    Image(systemName: failCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(failCount == 0 ? .green : .orange)
                    Text("\(passCount)/\(LevelGenerator.totalLevels)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.7))
                .onTapGesture { dismiss() }
            }
        }
        .watchBackButton()
        .onReceive(NotificationCenter.default.publisher(for: .ricochetSimulationProgress)) { notif in
            if let info = notif.userInfo {
                currentLevel = info["level"] as? Int ?? currentLevel
                passCount = info["pass"] as? Int ?? passCount
                failCount = info["fail"] as? Int ?? failCount
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .ricochetSimulationComplete)) { _ in
            isDone = true
        }
    }
}
