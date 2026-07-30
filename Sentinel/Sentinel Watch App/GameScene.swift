import SpriteKit
import WatchKit

/// Sentinel — gate-shooter scene.
/// A CLUSTER of shooters at the bottom steers left/right (Digital Crown) and auto-fires up.
/// Enemies descend in the central field — stop them or lose lives. Two side lanes stream
/// LEVEL-UP GATES down continuously: the left lane drops "+shooter" gates (a few hits to
/// break → +1 shooter, a wider wall of fire); the right lane drops ENCASED power-ups (many
/// hits to crack the casing, which visibly clears → +1 gun power = more damage per bolt).
/// Use it or lose it — a gate that reaches the bottom is gone, but another is always coming.
/// One input: steering IS the decision (defend the middle vs. invest in a side lane).
class GameScene: SKScene, SKPhysicsContactDelegate {

    private let bulletCategory: UInt32 = 0x1 << 1
    private let enemyCategory:  UInt32 = 0x1 << 2
    private let floorCategory:  UInt32 = 0x1 << 3
    private let gateCategory:   UInt32 = 0x1 << 4

    private var enemiesRemaining = 0
    private var lives = 3
    private var lifeIndicators: [SKNode] = []

    private var active = false
    private var waveCompleted = false
    private var gameOver = false
    private var needsBuild = true

    var waveNumber = 1

    // Shooter force — carried across waves by the container.
    var initialShooters: Int = 3
    var initialPower: Int = 1
    private let maxShooters = 8
    private let maxPower = 6
    private var shooterCount = 3
    private var gunPower = 1

    var currentShooters: Int { shooterCount }
    var currentPower: Int { gunPower }

    private var cluster: SKNode?

    // Geometry
    private let baseY: CGFloat = 20
    private let shooterSpacing: CGFloat = 6
    private let floorY: CGFloat = 30
    private let fireInterval: Double = 0.35
    private let bulletSpeed: CGFloat = 240
    private let gateSpeed: CGFloat = 15
    private let gateInterval: Double = 3.2
    private var leftLaneX: CGFloat { 15 }
    private var rightLaneX: CGFloat { size.width - 15 }

    override func sceneDidLoad() {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        shooterCount = min(max(initialShooters, 1), maxShooters)
        gunPower = min(max(initialPower, 1), maxPower)

        buildDefenseLine()
        buildFloorSensor()
        buildLaneMarkers()
        buildCluster()
        buildLifeIndicators()
        buildWaveLabel()
    }

    // MARK: - Construction

