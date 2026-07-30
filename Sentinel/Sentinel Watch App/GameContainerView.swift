import SwiftUI
import SpriteKit
import WatchGameKit

struct GameContainerView: View {
    let startWave: Int

    @State private var baseX: Double = 1.5      // Crown value, range 0...3 (mirrors Shatter)
    @State private var currentWave: Int
    @State private var sceneID = UUID()
    @Environment(\.dismiss) private var dismiss

    @State private var scene: GameScene

    init(startWave: Int) {
        self.startWave = startWave
        self._currentWave = State(initialValue: startWave)
        let s = GameScene(size: CGSize(width: 200, height: 240))
        s.scaleMode = .aspectFill
        s.waveNumber = startWave
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
            $baseX,
            from: 0.0,
            through: 3.0,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: false
        )
        .digitalCrownAccessory(.hidden)
        .scrollIndicators(.hidden)
        .onChange(of: baseX) { _, newValue in
            scene.updateBasePosition(newValue)
        }
        .watchBackButton()
        .onReceive(NotificationCenter.default.publisher(for: .sentinelWaveComplete)) { notification in
            if let wave = notification.object as? Int {
                ProgressStore.completeWave(wave)
                let next = wave + 1
                if next <= WaveData.totalWaves {
                    currentWave = next
                    // carry platoon + charge + turrets forward so progress persists across waves
                    let carriedPlatoon = scene.platoonTiers
                    let carriedCharge = scene.currentCharge
                    let carriedTurrets = scene.turretTiers
                    let newScene = GameScene(size: CGSize(width: 200, height: 240))
                    newScene.scaleMode = .aspectFill
                    newScene.waveNumber = next
                    newScene.initialPlatoon = carriedPlatoon.isEmpty ? [1] : carriedPlatoon
                    newScene.initialCharge = carriedCharge
                    newScene.initialTurrets = carriedTurrets
                    newScene.updateBasePosition(baseX)
                    scene = newScene
                    sceneID = UUID()
                } else {
                    dismiss()
                }
            }
        }
    }
}
