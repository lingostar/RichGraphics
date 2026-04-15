import SwiftUI
import SpriteKit

struct SpriteKitPhysicsView: View {
    @State private var scene: BallDropScene = {
        let scene = BallDropScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .white
        return scene
    }()

    var body: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Text("Tap anywhere to drop a ball")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    scene.clearBalls()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

@MainActor
class BallDropScene: SKScene {
    private let ballColors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink, .systemTeal]

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.5
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        addBall(at: location)
    }

    private func addBall(at position: CGPoint) {
        let radius = CGFloat.random(in: 15...35)
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.position = position
        ball.fillColor = ballColors.randomElement() ?? .systemBlue
        ball.strokeColor = ball.fillColor.withAlphaComponent(0.7)
        ball.lineWidth = 2

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.restitution = CGFloat.random(in: 0.4...0.8)
        body.friction = 0.3
        body.density = 1.0
        ball.physicsBody = body
        ball.name = "ball"

        addChild(ball)
    }

    func clearBalls() {
        children.filter { $0.name == "ball" }.forEach { $0.removeFromParent() }
    }
}

#Preview {
    NavigationStack {
        SpriteKitPhysicsView()
            .navigationTitle("SpriteKit Physics")
    }
}
