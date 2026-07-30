import SpriteKit
import WatchKit

/// Sentinel — M2 scene.
/// A 3-slot PLATOON at the bottom steers left/right (Digital Crown) and auto-fires up.
/// Each slot holds a unit whose TIER is shown word-free by color + pips; higher tier fires
/// faster. Killing enemies fills a blue charge capsule; each fill GROWS the platoon (fill
/// empty slots first, then merge upward). Platoon + charge persist across waves (carried by
/// the container). Enemy crossing the defense line costs a life; clear the wave → advance;
/// lose 3 lives → retry the wave from its starting platoon.
/// Still one-input (steer only). Player-directed merge / side turrets are M3+.
class GameScene: SKScene, SKPhysicsContactDelegate {

    private let bulletCategory: UInt32 = 0x1 << 1
    private let enemyCategory:  UInt32 = 0x1 << 2
    private let floorCategory:  UInt32 = 0x1 << 3

    private var base: SKNode?
    private var enemiesRemaining = 0
    private var lives = 3
    private var lifeIndicators: [SKNode] = []

    private var active = false          // gates auto-fire + contacts during transitions
    private var waveCompleted = false
    private var gameOver = false
    private var needsBuild = true

    var waveNumber = 1

    // Platoon / economy — set by the container to carry progress across waves.
    var initialPlatoon: [Int] = [1]    // starting tiers for this wave (nils padded to slotCount)
    var initialCharge: Int = 0

    private let slotCount = Platoon.slotCount
    private let slotOffsets: [CGFloat] = [-15, 0, 15]
    private var platoon: [Int?] = [nil, nil, nil]   // tier per slot, nil = empty
    private var unitNodes: [SKNode?] = [nil, nil, nil]

    private var charge = 0
    private var chargeNeeded = 3
    private var chargeFill: SKShapeNode?

    /// Exposed so the container can carry state into the next wave's scene.
    var platoonTiers: [Int] { platoon.compactMap { $0 } }
    var currentCharge: Int { charge }

    // Geometry
    private let chargeY: CGFloat = 5
    private let lifeDotsY: CGFloat = 12
    private let baseY: CGFloat = 22
    private let floorY: CGFloat = 33          // defense line — enemy crossing this breaches
    private let baseHalfWidth: CGFloat = 26
    private let bulletSpeed: CGFloat = 220

    override func sceneDidLoad() {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // seed platoon/charge from carried state
        platoon = Platoon.seed(from: initialPlatoon)
        charge = min(initialCharge, chargeNeeded - 1)

        buildDefenseLine()
        buildFloorSensor()
        buildBase()
        buildChargeBar()
        buildLifeIndicators()
        buildWaveLabel()
        refreshUnits()
    }

    // MARK: - Construction

