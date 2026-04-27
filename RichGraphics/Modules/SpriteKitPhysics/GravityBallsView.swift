import SwiftUI
import SpriteKit
import CoreMotion

struct GravityBallsView: View {
    @State private var scene: GravityBallsScene = {
        let scene = GravityBallsScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor.systemBackground
        return scene
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Text("\(scene.ballCount) balls")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Button("Clear All") {
                    scene.clearBalls()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .lockOrientation(.landscape)
    }
}

@MainActor
final class GravityBallsScene: SKScene {
    private let ballColors: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen,
        .systemOrange, .systemPurple, .systemPink,
        .systemTeal, .systemYellow, .systemIndigo,
    ]

    private let motionManager = CMMotionManager()
    @Published var ballCount: Int = 0

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.5
        physicsBody?.restitution = 0.3
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        startMotionUpdates()
    }

    override func willMove(from view: SKView) {
        motionManager.stopAccelerometerUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data, let self = self else { return }
            let gravity = CGVector(
                dx: data.acceleration.x * 9.8,
                dy: data.acceleration.y * 9.8
            )
            self.physicsWorld.gravity = gravity
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        addBall(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        addBall(at: location)
    }

    private func addBall(at position: CGPoint) {
        let radius = CGFloat.random(in: 10...30)
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.position = position
        ball.fillColor = ballColors.randomElement() ?? .systemBlue
        ball.strokeColor = ball.fillColor.withAlphaComponent(0.6)
        ball.lineWidth = 2
        ball.glowWidth = 1

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.restitution = CGFloat.random(in: 0.5...0.9)
        body.friction = 0.2
        body.density = CGFloat.random(in: 0.5...2.0)
        body.linearDamping = 0.1
        ball.physicsBody = body
        ball.name = "ball"

        addChild(ball)
        ballCount = children.filter { $0.name == "ball" }.count
    }

    func clearBalls() {
        children.filter { $0.name == "ball" }.forEach { $0.removeFromParent() }
        ballCount = 0
    }
}

#Preview {
    NavigationStack {
        GravityBallsView()
            .navigationTitle("Gravity Balls")
    }
}
