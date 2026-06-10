import SpriteKit
import WatchKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private let paddleCategory:  UInt32 = 0x1 << 0
    private let ballCategory:    UInt32 = 0x1 << 1
    private let brickCategory:   UInt32 = 0x1 << 2
    private let wallCategory:    UInt32 = 0x1 << 3
    private let floorCategory:   UInt32 = 0x1 << 4

    private var paddle: SKNode?
    private var ball: SKNode?
    private var bricksRemaining = 0
    private var ballLaunched = false
    private var levelCompleted = false
    private var ballLost = false
    private var lives = 3

    var levelNumber = 1
    private var needsBuild = true
    private var lifeIndicators: [SKNode] = []

    override func sceneDidLoad() {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        buildWalls()
        buildPaddle()
        buildBall()
        buildLifeIndicators()
    }

    // MARK: - Construction

    private func buildWalls() {
        let w = size.width
        let h = size.height

        let left = SKNode()
        left.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: h))
        left.physicsBody?.categoryBitMask = wallCategory
        addChild(left)

        let right = SKNode()
        right.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: w, y: 0), to: CGPoint(x: w, y: h))
        right.physicsBody?.categoryBitMask = wallCategory
        addChild(right)

        let ceilingY = h - 55
        let top = SKNode()
        top.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: ceilingY), to: CGPoint(x: w, y: ceilingY))
        top.physicsBody?.categoryBitMask = wallCategory
        addChild(top)

        let ceilingLine = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 4, y: ceilingY))
        path.addLine(to: CGPoint(x: w - 4, y: ceilingY))
        ceilingLine.path = path
        ceilingLine.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        ceilingLine.lineWidth = 1
        addChild(ceilingLine)

        let floor = SKNode()
        floor.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: w, y: 0))
        floor.physicsBody?.categoryBitMask = floorCategory
        floor.physicsBody?.contactTestBitMask = ballCategory
        addChild(floor)
    }

    private func buildPaddle() {
        let paddleWidth: CGFloat = 50
        let paddleHeight: CGFloat = 6
        let shape = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 3)
        shape.fillColor = SKColor(white: 1.0, alpha: 0.7)
        shape.strokeColor = .clear
        shape.position = CGPoint(x: size.width / 2, y: 24)

        shape.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: paddleWidth, height: paddleHeight))
        shape.physicsBody?.isDynamic = false
        shape.physicsBody?.categoryBitMask = paddleCategory
        shape.physicsBody?.friction = 0
        shape.physicsBody?.restitution = 1.0

        paddle = shape
        addChild(shape)
    }

    private func buildBall() {
        let radius: CGFloat = 4
        let shape = SKShapeNode(circleOfRadius: radius)
        shape.fillColor = SKColor(white: 1.0, alpha: 0.9)
        shape.strokeColor = .clear
        shape.position = CGPoint(x: size.width / 2, y: 34)

        shape.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        shape.physicsBody?.isDynamic = false
        shape.physicsBody?.categoryBitMask = ballCategory
        shape.physicsBody?.contactTestBitMask = brickCategory | floorCategory | paddleCategory
        shape.physicsBody?.collisionBitMask = wallCategory | paddleCategory | brickCategory
        shape.physicsBody?.friction = 0
        shape.physicsBody?.restitution = 1.0
        shape.physicsBody?.linearDamping = 0
        shape.physicsBody?.angularDamping = 0
        shape.physicsBody?.allowsRotation = false

        ball = shape
        ballLaunched = false
        hasReceivedInput = false
        addChild(shape)
    }

    private func buildBricks() {
        let level = LevelData.level(levelNumber)
        let brickWidth: CGFloat = 22
        let brickHeight: CGFloat = 8
        let spacingX: CGFloat = 3
        let spacingY: CGFloat = 4

        let cols = level.cols
        let rows = level.rows
        let totalWidth = CGFloat(cols) * brickWidth + CGFloat(cols - 1) * spacingX
        let startX = (size.width - totalWidth) / 2 + brickWidth / 2
        let startY = size.height - 65

        let colors = level.colors

        bricksRemaining = 0
        for row in 0..<rows {
            let color = colors[row % colors.count]
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (brickWidth + spacingX)
                let y = startY - CGFloat(row) * (brickHeight + spacingY)

                let brick = SKNode()
                brick.position = CGPoint(x: x, y: y)
                brick.name = "brick"

                let body = SKShapeNode(rectOf: CGSize(width: brickWidth, height: brickHeight), cornerRadius: 3)
                body.fillColor = color.withAlphaComponent(0.45)
                body.strokeColor = SKColor(white: 1.0, alpha: 0.25)
                body.lineWidth = 0.5
                brick.addChild(body)

                let topHL = SKShapeNode(rectOf: CGSize(width: brickWidth - 2, height: 1))
                topHL.fillColor = SKColor(white: 1.0, alpha: 0.30)
                topHL.strokeColor = .clear
                topHL.position = CGPoint(x: 0, y: brickHeight * 0.35)
                brick.addChild(topHL)

                brick.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: brickWidth, height: brickHeight))
                brick.physicsBody?.isDynamic = false
                brick.physicsBody?.categoryBitMask = brickCategory
                brick.physicsBody?.contactTestBitMask = ballCategory
                brick.physicsBody?.friction = 0
                brick.physicsBody?.restitution = 1.0

                addChild(brick)
                bricksRemaining += 1
            }
        }
    }

    private func buildLifeIndicators() {
        lifeIndicators.forEach { $0.removeFromParent() }
        lifeIndicators.removeAll()

        let spacing: CGFloat = 10
        let totalWidth = spacing * CGFloat(lives - 1)
        let startX = (size.width - totalWidth) / 2

        for i in 0..<lives {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = SKColor(white: 1.0, alpha: 0.6)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 10)
            dot.zPosition = 10
            addChild(dot)
            lifeIndicators.append(dot)
        }
    }

    private func updateLifeIndicators() {
        for (i, dot) in lifeIndicators.enumerated() {
            if i < lives {
                dot.alpha = 1.0
                (dot as? SKShapeNode)?.fillColor = SKColor(white: 1.0, alpha: 0.6)
            } else {
                dot.run(SKAction.fadeOut(withDuration: 0.3))
            }
        }
    }

    // MARK: - Controls

    private var hasReceivedInput = false

    func updatePaddlePosition(_ normalizedX: CGFloat) {
        guard let paddle, let ball else { return }
        let paddleHalf: CGFloat = 25
        let minX = paddleHalf + 2
        let maxX = size.width - paddleHalf - 2
        let normalized = normalizedX / 3.0
        let x = max(minX, min(maxX, normalized * size.width))
        paddle.position.x = x

        if !ballLaunched {
            ball.position.x = x
            if hasReceivedInput {
                launch()
            }
            hasReceivedInput = true
        }
    }

    private func launch() {
        guard let ball else { return }
        ballLaunched = true
        ball.physicsBody?.isDynamic = true

        let speed: CGFloat = LevelData.level(levelNumber).ballSpeed
        let angle = CGFloat.random(in: 0.4...0.8)
        let dx = Bool.random() ? speed * cos(angle) : -speed * cos(angle)
        ball.physicsBody?.velocity = CGVector(dx: dx, dy: speed * sin(angle))

        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        let brickBody: SKPhysicsBody?
        let otherMask: UInt32

        if a.categoryBitMask == brickCategory {
            brickBody = a; otherMask = b.categoryBitMask
        } else if b.categoryBitMask == brickCategory {
            brickBody = b; otherMask = a.categoryBitMask
        } else {
            brickBody = nil; otherMask = 0
        }

        if let brick = brickBody, otherMask == ballCategory {
            destroyBrick(brick.node!)
            return
        }

        if (a.categoryBitMask == floorCategory && b.categoryBitMask == ballCategory) ||
           (b.categoryBitMask == floorCategory && a.categoryBitMask == ballCategory) {
            handleBallLost()
            return
        }

        if (a.categoryBitMask == paddleCategory && b.categoryBitMask == ballCategory) ||
           (b.categoryBitMask == paddleCategory && a.categoryBitMask == ballCategory) {
            WKInterfaceDevice.current().play(.click)
            adjustBallAngle()
        }
    }

    private func destroyBrick(_ node: SKNode) {
        var brick = node
        while brick.name != "brick", let parent = brick.parent {
            brick = parent
        }
        guard brick.name == "brick" else { return }

        brick.name = nil
        brick.removeFromParent()
        bricksRemaining -= 1
        WKInterfaceDevice.current().play(.click)

        if bricksRemaining <= 0 && !levelCompleted {
            handleLevelComplete()
        }
    }

    private func adjustBallAngle() {
        guard let ball, let body = ball.physicsBody else { return }
        var vel = body.velocity
        let speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        let targetSpeed = LevelData.level(levelNumber).ballSpeed

        if vel.dy < 30 && vel.dy > -30 {
            vel.dy = vel.dy > 0 ? 60 : -60
        }
        if vel.dy < 0 { vel.dy = abs(vel.dy) }

        let currentSpeed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        if currentSpeed > 0 {
            vel.dx = vel.dx / currentSpeed * max(speed, targetSpeed)
            vel.dy = vel.dy / currentSpeed * max(speed, targetSpeed)
        }
        body.velocity = vel
    }

    // MARK: - Game Flow

    private func handleBallLost() {
        guard !ballLost else { return }
        ballLost = true
        lives -= 1
        ballLaunched = false
        WKInterfaceDevice.current().play(.failure)

        ball?.removeFromParent()
        ball = nil
        updateLifeIndicators()

        if lives > 0 {
            run(SKAction.wait(forDuration: 1.5)) { [weak self] in
                guard let self else { return }
                self.ballLost = false
                self.buildBall()
            }
        } else {
            let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
            flash.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.0)
            flash.strokeColor = .clear
            flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
            flash.zPosition = 100
            addChild(flash)

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
                self.ballLost = false
                self.lives = 3
                self.resetLevel()
                self.buildLifeIndicators()
            }
        }
    }

    private func handleLevelComplete() {
        guard !levelCompleted else { return }
        levelCompleted = true
        ballLaunched = false
        ball?.removeFromParent()
        ball = nil

        WKInterfaceDevice.current().play(.success)

        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.0)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 100
        addChild(flash)

        flash.run(SKAction.customAction(withDuration: 0.6) { node, elapsed in
            let t = elapsed / 0.6
            (node as? SKShapeNode)?.fillColor = SKColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.18 * t)
        })

        run(SKAction.wait(forDuration: 0.4)) {
            WKInterfaceDevice.current().play(.success)
        }

        paddle?.run(SKAction.sequence([
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
            NotificationCenter.default.post(name: .shatterLevelComplete, object: self.levelNumber)
        }
    }

    private func resetLevel() {
        children.filter { $0.name == "brick" }.forEach { $0.removeFromParent() }
        ball?.removeFromParent()

        buildBall()
        buildBricks()
    }

    // MARK: - Safety

    override func update(_ currentTime: TimeInterval) {
        if needsBuild {
            needsBuild = false
            buildBricks()
        }
        guard ballLaunched, let ball, let body = ball.physicsBody else { return }
        let vel = body.velocity
        let speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        let target = LevelData.level(levelNumber).ballSpeed

        if speed < target * 0.8 && speed > 0 {
            let scale = target / speed
            body.velocity = CGVector(dx: vel.dx * scale, dy: vel.dy * scale)
        }

        if ball.position.x < 0 || ball.position.x > size.width ||
           ball.position.y < -10 || ball.position.y > size.height + 10 {
            handleBallLost()
        }
    }
}

extension Notification.Name {
    static let shatterLevelComplete = Notification.Name("shatterLevelComplete")
}