    private func buildDefenseLine() {
        let line = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 30, y: floorY))
        path.addLine(to: CGPoint(x: size.width - 30, y: floorY))
        line.path = path
        line.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.12)
        line.lineWidth = 1
        addChild(line)
    }

    private func buildFloorSensor() {
        // only the central field breaches for lives; the side lanes are gate lanes
        let floor = SKNode()
        floor.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 30, y: floorY),
                                          to: CGPoint(x: size.width - 30, y: floorY))
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = floorCategory
        floor.physicsBody?.contactTestBitMask = enemyCategory
        floor.physicsBody?.collisionBitMask = 0
        addChild(floor)
    }

    private func buildLaneMarkers() {
        for x in [leftLaneX, rightLaneX] {
            let lane = SKShapeNode(rectOf: CGSize(width: 24, height: size.height), cornerRadius: 0)
            lane.fillColor = SKColor(white: 1.0, alpha: 0.03)
            lane.strokeColor = .clear
            lane.position = CGPoint(x: x, y: size.height / 2)
            lane.zPosition = -1
            addChild(lane)
        }
    }

    private func buildCluster() {
        cluster?.removeFromParent()
        let node = SKNode()
        node.position = CGPoint(x: size.width / 2, y: baseY)
        cluster = node
        addChild(node)
        refreshCluster()
    }

    /// Rebuild the row of shooter marks to match shooterCount.
    private func refreshCluster() {
        guard let cluster else { return }
        cluster.removeAllChildren()
        let n = shooterCount
        let rowW = shooterSpacing * CGFloat(n - 1)
        for i in 0..<n {
            let dot = SKShapeNode(circleOfRadius: 2.4)
            dot.fillColor = SKColor(white: 1.0, alpha: 0.9)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: -rowW / 2 + CGFloat(i) * shooterSpacing, y: 0)
            cluster.addChild(dot)
        }
    }

    private func clusterHalfWidth() -> CGFloat {
        shooterSpacing * CGFloat(shooterCount - 1) / 2
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
            dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 8)
            dot.zPosition = 10
            addChild(dot)
            lifeIndicators.append(dot)
        }
    }

    private func updateLifeIndicators() {
        for (i, dot) in lifeIndicators.enumerated() {
            if i < lives { dot.alpha = 1.0 }
            else { dot.run(SKAction.fadeOut(withDuration: 0.3)) }
        }
    }

    private func buildWaveLabel() {
        let label = SKLabelNode(text: "\(waveNumber)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 12
        label.fontColor = SKColor(white: 1.0, alpha: 0.22)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height - 7)
        label.zPosition = 5
        addChild(label)
    }

    // MARK: - Firing

    private func startVolleys() {
        let volley = SKAction.sequence([
            SKAction.wait(forDuration: fireInterval),
            SKAction.run { [weak self] in self?.fireVolley() }
        ])
        run(SKAction.repeatForever(volley), withKey: "volley")
    }

    private func fireVolley() {
        guard active, let cluster else { return }
        let n = shooterCount
        let rowW = shooterSpacing * CGFloat(n - 1)
        for i in 0..<n {
            let x = cluster.position.x - rowW / 2 + CGFloat(i) * shooterSpacing
            spawnBolt(atX: x, dmg: gunPower)
        }
    }

    private func powerColor(_ power: Int) -> SKColor {
        switch power {
        case 1:  return SKColor(red: 0.5,  green: 0.8,  blue: 1.0, alpha: 0.95)
        case 2:  return SKColor(red: 0.4,  green: 0.9,  blue: 0.9, alpha: 0.95)
        case 3:  return SKColor(red: 0.4,  green: 0.95, blue: 0.5, alpha: 0.95)
        case 4:  return SKColor(red: 1.0,  green: 0.85, blue: 0.3, alpha: 0.95)
        case 5:  return SKColor(red: 1.0,  green: 0.55, blue: 0.3, alpha: 0.95)
        default: return SKColor(red: 1.0,  green: 0.4,  blue: 0.4, alpha: 0.95)
        }
    }

    private func spawnBolt(atX x: CGFloat, dmg: Int) {
        let h: CGFloat = 8 + CGFloat(min(dmg, maxPower) - 1) * 1.6   // stronger = longer bolt
        let bullet = SKShapeNode(rectOf: CGSize(width: 2.5, height: h), cornerRadius: 1.2)
        bullet.fillColor = powerColor(dmg)
        bullet.strokeColor = .clear
        bullet.position = CGPoint(x: x, y: baseY + 6)
        bullet.name = "bullet"
        bullet.userData = ["dmg": dmg]

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 2.5, height: h))
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.categoryBitMask = bulletCategory
        body.contactTestBitMask = enemyCategory | gateCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: bulletSpeed)
        bullet.physicsBody = body
        addChild(bullet)
    }

    // MARK: - Gates

    private func startGates() {
        let spawn = SKAction.sequence([
            SKAction.run { [weak self] in self?.spawnGate(type: "shooters", laneX: self?.leftLaneX ?? 0) },
            SKAction.run { [weak self] in self?.spawnGate(type: "power", laneX: self?.rightLaneX ?? 0) },
            SKAction.wait(forDuration: gateInterval)
        ])
        // stagger the first spawn so gates don't appear instantly at wave start
        run(SKAction.sequence([SKAction.wait(forDuration: 1.2),
                               SKAction.repeatForever(spawn)]), withKey: "gates")
    }

    private func spawnGate(type: String, laneX: CGFloat) {
        guard active else { return }
        let maxHP = (type == "power") ? 8 : 3     // power-ups are encased → more hits to crack
        let node = SKNode()
        node.position = CGPoint(x: laneX, y: size.height + 12)
        node.name = "gate"
        node.userData = ["type": type, "hp": maxHP, "maxHP": maxHP]

        // reveal icon (behind), then the casing on top that clears as it's shot
        if type == "power" {
            let icon = SKLabelNode(text: "⚡")
            icon.fontSize = 13
            icon.verticalAlignmentMode = .center
            icon.horizontalAlignmentMode = .center
            icon.zPosition = 0
            node.addChild(icon)
        } else {
            for k in -1...1 {
                let d = SKShapeNode(circleOfRadius: 1.6)
                d.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.95)
                d.strokeColor = .clear
                d.position = CGPoint(x: CGFloat(k) * 4, y: -2)
                d.zPosition = 0
                node.addChild(d)
            }
            let plus = SKLabelNode(text: "+")
            plus.fontName = "Menlo-Bold"; plus.fontSize = 11
            plus.fontColor = SKColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0)
            plus.verticalAlignmentMode = .center; plus.horizontalAlignmentMode = .center
            plus.position = CGPoint(x: 0, y: 3); plus.zPosition = 0
            node.addChild(plus)
        }

        let casing = SKShapeNode(rectOf: CGSize(width: 22, height: 18), cornerRadius: 3)
        casing.fillColor = SKColor(white: 0.75, alpha: 0.85)      // "concrete/glass"
        casing.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        casing.lineWidth = 0.5
        casing.name = "casing"
        casing.zPosition = 1
        node.addChild(casing)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 22, height: 18))
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.categoryBitMask = gateCategory
        body.contactTestBitMask = bulletCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: -gateSpeed)
        node.physicsBody = body
        addChild(node)
    }

    // MARK: - Controls

    func updateBasePosition(_ crownValue: CGFloat) {
        guard let cluster else { return }
        let half = clusterHalfWidth()
        let minX = half + 2
        let maxX = size.width - half - 2
        let normalized = crownValue / 3.0
        cluster.position.x = max(minX, min(maxX, normalized * size.width))
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        guard active else { return }
        let a = contact.bodyA, b = contact.bodyB
        let masks = a.categoryBitMask | b.categoryBitMask

        if masks == (bulletCategory | enemyCategory) {
            let bullet = a.categoryBitMask == bulletCategory ? a.node : b.node
            let enemy  = a.categoryBitMask == enemyCategory  ? a.node : b.node
            handleBulletEnemy(bullet: bullet, enemy: enemy)
        } else if masks == (bulletCategory | gateCategory) {
            let bullet = a.categoryBitMask == bulletCategory ? a.node : b.node
            let gate   = a.categoryBitMask == gateCategory   ? a.node : b.node
            handleBulletGate(bullet: bullet, gate: gate)
        } else if masks == (enemyCategory | floorCategory) {
            let enemy = a.categoryBitMask == enemyCategory ? a.node : b.node
            handleBreach(enemy: enemy)
        }
    }

    private func handleBulletEnemy(bullet: SKNode?, enemy: SKNode?) {
        guard let enemy, enemy.name == "enemy" else { return }
        let dmg = (bullet?.userData?["dmg"] as? Int) ?? 1
        bullet?.removeFromParent()

        let hp = (enemy.userData?["hp"] as? Int ?? 1) - dmg
        enemy.userData?["hp"] = hp
        if hp > 0 {
            let maxHP = enemy.userData?["maxHP"] as? Int ?? 1
            enemy.run(SKAction.sequence([SKAction.scale(to: 1.18, duration: 0.05),
                                         SKAction.scale(to: 1.0, duration: 0.05)]))
            (enemy.childNode(withName: "glyph") as? SKLabelNode)?.alpha =
                0.45 + 0.55 * CGFloat(max(hp, 0)) / CGFloat(max(1, maxHP))
            if let bar = enemy.childNode(withName: "bossHP") as? SKShapeNode {
                bar.xScale = max(0.001, CGFloat(hp) / CGFloat(max(1, maxHP)))
                bar.position.x = -20 + (40 * CGFloat(hp) / CGFloat(max(1, maxHP))) / 2
            }
            return
        }

        enemy.name = nil
        enemy.physicsBody = nil
        enemy.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.4, duration: 0.12),
                            SKAction.fadeOut(withDuration: 0.12)]),
            SKAction.removeFromParent()
        ]))
        WKInterfaceDevice.current().play(.click)
        enemiesRemaining -= 1
        if enemiesRemaining <= 0 { handleWaveComplete() }
    }

    private func handleBulletGate(bullet: SKNode?, gate: SKNode?) {
        guard let gate, gate.name == "gate" else { return }
        bullet?.removeFromParent()
        let hp = (gate.userData?["hp"] as? Int ?? 1) - 1     // "number of times you shoot it"
        gate.userData?["hp"] = hp
        let maxHP = gate.userData?["maxHP"] as? Int ?? 1

        if hp > 0 {
            // casing visibly clears as it's cracked open
            if let casing = gate.childNode(withName: "casing") as? SKShapeNode {
                casing.fillColor = SKColor(white: 0.75, alpha: 0.85 * CGFloat(hp) / CGFloat(maxHP))
                casing.run(SKAction.sequence([SKAction.scale(to: 1.12, duration: 0.04),
                                              SKAction.scale(to: 1.0, duration: 0.04)]))
            }
            return
        }
        breakGate(gate)
    }

    private func breakGate(_ gate: SKNode) {
        guard let type = gate.userData?["type"] as? String else { return }
        gate.name = nil
        gate.physicsBody = nil

        if type == "power" {
            gunPower = min(gunPower + 1, maxPower)
        } else {
            shooterCount = min(shooterCount + 1, maxShooters)
            refreshCluster()
        }
        WKInterfaceDevice.current().play(.success)
        gate.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.6, duration: 0.15),
                            SKAction.fadeOut(withDuration: 0.15)]),
            SKAction.removeFromParent()
        ]))
    }

    private func handleBreach(enemy: SKNode?) {
        guard let enemy, enemy.name == "enemy" else { return }
        let isBoss = (enemy.userData?["boss"] as? Bool) ?? false
        enemy.name = nil
        enemy.removeFromParent()

        if isBoss {
            lives = 0
            updateLifeIndicators()
            enemiesRemaining -= 1
            handleGameOver()
            return
        }
        lives -= 1
        updateLifeIndicators()
        WKInterfaceDevice.current().play(.failure)
        enemiesRemaining -= 1
        if lives <= 0 { handleGameOver() }
        else if enemiesRemaining <= 0 { handleWaveComplete() }
    }

    // MARK: - Wave lifecycle

    private func startWave() {
        let wave = WaveData.wave(waveNumber)
        enemiesRemaining = 0
        if wave.isBoss {
            spawnBoss(wave)
            enemiesRemaining = 1
        } else {
            let cols = wave.cols, rows = wave.rows
            let margin: CGFloat = 40           // keep enemies inside the two gate lanes
            let usable = size.width - margin * 2
            let spawnFrontY = size.height - 20
            let rowSpacing: CGFloat = 24
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = cols > 1 ? margin + usable * CGFloat(col) / CGFloat(cols - 1) : size.width / 2
                    let y = spawnFrontY + CGFloat(row) * rowSpacing
                    spawnEnemy(at: CGPoint(x: x, y: y), speed: wave.enemySpeed, emoji: wave.emoji, hp: wave.enemyHP)
                    enemiesRemaining += 1
                }
            }
        }
        active = true
        startVolleys()
        startGates()
    }

    private func spawnEnemy(at position: CGPoint, speed: Double, emoji: String, hp: Int) {
        let node = SKNode()
        node.position = position
        node.name = "enemy"
        node.userData = ["hp": hp, "maxHP": hp]
        let label = SKLabelNode(text: emoji)
        label.name = "glyph"; label.fontSize = 16
        label.verticalAlignmentMode = .center; label.horizontalAlignmentMode = .center
        node.addChild(label)
        let body = SKPhysicsBody(circleOfRadius: 8)
        body.isDynamic = true; body.affectedByGravity = false; body.linearDamping = 0
        body.categoryBitMask = enemyCategory
        body.contactTestBitMask = bulletCategory | floorCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: -speed)
        node.physicsBody = body
        addChild(node)
    }

    private func spawnBoss(_ wave: Wave) {
        let node = SKNode()
        node.position = CGPoint(x: size.width / 2, y: size.height - 46)
        node.name = "enemy"
        node.userData = ["hp": wave.enemyHP, "maxHP": wave.enemyHP, "boss": true]
        let label = SKLabelNode(text: wave.emoji)
        label.name = "glyph"; label.fontSize = 40
        label.verticalAlignmentMode = .center; label.horizontalAlignmentMode = .center
        node.addChild(label)
        let barW: CGFloat = 40
        let track = SKShapeNode(rectOf: CGSize(width: barW, height: 3), cornerRadius: 1.5)
        track.fillColor = SKColor(white: 1.0, alpha: 0.12); track.strokeColor = .clear
        track.position = CGPoint(x: 0, y: 26); node.addChild(track)
        let fill = SKShapeNode(rectOf: CGSize(width: barW, height: 3), cornerRadius: 1.5)
        fill.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.9); fill.strokeColor = .clear
        fill.position = CGPoint(x: 0, y: 26); fill.name = "bossHP"; node.addChild(fill)
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = true; body.affectedByGravity = false; body.linearDamping = 0
        body.categoryBitMask = enemyCategory
        body.contactTestBitMask = bulletCategory | floorCategory
        body.collisionBitMask = 0
        body.velocity = CGVector(dx: 0, dy: -wave.enemySpeed)
        node.physicsBody = body
        addChild(node)
    }

    // MARK: - Game flow

    private func stopAction() {
        removeAction(forKey: "volley")
        removeAction(forKey: "gates")
    }

    private func handleWaveComplete() {
        guard !waveCompleted, !gameOver else { return }
        waveCompleted = true
        active = false
        stopAction()
        WKInterfaceDevice.current().play(.success)

        let flash = fullScreenFlash(red: 0.2, green: 0.9, blue: 0.4)
        flash.run(SKAction.customAction(withDuration: 0.6) { node, elapsed in
            (node as? SKShapeNode)?.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.18 * (elapsed / 0.6))
        })
        cluster?.run(SKAction.sequence([SKAction.wait(forDuration: 0.8), SKAction.fadeOut(withDuration: 0.5)]))
        run(SKAction.wait(forDuration: 1.6)) {
            flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
                (node as? SKShapeNode)?.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.18 * (1.0 - elapsed / 0.5))
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
        stopAction()
        WKInterfaceDevice.current().play(.failure)

        let flash = fullScreenFlash(red: 1.0, green: 0.2, blue: 0.2)
        flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
            (node as? SKShapeNode)?.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.20 * (elapsed / 0.5))
        })
        run(SKAction.wait(forDuration: 2.0)) {
            flash.run(SKAction.customAction(withDuration: 0.5) { node, elapsed in
                (node as? SKShapeNode)?.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.20 * (1.0 - elapsed / 0.5))
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
        children.filter { $0.name == "enemy" || $0.name == "bullet" || $0.name == "gate" }
            .forEach { $0.removeFromParent() }
        lives = 3
        gameOver = false
        waveCompleted = false
        buildLifeIndicators()
        shooterCount = min(max(initialShooters, 1), maxShooters)
        gunPower = min(max(initialPower, 1), maxPower)
        cluster?.alpha = 1.0
        refreshCluster()
        startWave()
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if needsBuild { needsBuild = false; startWave() }
        for node in children {
            if node.name == "bullet", node.position.y > size.height + 12 {
                node.removeFromParent()
            } else if node.name == "enemy", node.position.y < -20 {
                node.removeFromParent()
            } else if node.name == "gate", node.position.y < -14 {
                node.removeFromParent()   // missed the gate — use it or lose it
            }
        }
    }
}

extension Notification.Name {
    static let sentinelWaveComplete = Notification.Name("sentinelWaveComplete")
}
