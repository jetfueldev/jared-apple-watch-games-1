import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    struct Category {
        static let wall: UInt32 = 1
        static let shot: UInt32 = 2
        static let target: UInt32 = 4
        static let void_zone: UInt32 = 8
        static let obstacle: UInt32 = 16
        static let absorb: UInt32 = 32
    }

    private let alienNames = [
        "Aliens/alien_classic",
        "Aliens/alien_cyclops",
        "Aliens/alien_tentacle",
        "Aliens/alien_robot",
        "Aliens/alien_horned",
        "Aliens/alien_ufo"
    ]

    var levelNumber = 1
    var autoPlayMode = false

    private var shipNode: SKNode!
    private var aimNode: SKShapeNode!
    private var targetNode: SKNode!
    private var shotNode: SKShapeNode?

    private var obstacleNodes: [SKNode] = []

    private var aimAngle: CGFloat = 0
    private var canFire = true

    private var countdownArc: SKShapeNode!
    private let countdownTotal: TimeInterval = 12
    private var countdownRemaining: TimeInterval = 12
    private var lastUpdateTime: TimeInterval = 0

    private let baseShotSpeed: CGFloat = 250
    private let shotRadius: CGFloat = 3

    private var levelLabel: SKLabelNode!

    private var autoPlayCurrentLevel = 1
    private var autoPlayPassCount = 0
    private var autoPlayFailCount = 0
    private var autoPlayStarted = false

    private var shotSpeed: CGFloat {
        autoPlayMode ? 400 : baseShotSpeed
    }

    override func sceneDidLoad() {
        backgroundColor = .black

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupBoundaryWalls()
        setupVoidZone()
        setupShip()
        setupLevelLabel()
        setupAim()
        setupCountdownArc()

        loadLevel(levelNumber)
    }

    // MARK: - Auto-play simulation

    private let autoPlayShotSpeed: CGFloat = 500

    private func playNextAutoLevel() {
        guard autoPlayCurrentLevel <= LevelGenerator.totalLevels else {
            NotificationCenter.default.post(name: .ricochetSimulationComplete, object: nil)
            return
        }

        let level = LevelGenerator.generate(number: autoPlayCurrentLevel)
        let result = LevelSimulator.simulate(level: level)

        levelNumber = autoPlayCurrentLevel
        loadLevel(autoPlayCurrentLevel)

        let info: [String: Any] = [
            "level": autoPlayCurrentLevel,
            "pass": autoPlayPassCount,
            "fail": autoPlayFailCount
        ]
        NotificationCenter.default.post(name: .ricochetSimulationProgress, object: nil, userInfo: info)

        if result.solvable, result.path.count >= 2 {
            aimNode.isHidden = false
            countdownArc.isHidden = true

            let angle = result.solutionAngle ?? 0
            let path = result.path

            run(.sequence([
                .wait(forDuration: 0.15),
                .run { [weak self] in self?.animateAimTo(angle: Double(angle), duration: 0.2) },
                .wait(forDuration: 0.25),
                .run { [weak self] in self?.playPath(path) }
            ]))
        } else {
            aimNode.isHidden = true
            countdownArc.isHidden = true
            autoPlayFailCount += 1
            showUnsolvableIndicator()

            run(.sequence([
                .wait(forDuration: 0.8),
                .run { [weak self] in
                    guard let self else { return }
                    let failInfo: [String: Any] = [
                        "level": self.autoPlayCurrentLevel,
                        "hit": false,
                        "pass": self.autoPlayPassCount,
                        "fail": self.autoPlayFailCount
                    ]
                    NotificationCenter.default.post(name: .ricochetSimulationProgress, object: nil, userInfo: failInfo)
                    self.autoPlayCurrentLevel += 1
                    self.playNextAutoLevel()
                }
            ]))
        }
    }

    private func showUnsolvableIndicator() {
        let sz: CGFloat = 16
        let xPath = CGMutablePath()
        xPath.move(to: CGPoint(x: -sz / 2, y: -sz / 2))
        xPath.addLine(to: CGPoint(x: sz / 2, y: sz / 2))
        xPath.move(to: CGPoint(x: sz / 2, y: -sz / 2))
        xPath.addLine(to: CGPoint(x: -sz / 2, y: sz / 2))

        let xMark = SKShapeNode(path: xPath)
        xMark.strokeColor = SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.9)
        xMark.lineWidth = 3
        xMark.glowWidth = 2
        xMark.position = targetNode.position
        xMark.zPosition = 10
        xMark.setScale(0.3)
        addChild(xMark)

        xMark.run(.sequence([
            .scale(to: 1.0, duration: 0.2),
            .wait(forDuration: 0.4),
            .group([
                .fadeOut(withDuration: 0.15),
                .scale(to: 0.5, duration: 0.15)
            ]),
            .removeFromParent()
        ]))
    }

    private func animateAimTo(angle: Double, duration: TimeInterval) {
        let startAngle = aimAngle
        let endAngle = CGFloat(angle)
        let steps = max(1, Int(duration * 60))
        let stepDuration = duration / Double(steps)

        var actions: [SKAction] = []
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = startAngle + (endAngle - startAngle) * t
            actions.append(.run { [weak self] in
                self?.updateAim(angle: Double(a))
            })
            if i < steps {
                actions.append(.wait(forDuration: stepDuration))
            }
        }
        run(.sequence(actions))
    }

    private func playPath(_ path: [CGPoint]) {
        guard path.count >= 2 else {
            advanceAutoPlay(hit: false)
            return
        }

        let shot = SKShapeNode(circleOfRadius: shotRadius)
        shot.fillColor = SKColor(red: 0.3, green: 1.0, blue: 0.4, alpha: 1)
        shot.strokeColor = .clear
        shot.glowWidth = 2
        shot.position = path[0]
        shot.zPosition = 5
        addChild(shot)
        shotNode = shot

        aimNode.isHidden = true

        var actions: [SKAction] = []
        for i in 1..<path.count {
            let from = path[i - 1]
            let to = path[i]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let duration = TimeInterval(dist / autoPlayShotSpeed)
            actions.append(.move(to: to, duration: duration))
            if i < path.count - 1 {
                actions.append(.run { [weak self] in
                    self?.bounceSparkle(at: to)
                })
            }
        }
        actions.append(.run { [weak self] in
            self?.handleAutoPlayHit()
        })

        shot.run(.sequence(actions))
    }

    private func bounceSparkle(at point: CGPoint) {
        let sparkle = SKShapeNode(circleOfRadius: 4)
        sparkle.position = point
        sparkle.fillColor = .clear
        sparkle.strokeColor = SKColor(red: 0.7, green: 1.0, blue: 0.8, alpha: 0.9)
        sparkle.lineWidth = 1
        sparkle.glowWidth = 2
        sparkle.zPosition = 4
        addChild(sparkle)

        sparkle.run(.sequence([
            .group([
                .scale(to: 2.0, duration: 0.15),
                .fadeOut(withDuration: 0.15)
            ]),
            .removeFromParent()
        ]))
    }

    private func handleAutoPlayHit() {
        shotNode?.removeAllActions()
        shotNode?.removeFromParent()
        shotNode = nil

        let flash = SKAction.sequence([
            .scale(to: 1.3, duration: 0.05),
            .scale(to: 0.3, duration: 0.08),
            .wait(forDuration: 0.07),
            .scale(to: 1.0, duration: 0.1)
        ])
        targetNode.run(flash) { [weak self] in
            self?.advanceAutoPlay(hit: true)
        }
    }

    private func advanceAutoPlay(hit: Bool) {
        if hit {
            autoPlayPassCount += 1
        }

        let info: [String: Any] = [
            "level": autoPlayCurrentLevel,
            "hit": hit,
            "pass": autoPlayPassCount,
            "fail": autoPlayFailCount
        ]
        NotificationCenter.default.post(name: .ricochetSimulationProgress, object: nil, userInfo: info)

        shotNode?.removeAllActions()
        shotNode?.removeFromParent()
        shotNode = nil
        canFire = true
        aimAngle = 0
        shipNode.zRotation = 0

        autoPlayCurrentLevel += 1

        run(.sequence([
            .wait(forDuration: 0.15),
            .run { [weak self] in self?.playNextAutoLevel() }
        ]))
    }

    // MARK: - Boundary walls

    private func setupBoundaryWalls() {
        let sideEdges: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height)),
            (CGPoint(x: size.width, y: 0), CGPoint(x: size.width, y: size.height)),
        ]
        for (from, to) in sideEdges {
            let node = SKNode()
            let body = SKPhysicsBody(edgeFrom: from, to: to)
            body.categoryBitMask = Category.wall
            body.friction = 0
            body.restitution = 1.0
            node.physicsBody = body
            addChild(node)
        }
    }

    private func setupVoidZone() {
        let voidEdges: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 0, y: size.height), CGPoint(x: size.width, y: size.height)),
            (CGPoint(x: 0, y: 0), CGPoint(x: size.width, y: 0)),
        ]
        for (from, to) in voidEdges {
            let node = SKNode()
            let body = SKPhysicsBody(edgeFrom: from, to: to)
            body.categoryBitMask = Category.void_zone
            body.contactTestBitMask = Category.shot
            body.collisionBitMask = 0
            node.physicsBody = body
            addChild(node)
        }

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: 1.8),
            .fadeAlpha(to: 0.8, duration: 1.8)
        ])

        let topBar = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: 3))
        topBar.position = CGPoint(x: size.width / 2, y: size.height - 1)
        topBar.fillColor = SKColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 0.7)
        topBar.strokeColor = .clear
        topBar.glowWidth = 6
        topBar.zPosition = -1
        addChild(topBar)
        topBar.run(.repeatForever(pulse))

        let topSoft = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: 16))
        topSoft.position = CGPoint(x: size.width / 2, y: size.height - 8)
        topSoft.fillColor = SKColor(red: 0.3, green: 0.05, blue: 0.5, alpha: 0.15)
        topSoft.strokeColor = .clear
        topSoft.zPosition = -2
        addChild(topSoft)

        let botBar = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: 3))
        botBar.position = CGPoint(x: size.width / 2, y: 1)
        botBar.fillColor = SKColor(red: 0.5, green: 0.1, blue: 0.8, alpha: 0.7)
        botBar.strokeColor = .clear
        botBar.glowWidth = 6
        botBar.zPosition = -1
        addChild(botBar)
        botBar.run(.repeatForever(pulse))

        let botSoft = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: 16))
        botSoft.position = CGPoint(x: size.width / 2, y: 8)
        botSoft.fillColor = SKColor(red: 0.3, green: 0.05, blue: 0.5, alpha: 0.15)
        botSoft.strokeColor = .clear
        botSoft.zPosition = -2
        addChild(botSoft)
    }

    // MARK: - Level loading

    private func setupLevelLabel() {
        levelLabel = SKLabelNode(text: "1")
        levelLabel.fontSize = 10
        levelLabel.fontColor = SKColor.white.withAlphaComponent(0.3)
        levelLabel.position = CGPoint(x: size.width - 12, y: 6)
        levelLabel.horizontalAlignmentMode = .right
        addChild(levelLabel)
    }

    private func loadLevel(_ number: Int) {
        let level = LevelGenerator.generate(number: number)

        levelLabel?.text = "\(level.number)"

        clearObstacles()
        targetNode?.removeFromParent()

        for obstacle in level.obstacles {
            let node = makeObstacleNode(obstacle)
            addChild(node)
            obstacleNodes.append(node)
        }

        let alienName = alienNames[level.alienIndex % alienNames.count]
        let texture = SKTexture(imageNamed: alienName)
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: 32, height: 32)
        sprite.position = level.targetPosition

        let body = SKPhysicsBody(circleOfRadius: 16)
        body.categoryBitMask = Category.target
        body.contactTestBitMask = Category.shot
        body.collisionBitMask = 0
        body.isDynamic = false
        sprite.physicsBody = body

        addChild(sprite)
        targetNode = sprite
    }

    private func clearObstacles() {
        for node in obstacleNodes {
            node.removeFromParent()
        }
        obstacleNodes.removeAll()
    }

    private func makeObstacleNode(_ obstacle: Obstacle) -> SKNode {
        let container = SKNode()

        let isAbsorb = obstacle.type == .absorb
        let category = isAbsorb ? Category.absorb : Category.obstacle

        let body = SKPhysicsBody(edgeFrom: obstacle.from, to: obstacle.to)
        body.categoryBitMask = category
        body.friction = 0

        if isAbsorb {
            body.restitution = 0
            body.collisionBitMask = 0
            body.contactTestBitMask = Category.shot
        } else {
            body.restitution = 1.0
        }

        container.physicsBody = body

        let path = CGMutablePath()
        path.move(to: obstacle.from)
        path.addLine(to: obstacle.to)

        let line = SKShapeNode(path: path)
        let zone = (levelNumber - 1) / 10

        if isAbsorb {
            let absorbColors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
                (0.6, 0.15, 0.7),   // Earth
                (0.7, 0.1, 0.5),    // Moon
                (0.9, 0.15, 0.2),   // Star
                (0.85, 0.1, 0.4),   // Planet
                (1.0, 0.2, 0.1),    // Sun
            ]
            let c = absorbColors[min(zone, absorbColors.count - 1)]
            line.strokeColor = SKColor(red: c.r, green: c.g, blue: c.b, alpha: 0.85)
            line.glowWidth = CGFloat(min(zone, 4)) + 2
            line.lineWidth = zone >= 3 ? 3 : 2
        } else {
            let wallColors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
                (0.3, 0.75, 0.85),  // Earth — cool cyan
                (0.55, 0.6, 0.85),  // Moon — soft blue
                (0.85, 0.75, 0.3),  // Star — warm gold
                (0.7, 0.4, 0.85),   // Planet — purple
                (0.95, 0.5, 0.2),   // Sun — orange
            ]
            let c = wallColors[min(zone, wallColors.count - 1)]
            line.strokeColor = SKColor(red: c.r, green: c.g, blue: c.b, alpha: 0.8)
            line.glowWidth = CGFloat(min(zone, 3)) + 1
            line.lineWidth = 2
        }

        container.addChild(line)

        return container
    }

    // MARK: - Ship

    private func setupShip() {
        shipNode = SKNode()
        shipNode.position = CGPoint(x: size.width / 2, y: 28)

        let body = SKShapeNode(path: shipBodyPath())
        body.fillColor = SKColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1)
        body.strokeColor = SKColor(red: 0.15, green: 0.5, blue: 0.25, alpha: 1)
        body.lineWidth = 0.5
        shipNode.addChild(body)

        let cockpit = SKShapeNode(ellipseOf: CGSize(width: 4, height: 6))
        cockpit.position = CGPoint(x: 0, y: 4)
        cockpit.fillColor = SKColor(red: 0.5, green: 0.95, blue: 0.7, alpha: 0.9)
        cockpit.strokeColor = .clear
        shipNode.addChild(cockpit)

        let leftEngine = makeEngineGlow(at: CGPoint(x: -3, y: -10))
        let rightEngine = makeEngineGlow(at: CGPoint(x: 3, y: -10))
        shipNode.addChild(leftEngine)
        shipNode.addChild(rightEngine)

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.4, duration: 0.6),
            .fadeAlpha(to: 1.0, duration: 0.6)
        ])
        leftEngine.run(.repeatForever(pulse))
        rightEngine.run(.repeatForever(pulse))

        addChild(shipNode)
    }

    private func shipBodyPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: 14))
        p.addQuadCurve(to: CGPoint(x: 4, y: 2), control: CGPoint(x: 2, y: 8))
        p.addLine(to: CGPoint(x: 10, y: -4))
        p.addLine(to: CGPoint(x: 11, y: -8))
        p.addLine(to: CGPoint(x: 6, y: -5))
        p.addLine(to: CGPoint(x: 4, y: -7))
        p.addLine(to: CGPoint(x: 4, y: -10))
        p.addLine(to: CGPoint(x: 2, y: -10))
        p.addLine(to: CGPoint(x: 2, y: -7))
        p.addLine(to: CGPoint(x: 0, y: -5))
        p.addLine(to: CGPoint(x: -2, y: -7))
        p.addLine(to: CGPoint(x: -2, y: -10))
        p.addLine(to: CGPoint(x: -4, y: -10))
        p.addLine(to: CGPoint(x: -4, y: -7))
        p.addLine(to: CGPoint(x: -6, y: -5))
        p.addLine(to: CGPoint(x: -11, y: -8))
        p.addLine(to: CGPoint(x: -10, y: -4))
        p.addQuadCurve(to: CGPoint(x: 0, y: 14), control: CGPoint(x: -2, y: 8))
        p.closeSubpath()
        return p
    }

    private func makeEngineGlow(at position: CGPoint) -> SKShapeNode {
        let glow = SKShapeNode(ellipseOf: CGSize(width: 3, height: 5))
        glow.position = CGPoint(x: position.x, y: position.y - 2)
        glow.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.9)
        glow.strokeColor = .clear
        glow.glowWidth = 2
        return glow
    }

    // MARK: - Aim

    private func setupAim() {
        aimNode = SKShapeNode()
        aimNode.strokeColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.3)
        aimNode.lineWidth = 1
        addChild(aimNode)
        redrawAim()
    }

    private func redrawAim() {
        let origin = shipNode.position
        let length: CGFloat = size.height * 1.5
        let dashLen: CGFloat = 3
        let gapLen: CGFloat = 4
        let dx = -sin(aimAngle)
        let dy = cos(aimAngle)

        let path = CGMutablePath()
        var dist: CGFloat = 18
        while dist < length {
            let sx = origin.x + dx * dist
            let sy = origin.y + dy * dist
            let ex = origin.x + dx * min(dist + dashLen, length)
            let ey = origin.y + dy * min(dist + dashLen, length)
            path.move(to: CGPoint(x: sx, y: sy))
            path.addLine(to: CGPoint(x: ex, y: ey))
            dist += dashLen + gapLen
        }
        aimNode.path = path
    }

    // MARK: - Countdown

    private func setupCountdownArc() {
        countdownArc = SKShapeNode()
        countdownArc.strokeColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.5)
        countdownArc.lineWidth = 2
        countdownArc.fillColor = .clear
        countdownArc.position = shipNode.position
        addChild(countdownArc)
        redrawCountdownArc()
    }

    private func redrawCountdownArc() {
        let fraction = CGFloat(countdownRemaining / countdownTotal)
        let arcAngle = fraction * .pi * 2
        let radius: CGFloat = 18

        if arcAngle > 0.01 {
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: radius,
                        startAngle: .pi / 2,
                        endAngle: .pi / 2 - arcAngle,
                        clockwise: true)
            countdownArc.path = path
        } else {
            countdownArc.path = nil
        }
    }

    // MARK: - Controls

    func updateAim(angle: Double) {
        aimAngle = CGFloat(angle)
        shipNode.zRotation = aimAngle
        redrawAim()
    }

    func fire() {
        guard canFire, shotNode == nil else { return }
        canFire = false

        let shot = SKShapeNode(circleOfRadius: shotRadius)
        shot.fillColor = SKColor(red: 0.3, green: 1.0, blue: 0.4, alpha: 1)
        shot.strokeColor = .clear
        shot.glowWidth = 1
        shot.position = CGPoint(
            x: shipNode.position.x - sin(aimAngle) * 20,
            y: shipNode.position.y + cos(aimAngle) * 20
        )

        let body = SKPhysicsBody(circleOfRadius: shotRadius)
        body.categoryBitMask = Category.shot
        body.contactTestBitMask = Category.target | Category.void_zone | Category.absorb
        body.collisionBitMask = Category.wall | Category.obstacle
        body.friction = 0
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0
        body.allowsRotation = false
        body.velocity = CGVector(
            dx: -sin(aimAngle) * shotSpeed,
            dy: cos(aimAngle) * shotSpeed
        )

        shot.physicsBody = body
        addChild(shot)
        shotNode = shot

        aimNode.isHidden = true
        countdownArc.isHidden = true

        let timeout: TimeInterval = autoPlayMode ? 4 : 6
        shot.run(.sequence([
            .wait(forDuration: timeout),
            .removeFromParent()
        ])) { [weak self] in
            self?.resetAfterShot()
        }
    }

    // MARK: - Shot lifecycle

    private func resetAfterShot() {
        if autoPlayMode {
            advanceAutoPlay(hit: false)
            return
        }

        shotNode = nil
        aimNode.isHidden = false
        countdownArc.isHidden = false
        canFire = true
        countdownRemaining = countdownTotal
        redrawCountdownArc()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if masks == Category.shot | Category.target {
            handleHit()
        } else if masks & (Category.void_zone | Category.absorb) != 0 &&
                  masks & Category.shot != 0 {
            handleMiss()
        }
    }

    private func handleHit() {
        shotNode?.removeAllActions()
        shotNode?.removeFromParent()
        shotNode = nil

        let flash = SKAction.sequence([
            .scale(to: 1.4, duration: 0.1),
            .scale(to: 0.2, duration: 0.15),
            .wait(forDuration: 0.3),
            .scale(to: 1.0, duration: 0.2)
        ])

        if autoPlayMode {
            targetNode.run(flash) { [weak self] in
                self?.advanceAutoPlay(hit: true)
            }
        } else {
            targetNode.run(flash) { [weak self] in
                guard let self else { return }
                NotificationCenter.default.post(
                    name: .ricochetLevelComplete,
                    object: self.levelNumber
                )
            }
            aimNode.isHidden = false
            countdownArc.isHidden = false
            canFire = true
            countdownRemaining = countdownTotal
            redrawCountdownArc()
        }
    }

    private func handleMiss() {
        guard let shot = shotNode else { return }

        let fadeOut = SKAction.sequence([
            .group([
                .fadeOut(withDuration: 0.3),
                .scale(to: 0.1, duration: 0.3)
            ]),
            .removeFromParent()
        ])
        shot.removeAllActions()
        shot.physicsBody = nil
        shot.run(fadeOut) { [weak self] in
            self?.resetAfterShot()
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if autoPlayMode && !autoPlayStarted {
            autoPlayStarted = true
            aimNode.isHidden = true
            countdownArc.isHidden = true
            playNextAutoLevel()
            return
        }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard canFire, shotNode == nil else { return }
        guard !autoPlayMode else { return }

        countdownRemaining -= dt
        if countdownRemaining <= 0 {
            fire()
        } else {
            redrawCountdownArc()
        }
    }
}

extension Notification.Name {
    static let ricochetLevelComplete = Notification.Name("ricochetLevelComplete")
    static let ricochetSimulationProgress = Notification.Name("ricochetSimulationProgress")
    static let ricochetSimulationComplete = Notification.Name("ricochetSimulationComplete")
}
