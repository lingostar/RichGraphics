import SwiftUI
import SpriteKit

struct BreakoutGameView: View {
    @State private var scene: BreakoutScene = {
        let scene = BreakoutScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(white: 0.05, alpha: 1)
        return scene
    }()

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Label("\(scene.score)", systemImage: "star.fill")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.yellow)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<scene.lives, id: \.self) { _ in
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Spacer()

                Button("New Game") {
                    scene.newGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }
}

@MainActor
final class BreakoutScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    @Published var score: Int = 0
    @Published var lives: Int = 3

    private var paddle: SKShapeNode?
    private var ball: SKShapeNode?
    private var isGameOver = false

    private let ballCategory: UInt32 = 0x1
    private let brickCategory: UInt32 = 0x2
    private let paddleCategory: UInt32 = 0x4
    private let wallCategory: UInt32 = 0x8
    private let bottomCategory: UInt32 = 0x10

    private let brickColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen]

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        newGame()
    }

    func newGame() {
        removeAllChildren()
        score = 0
        lives = 3
        isGameOver = false

        setupWalls()
        setupPaddle()
        setupBricks()
        setupBall()
    }

    private func setupWalls() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: frame)
        borderBody.categoryBitMask = wallCategory
        borderBody.friction = 0
        borderBody.restitution = 1
        physicsBody = borderBody

        // Bottom sensor
        let bottomRect = CGRect(x: 0, y: 0, width: frame.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        bottom.physicsBody?.categoryBitMask = bottomCategory
        bottom.physicsBody?.contactTestBitMask = ballCategory
        addChild(bottom)
    }

    private func setupPaddle() {
        let paddleWidth: CGFloat = 100
        let paddleHeight: CGFloat = 16
        let paddleNode = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 8)
        paddleNode.fillColor = .white
        paddleNode.strokeColor = .systemBlue
        paddleNode.lineWidth = 2
        paddleNode.position = CGPoint(x: frame.midX, y: 50)
        paddleNode.name = "paddle"

        let body = SKPhysicsBody(rectangleOf: CGSize(width: paddleWidth, height: paddleHeight))
        body.isDynamic = false
        body.categoryBitMask = paddleCategory
        body.contactTestBitMask = ballCategory
        body.friction = 0
        body.restitution = 1
        paddleNode.physicsBody = body

        addChild(paddleNode)
        paddle = paddleNode
    }

    private func setupBricks() {
        let rows = 4
        let cols = 8
        let brickWidth: CGFloat = (frame.width - 40) / CGFloat(cols) - 4
        let brickHeight: CGFloat = 18
        let startY = frame.height - 120

        for row in 0..<rows {
            let color = brickColors[row % brickColors.count]
            for col in 0..<cols {
                let brick = SKShapeNode(rectOf: CGSize(width: brickWidth, height: brickHeight), cornerRadius: 4)
                brick.fillColor = color
                brick.strokeColor = color.withAlphaComponent(0.6)
                brick.lineWidth = 1
                brick.name = "brick"

                let x = 24 + brickWidth / 2 + CGFloat(col) * (brickWidth + 4)
                let y = startY - CGFloat(row) * (brickHeight + 6)
                brick.position = CGPoint(x: x, y: y)

                let body = SKPhysicsBody(rectangleOf: CGSize(width: brickWidth, height: brickHeight))
                body.isDynamic = false
                body.categoryBitMask = brickCategory
                body.contactTestBitMask = ballCategory
                body.friction = 0
                body.restitution = 1
                brick.physicsBody = body

                addChild(brick)
            }
        }
    }

    private func setupBall() {
        ball?.removeFromParent()

        let radius: CGFloat = 8
        let ballNode = SKShapeNode(circleOfRadius: radius)
        ballNode.fillColor = .white
        ballNode.strokeColor = .systemCyan
        ballNode.lineWidth = 2
        ballNode.glowWidth = 2
        ballNode.position = CGPoint(x: frame.midX, y: 80)
        ballNode.name = "ball"

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.categoryBitMask = ballCategory
        body.contactTestBitMask = brickCategory | bottomCategory | paddleCategory
        body.collisionBitMask = wallCategory | paddleCategory | brickCategory
        body.friction = 0
        body.restitution = 1
        body.linearDamping = 0
        body.angularDamping = 0
        body.allowsRotation = false
        ballNode.physicsBody = body

        addChild(ballNode)
        ball = ballNode

        let angle = CGFloat.random(in: .pi / 4 ... 3 * .pi / 4)
        let speed: CGFloat = 300
        body.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(to: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(to: touches)
    }

    private func movePaddle(to touches: Set<UITouch>) {
        guard let touch = touches.first, let paddle = paddle else { return }
        let location = touch.location(in: self)
        let newX = max(54, min(location.x, frame.width - 54))
        paddle.position.x = newX
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        let categories = bodies.map { $0.categoryBitMask }

        if categories.contains(brickCategory) && categories.contains(ballCategory) {
            let brickBody = bodies.first { $0.categoryBitMask == brickCategory }
            if let brick = brickBody?.node {
                brick.removeFromParent()
                score += 10
            }
        }

        if categories.contains(bottomCategory) && categories.contains(ballCategory) {
            lives -= 1
            if lives <= 0 {
                isGameOver = true
                ball?.removeFromParent()
            } else {
                setupBall()
            }
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard let ball = ball, let body = ball.physicsBody else { return }

        // Keep ball speed constant
        let speed: CGFloat = 300
        let velocity = body.velocity
        let currentSpeed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if currentSpeed > 0 && abs(currentSpeed - speed) > 10 {
            let factor = speed / currentSpeed
            body.velocity = CGVector(dx: velocity.dx * factor, dy: velocity.dy * factor)
        }

        // Prevent nearly horizontal movement
        if abs(body.velocity.dy) < 50 {
            let sign: CGFloat = body.velocity.dy >= 0 ? 1 : -1
            body.velocity.dy = sign * 80
        }
    }
}

#Preview {
    NavigationStack {
        BreakoutGameView()
            .navigationTitle("Breakout Mini-Game")
    }
}
