import SwiftUI
import SpriteKit

struct MagneticFieldView: View {
    @State private var scene: MagneticFieldScene = {
        let scene = MagneticFieldScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(white: 0.05, alpha: 1)
        return scene
    }()
    @State private var isAttractMode = true

    var body: some View {
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 12) {
                HStack {
                    Picker("Mode", selection: $isAttractMode) {
                        Label("Attract", systemImage: "arrow.down.to.line")
                            .tag(true)
                        Label("Repel", systemImage: "arrow.up.to.line")
                            .tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)

                    Spacer()

                    Button("Clear Fields") {
                        scene.clearFields()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onChange(of: isAttractMode) { _, newValue in
            scene.attractMode = newValue
        }
    }
}

@MainActor
final class MagneticFieldScene: SKScene {
    var attractMode = true
    private let particleCount = 60

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        spawnParticles()
    }

    private func spawnParticles() {
        let colors: [UIColor] = [.systemCyan, .systemMint, .systemPink, .systemYellow, .systemPurple]

        for _ in 0..<particleCount {
            let radius: CGFloat = CGFloat.random(in: 4...8)
            let particle = SKShapeNode(circleOfRadius: radius)
            particle.position = CGPoint(
                x: CGFloat.random(in: 40...(frame.width - 40)),
                y: CGFloat.random(in: 80...(frame.height - 80))
            )
            particle.fillColor = colors.randomElement() ?? .systemCyan
            particle.strokeColor = .clear
            particle.glowWidth = 2
            particle.name = "particle"

            let body = SKPhysicsBody(circleOfRadius: radius)
            body.mass = 0.02
            body.friction = 0.0
            body.restitution = 0.6
            body.linearDamping = 0.5
            body.fieldBitMask = 0x1
            particle.physicsBody = body

            addChild(particle)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        placeField(at: location)
    }

    private func placeField(at position: CGPoint) {
        let field: SKFieldNode
        if attractMode {
            field = SKFieldNode.radialGravityField()
            field.strength = 8
        } else {
            field = SKFieldNode.radialGravityField()
            field.strength = -8
        }
        field.falloff = 2.0
        field.region = SKRegion(radius: 150)
        field.position = position
        field.categoryBitMask = 0x1
        field.name = "field"

        // Visual indicator
        let indicator = SKShapeNode(circleOfRadius: 20)
        indicator.fillColor = attractMode ? UIColor.systemBlue.withAlphaComponent(0.3) : UIColor.systemRed.withAlphaComponent(0.3)
        indicator.strokeColor = attractMode ? .systemBlue : .systemRed
        indicator.lineWidth = 2
        indicator.glowWidth = 4
        indicator.name = "fieldIndicator"
        field.addChild(indicator)

        // Outer ring
        let ring = SKShapeNode(circleOfRadius: 40)
        ring.fillColor = .clear
        ring.strokeColor = (attractMode ? UIColor.systemBlue : UIColor.systemRed).withAlphaComponent(0.2)
        ring.lineWidth = 1
        ring.name = "fieldRing"
        field.addChild(ring)

        // Pulse animation
        let scaleUp = SKAction.scale(to: 1.5, duration: 1.0)
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 1.0)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        let pulseScale = SKAction.sequence([scaleUp, scaleDown])
        let pulseFade = SKAction.sequence([fadeOut, fadeIn])
        let pulseGroup = SKAction.group([pulseScale, pulseFade])
        ring.run(SKAction.repeatForever(pulseGroup))

        // Label
        let label = SKLabelNode(text: attractMode ? "+" : "−")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 20
        label.fontColor = attractMode ? .systemBlue : .systemRed
        label.verticalAlignmentMode = .center
        field.addChild(label)

        addChild(field)
    }

    func clearFields() {
        children.filter { $0.name == "field" }.forEach { $0.removeFromParent() }
    }
}

#Preview {
    NavigationStack {
        MagneticFieldView()
            .navigationTitle("Magnetic Field")
    }
}
