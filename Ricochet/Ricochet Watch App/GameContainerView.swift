import SwiftUI
import SpriteKit

struct GameContainerView: View {
    let startLevel: Int

    @State private var aimAngle: Double = 0.0
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
        .onTapGesture {
            scene.fire()
        }
        .focusable()
        .digitalCrownRotation(
            $aimAngle,
            from: -8.4,
            through: 8.4,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .digitalCrownAccessory(.hidden)
        .onChange(of: aimAngle) { _, newValue in
            scene.updateAim(angle: newValue / 3.0)
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
        .onReceive(NotificationCenter.default.publisher(for: .ricochetLevelComplete)) { notification in
            if let level = notification.object as? Int {
                ProgressStore.completeLevel(level)
                let next = level + 1
                if next <= LevelGenerator.totalLevels {
                    currentLevel = next
                    aimAngle = 0.0
                    let newScene = GameScene(size: CGSize(width: 200, height: 240))
                    newScene.scaleMode = .aspectFill
                    newScene.levelNumber = next
                    scene = newScene
                    sceneID = UUID()
                } else {
                    dismiss()
                }
            }
        }
    }
}
