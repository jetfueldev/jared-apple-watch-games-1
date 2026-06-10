import SwiftUI
import SpriteKit
import WatchGameKit

struct GameContainerView: View {
    let startLevel: Int

    @State private var paddleX: Double = 0.5
    @State private var currentLevel: Int
    @State private var sceneID = UUID()
    @Environment(\.dismiss) private var dismiss

    @State private var scene: GameScene

    init(startLevel: Int) {
        self.startLevel = startLevel
        self._currentLevel = State(initialValue: startLevel)
        let s = GameScene(size: CGSize(width: 200, height: 240))
        s.scaleMode = .aspectFill
        s.levelNumber = startLevel
        self._scene = State(initialValue: s)
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .id(sceneID)
        .focusable()
        .digitalCrownRotation(
            $paddleX,
            from: 0.0,
            through: 3.0,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: false
        )
        .digitalCrownAccessory(.hidden)
        .scrollIndicators(.hidden)
        .onChange(of: paddleX) { _, newValue in
            scene.updatePaddlePosition(newValue)
        }
        .watchBackButton()
        .onReceive(NotificationCenter.default.publisher(for: .shatterLevelComplete)) { notification in
            if let level = notification.object as? Int {
                ProgressStore.completeLevel(level)
                let next = level + 1
                if next <= LevelData.totalLevels {
                    currentLevel = next
                    let newScene = GameScene(size: CGSize(width: 200, height: 240))
                    newScene.scaleMode = .aspectFill
                    newScene.levelNumber = next
                    newScene.updatePaddlePosition(paddleX)
                    scene = newScene
                    sceneID = UUID()
                } else {
                    dismiss()
                }
            }
        }
    }
}
