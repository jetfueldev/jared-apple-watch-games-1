import SpriteKit
import WatchKit

/// Sentinel — M1 scene.
/// A base at the bottom steers left/right (Digital Crown) and auto-fires straight up.
/// Enemies descend in a formation; a bullet destroys one; an enemy crossing the defense
/// line costs a life. Clear the wave → advance. Lose 3 lives → retry the wave.
/// No merge / turrets / economy yet (M2+). Mirrors Shatter's structure + timing rules.
class GameScene: SKScene, SKPhysicsContactDelegate {

    private let baseCategory:   UInt32 = 0x1 << 0
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

    // Geometry
    private let floorY: CGFloat = 22        // defense line — enemy crossing this breaches
    private let baseY: CGFloat = 12
    private let baseHalfWidth: CGFloat = 21
    private let bulletSpeed: CGFloat = 220

    override func sceneDidLoad() {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        buildDefenseLine()
        buildFloorSensor()
        buildBase()
        buildLifeIndicators()
        buildWaveLabel()
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
        let width: CGFloat = 42
        let height: CGFloat = 8
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 3)
        node.fillColor = SKColor(white: 1.0, alpha: 0.75)
        node.strokeColor = .clear
        node.position = CGPoint(x: size.width / 2, y: baseY)
        node.name = "base"

        // faint muzzle nub so the firing direction reads
        let muzzle = SKShapeNode(rectOf: CGSize(width: 4, height: 4), cornerRadius: 1)
        muzzle.fillColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.9)
        muzzle.strokeColor = .clear
        muzzle.position = CGPoint(x: 0, y: height / 2 + 1)
        node.addChild(muzzle)

        base = node
        addChild(node)
    }

    private func buildLifeIndicators() {
        lifeIndicators.forEach { $0.removeFromParent() }
        lifeIndicators.removeAll()

        let spacing: CGFloat = 10
        let totalWidth = spacing * CGFloat(3 - 1)
        let startX = (size.width - totalWidth) / 2

        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = SKColor(white: 1.0, alpha: 0.6)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 8)
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

    // MARK: - Wave lifecycle

    private func startWave() {
        let wave = WaveData.wave(waveNumber)
        let cols = wave.cols
        let rows = wave.rows

        let margin: CGFloat = 22
        let usable = size.width - margin * 2
        let spawnFrontY = size.height - 20     // front row just below the top
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
                // higher rows spawn above the top edge so the formation streams in
                let y = spawnFrontY + CGFloat(row) * rowSpacing
                spawnEnemy(at: CGPoint(x: x, y: y), speed: wave.enemySpeed, emoji: wave.emoji)
                enemiesRemaining += 1
            }
        }

        active = true
        startFiring(interval: wave.fireInterval)
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

    private func startFiring(interval: Double) {
        guard let base else { return }
        let fire = SKAction.sequence([
            SKAction.wait(forDuration: interval),
            SKAction.run { [weak self] in self?.fireBullet() }
        ])
        base.run(SKAction.repeatForever(fire), withKey: "fire")
    }

    private func fireBullet() {
        guard active, let base else { return }
        let bullet = SKShapeNode(rectOf: CGSize(width: 2.5, height: 9), cornerRadius: 1.2)
        bullet.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.95)
        bullet.strokeColor = .clear
        bullet.position = CGPoint(x: base.position.x, y: base.position.y + 8)
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

        // small pop
        enemy.physicsBody = nil
        enemy.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.removeFromParent()
        ]))

        WKInterfaceDevice.current().play(.click)
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
        base?.removeAction(forKey: "fire")

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
        base?.removeAction(forKey: "fire")

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

        base?.alpha = 1.0
        startWave()
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if needsBuild {
            needsBuild = false
            startWave()
        }

        // cull bullets that leave the top; safety-cull enemies that slip past
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
