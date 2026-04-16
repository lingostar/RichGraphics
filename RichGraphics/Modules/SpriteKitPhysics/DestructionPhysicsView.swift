import SwiftUI
import SpriteKit

struct DestructionPhysicsView: View {
    @State private var scene: DestructionScene = {
        let scene = DestructionScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor.systemBackground
        return scene
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Text("Tap shapes to destroy them")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Button("Spawn Shape") {
                    scene.spawnRandomShape()
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

@MainActor
final class DestructionScene: SKScene {
    private let shapeColors: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen,
        .systemOrange, .systemPurple, .systemTeal,
    ]

    private enum ShapeKind: CaseIterable {
        case square, circle, triangle
    }

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.5
        physicsWorld.gravity = CGVector(dx: 0, dy: -6.0)

        for _ in 0..<5 {
            spawnRandomShape()
        }
    }

    func spawnRandomShape() {
        let kind = ShapeKind.allCases.randomElement() ?? .square
        let color = shapeColors.randomElement() ?? .systemBlue
        let size = CGFloat.random(in: 40...70)
        let x = CGFloat.random(in: 60...(frame.width - 60))
        let y = frame.height - 100

        let shape: SKShapeNode
        switch kind {
        case .square:
            shape = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 4)
            shape.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size, height: size))
        case .circle:
            shape = SKShapeNode(circleOfRadius: size / 2)
            shape.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        case .triangle:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size / 2))
            path.addLine(to: CGPoint(x: -size / 2, y: -size / 2))
            path.addLine(to: CGPoint(x: size / 2, y: -size / 2))
            path.closeSubpath()
            shape = SKShapeNode(path: path)
            shape.physicsBody = SKPhysicsBody(polygonFrom: path)
        }

        shape.position = CGPoint(x: x, y: y)
        shape.fillColor = color
        shape.strokeColor = color.withAlphaComponent(0.6)
        shape.lineWidth = 2
        shape.name = "shape"
        shape.physicsBody?.restitution = 0.3
        shape.physicsBody?.friction = 0.4
        shape.physicsBody?.density = 1.0

        addChild(shape)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let tappedNodes = nodes(at: location)
        for node in tappedNodes {
            if node.name == "shape", let shapeNode = node as? SKShapeNode {
                destroyShape(shapeNode)
                return
            }
        }
    }

    private func destroyShape(_ shape: SKShapeNode) {
        let position = shape.position
        let color = shape.fillColor
        shape.removeFromParent()

        let fragmentCount = Int.random(in: 8...14)
        for _ in 0..<fragmentCount {
            let fragSize = CGFloat.random(in: 6...14)
            let fragment = SKShapeNode(rectOf: CGSize(width: fragSize, height: fragSize), cornerRadius: 2)
            fragment.position = CGPoint(
                x: position.x + CGFloat.random(in: -15...15),
                y: position.y + CGFloat.random(in: -15...15)
            )
            fragment.fillColor = color.withAlphaComponent(CGFloat.random(in: 0.5...1.0))
            fragment.strokeColor = .clear
            fragment.name = "fragment"

            let body = SKPhysicsBody(rectangleOf: CGSize(width: fragSize, height: fragSize))
            body.mass = 0.01
            body.restitution = 0.4
            body.friction = 0.3
            body.linearDamping = 0.3
            body.angularDamping = 0.3
            fragment.physicsBody = body

            // Explode outward
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let force = CGFloat.random(in: 2...6)
            let impulse = CGVector(dx: cos(angle) * force, dy: sin(angle) * force)
            fragment.physicsBody?.applyImpulse(impulse)
            fragment.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.1...0.1))

            addChild(fragment)

            // Fade out and remove after a while
            let wait = SKAction.wait(forDuration: Double.random(in: 2...4))
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            fragment.run(SKAction.sequence([wait, fade, remove]))
        }

        // Flash effect
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.position = position
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.8
        flash.zPosition = 10
        addChild(flash)
        let expand = SKAction.scale(to: 2.0, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let group = SKAction.group([expand, fadeOut])
        flash.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
}

#Preview {
    NavigationStack {
        DestructionPhysicsView()
            .navigationTitle("Destruction Physics")
    }
}