    private func buildDefenseLine() {
        let line = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 4, y: floorY))
        path.addLine(to: CGPoint(x: size.width - 4, y: floorY))
        line.path = path
        line.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.12)
        line.lineWidth = 1
        addChild(line)
    }

    private func buildFloorSensor() {
        let floor = SKNode()
        floor.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: floorY),
                                          to: CGPoint(x: size.width, y: floorY))
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = floorCategory
        floor.physicsBody?.contactTestBitMask = enemyCategory
        floor.physicsBody?.collisionBitMask = 0
        addChild(floor)
    }

    private func buildBase() {
        let width: CGFloat = 52
        let height: CGFloat = 4
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        node.fillColor = SKColor(white: 1.0, alpha: 0.55)
        node.strokeColor = .clear
        node.position = CGPoint(x: size.width / 2, y: baseY)
        node.name = "base"
        base = node
        addChild(node)
    }

    private func buildChargeBar() {
        let w: CGFloat = 100
        let track = SKShapeNode(rectOf: CGSize(width: w, height: 3), cornerRadius: 1.5)
        track.fillColor = SKColor(white: 1.0, alpha: 0.08)
        track.strokeColor = .clear
        track.position = CGPoint(x: size.width / 2, y: chargeY)
        track.zPosition = 8
        addChild(track)

        let fill = SKShapeNode(rectOf: CGSize(width: w, height: 3), cornerRadius: 1.5)
        fill.fillColor = SKColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 0.55)   // collection blue
        fill.strokeColor = .clear
        fill.position = track.position
        fill.zPosition = 9
        chargeFill = fill
        addChild(fill)
        updateChargeBar()
    }

    private func updateChargeBar() {
        guard let fill = chargeFill else { return }
        let w: CGFloat = 100
        let frac = max(0, min(1, CGFloat(charge) / CGFloat(chargeNeeded)))
        fill.xScale = max(0.001, frac)
        // keep left-anchored: shift so it grows from the left edge of the track
        fill.position.x = size.width / 2 - w / 2 + (w * frac) / 2
    }

    private func buildLifeIndicators() {
        lifeIndicators.forEach { $0.removeFromParent() }
        lifeIndicators.removeAll()

        let spacing: CGFloat = 10
        let totalWidth = spacing * CGFloat(3 - 1)
        let startX = (size.width - totalWidth) / 2

        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: 2.5)
            dot.fillColor = SKColor(white: 1.0, alpha: 0.6)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: lifeDotsY)
            dot.zPosition = 10
            addChild(dot)
            lifeIndicators.append(dot)
        }
    }

    private func updateLifeIndicators() {
        for (i, dot) in lifeIndicators.enumerated() {
            if i < lives {
                dot.alpha = 1.0
            } else {
                dot.run(SKAction.fadeOut(withDuration: 0.3))
            }
        }
    }

    private func buildWaveLabel() {
        let label = SKLabelNode(text: "\(waveNumber)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 13
        label.fontColor = SKColor(white: 1.0, alpha: 0.22)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height - 12)
        label.zPosition = 5
        addChild(label)
    }

    // MARK: - Platoon / units

    private func tierColor(_ tier: Int) -> SKColor {
        switch tier {
        case 1:  return SKColor(red: 0.5,  green: 0.8,  blue: 1.0, alpha: 0.95)  // blue
        case 2:  return SKColor(red: 0.3,  green: 0.9,  blue: 0.5, alpha: 0.95)  // green
        case 3:  return SKColor(red: 1.0,  green: 0.8,  blue: 0.3, alpha: 0.95)  // yellow
        case 4:  return SKColor(red: 1.0,  green: 0.55, blue: 0.3, alpha: 0.95)  // orange
        default: return SKColor(red: 0.75, green: 0.5,  blue: 1.0, alpha: 0.95)  // purple (5+)
        }
    }

    /// Higher tier fires faster.
    private func fireInterval(_ tier: Int) -> Double {
        max(0.18, 0.5 - Double(tier - 1) * 0.07)
    }

    private func makeUnitNode(tier: Int) -> SKNode {
        let container = SKNode()
        let color = tierColor(tier)

        let body = SKShapeNode(rectOf: CGSize(width: 12, height: 8), cornerRadius: 2)
        body.fillColor = color
        body.strokeColor = .clear
        body.position = .zero
        container.addChild(body)

        // pips: redundant word-free tier signal (color + count)
        let pipCount = min(tier, 5)
        let spacing: CGFloat = 2.6
        let rowW = spacing * CGFloat(pipCount - 1)
        for p in 0..<pipCount {
            let pip = SKShapeNode(circleOfRadius: 0.9)
            pip.fillColor = SKColor(white: 1.0, alpha: 0.9)
            pip.strokeColor = .clear
            pip.position = CGPoint(x: -rowW / 2 + CGFloat(p) * spacing, y: 0)
            container.addChild(pip)
        }
        return container
    }

    private func refreshUnits() {
        guard let base else { return }
        for (i, node) in unitNodes.enumerated() {
            node?.removeFromParent()
            unitNodes[i] = nil
        }
        for (i, tier) in platoon.enumerated() {
            guard let tier else { continue }
            let node = makeUnitNode(tier: tier)
            node.position = CGPoint(x: slotOffsets[i], y: 4)
            base.addChild(node)
            unitNodes[i] = node
            startFiring(node: node, offset: slotOffsets[i], tier: tier)
        }
    }

    private func startFiring(node: SKNode, offset: CGFloat, tier: Int) {
        let color = tierColor(tier)
        let fire = SKAction.sequence([
            SKAction.wait(forDuration: fireInterval(tier)),
            SKAction.run { [weak self] in
                guard let self, let base = self.base else { return }
                self.fireBullet(atX: base.position.x + offset, color: color)
            }
        ])
        node.run(SKAction.repeatForever(fire), withKey: "fire")
    }

    private func fireBullet(atX x: CGFloat, color: SKColor) {
        guard active else { return }
        let bullet = SKShapeNode(rectOf: CGSize(width: 2.5, height: 9), cornerRadius: 1.2)
        bullet.fillColor = color
        bullet.strokeColor = .clear
        bullet.position = CGPoint(x: x, y: baseY + 8)
        bullet.name = "bullet"

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 2.5, height: 9))
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.categoryBitMask = bulletCategory
        body.contactTestBitMask = enemyCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: bulletSpeed)
        bullet.physicsBody = body

        addChild(bullet)
    }

    /// Economy step: one charge-fill grows the platoon by one increment.
    /// Fill empty slots first; once full, merge a T1 up, else bump the lowest slot up.
    private func growPlatoon() {
        platoon = Platoon.grow(platoon)
        refreshUnits()
        WKInterfaceDevice.current().play(.success)

        // brief pulse on the newest/strongest slot for feedback
        if let node = unitNodes.compactMap({ $0 }).last {
            node.run(SKAction.sequence([
                SKAction.scale(to: 1.35, duration: 0.12),
                SKAction.scale(to: 1.0, duration: 0.12)
            ]))
        }
    }

    // MARK: - Wave lifecycle

    private func startWave() {
        let wave = WaveData.wave(waveNumber)
        let cols = wave.cols
        let rows = wave.rows

        let margin: CGFloat = 22
        let usable = size.width - margin * 2
        let spawnFrontY = size.height - 20
        let rowSpacing: CGFloat = 24

        enemiesRemaining = 0
        for row in 0..<rows {
            for col in 0..<cols {
                let x: CGFloat
                if cols > 1 {
                    x = margin + usable * CGFloat(col) / CGFloat(cols - 1)
                } else {
                    x = size.width / 2
                }
                let y = spawnFrontY + CGFloat(row) * rowSpacing
                spawnEnemy(at: CGPoint(x: x, y: y), speed: wave.enemySpeed, emoji: wave.emoji)
                enemiesRemaining += 1
            }
        }

        active = true
        refreshUnits()   // (re)start each unit's fire loop
    }

    private func spawnEnemy(at position: CGPoint, speed: Double, emoji: String) {
        let node = SKNode()
        node.position = position
        node.name = "enemy"

        let label = SKLabelNode(text: emoji)
        label.fontSize = 16
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        node.addChild(label)

        let body = SKPhysicsBody(circleOfRadius: 8)
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.categoryBitMask = enemyCategory
        body.contactTestBitMask = bulletCategory | floorCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: -speed)
        node.physicsBody = body

        addChild(node)
    }

    // MARK: - Controls

    func updateBasePosition(_ crownValue: CGFloat) {
        guard let base else { return }
        let minX = baseHalfWidth + 2
        let maxX = size.width - baseHalfWidth - 2
        let normalized = crownValue / 3.0
        base.position.x = max(minX, min(maxX, normalized * size.width))
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        guard active else { return }

        let a = contact.bodyA
        let b = contact.bodyB
        let masks = a.categoryBitMask | b.categoryBitMask

        if masks == (bulletCategory | enemyCategory) {
            let bulletNode = a.categoryBitMask == bulletCategory ? a.node : b.node
            let enemyNode  = a.categoryBitMask == enemyCategory  ? a.node : b.node
            handleBulletHit(bullet: bulletNode, enemy: enemyNode)
        } else if masks == (enemyCategory | floorCategory) {
            let enemyNode = a.categoryBitMask == enemyCategory ? a.node : b.node
            handleBreach(enemy: enemyNode)
        }
    }

    private func handleBulletHit(bullet: SKNode?, enemy: SKNode?) {
        guard let enemy, enemy.name == "enemy" else { return }
        enemy.name = nil
        bullet?.removeFromParent()

        enemy.physicsBody = nil
        enemy.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.removeFromParent()
        ]))

        WKInterfaceDevice.current().play(.click)

        // economy: a kill charges the meter; a full meter grows the platoon
        charge += 1
        if charge >= chargeNeeded {
            charge = 0
            growPlatoon()
        }
        updateChargeBar()

        enemiesRemaining -= 1
        if enemiesRemaining <= 0 { handleWaveComplete() }
    }

    private func handleBreach(enemy: SKNode?) {
        guard let enemy, enemy.name == "enemy" else { return }
        enemy.name = nil
        enemy.removeFromParent()

        lives -= 1
        updateLifeIndicators()
        WKInterfaceDevice.current().play(.failure)

        enemiesRemaining -= 1

        if lives <= 0 {
            handleGameOver()
        } else if enemiesRemaining <= 0 {
            handleWaveComplete()
        }
    }

    // MARK: - Game flow

    private func handleWaveComplete() {
        guard !waveCompleted, !gameOver else { return }
        waveCompleted = true
        active = false
        unitNodes.forEach { $0?.removeAction(forKey: "fire") }

        WKInterfaceDevice.current().play(.success)

        let flash = fullScreenFlash(red: 0.2, green: 0.9, blue: 0.4)
        flash.run(SKAction.customAction(withDuration: 0.6) { node, elapsed in
            let t = elapsed / 0.6
            (node as? SKShapeNode)?.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.18 * t)
        })

        base?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.5)
        ]))

        run(SKAction.wait(forDuration: 1.6)) {
            flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
                let t = elapsed / 0.5
                (node as? SKShapeNode)?.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.18 * (1.0 - t))
            })
        }

        run(SKAction.wait(forDuration: 2.5)) { [weak self] in
            guard let self else { return }
            flash.removeFromParent()
            NotificationCenter.default.post(name: .sentinelWaveComplete, object: self.waveNumber)
        }
    }

    private func handleGameOver() {
        guard !gameOver, !waveCompleted else { return }
        gameOver = true
        active = false
        unitNodes.forEach { $0?.removeAction(forKey: "fire") }

        WKInterfaceDevice.current().play(.failure)

        let flash = fullScreenFlash(red: 1.0, green: 0.2, blue: 0.2)
        flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
            let t = elapsed / 0.5
            (node as? SKShapeNode)?.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.20 * t)
        })

        run(SKAction.wait(forDuration: 2.0)) {
            flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
                let t = elapsed / 0.5
                (node as? SKShapeNode)?.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.20 * (1.0 - t))
            })
        }

        run(SKAction.wait(forDuration: 3.0)) { [weak self] in
            guard let self else { return }
            flash.removeFromParent()
            self.retryWave()
        }
    }

    private func fullScreenFlash(red: CGFloat, green: CGFloat, blue: CGFloat) -> SKShapeNode {
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor = SKColor(red: red, green: green, blue: blue, alpha: 0.0)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 100
        addChild(flash)
        return flash
    }

    private func retryWave() {
        children.filter { $0.name == "enemy" || $0.name == "bullet" }
            .forEach { $0.removeFromParent() }

        lives = 3
        gameOver = false
        waveCompleted = false
        buildLifeIndicators()

        // restore the platoon + charge this wave began with
        platoon = Platoon.seed(from: initialPlatoon)
        charge = min(initialCharge, chargeNeeded - 1)
        updateChargeBar()

        base?.alpha = 1.0
        startWave()
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if needsBuild {
            needsBuild = false
            startWave()
        }

        for node in children {
            if node.name == "bullet", node.position.y > size.height + 12 {
                node.removeFromParent()
            } else if node.name == "enemy", node.position.y < -20 {
                node.removeFromParent()
            }
        }
    }
}

extension Notification.Name {
    static let sentinelWaveComplete = Notification.Name("sentinelWaveComplete")
}
