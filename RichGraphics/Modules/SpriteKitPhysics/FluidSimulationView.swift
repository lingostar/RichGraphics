import SwiftUI
import SpriteKit

enum FluidType: String, CaseIterable, Identifiable {
    case water, lava, slime
    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var color: UIColor {
        switch self {
        case .water: .systemBlue
        case .lava: .systemOrange
        case .slime: .systemGreen
        }
    }

    var particleRadius: CGFloat {
        switch self {
        case .water: 4
        case .lava: 5
        case .slime: 6
        }
    }

    var damping: CGFloat {
        switch self {
        case .water: 0.3
        case .lava: 0.8
        case .slime: 1.2
        }
    }
}

struct FluidSimulationView: View {
    @State private var scene: FluidScene = {
        let scene = FluidScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor.systemBackground
        return scene
    }()
    @State private var selectedFluid: FluidType = .water

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Picker("Fluid", selection: $selectedFluid) {
                    ForEach(FluidType.allCases) { fluid in
                        Text(fluid.label).tag(fluid)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .onChange(of: selectedFluid) { _, newValue in
            scene.currentFluid = newValue
        }
    }
}

@MainActor
final class FluidScene: SKScene {
    var currentFluid: FluidType = .water
    private let maxParticles = 500

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.2
        physicsWorld.gravity = CGVector(dx: 0, dy: -4.0)

        let attractorField = SKFieldNode.radialGravityField()
        attractorField.strength = 0.5
        attractorField.falloff = 1.5
        attractorField.position = CGPoint(x: frame.midX, y: frame.midY)
        attractorField.name = "centralField"
        attractorField.categoryBitMask = 0x1
        addChild(attractorField)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnParticles(at: location, count: 15)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnParticles(at: location, count: 5)
    }

    private func spawnParticles(at position: CGPoint, count: Int) {
        let particleCount = children.filter { $0.name == "particle" }.count
        let allowed = min(count, maxParticles - particleCount)
        guard allowed > 0 else { return }

        for _ in 0..<allowed {
            let radius = currentFluid.particleRadius
            let particle = SKShapeNode(circleOfRadius: radius)
            particle.position = CGPoint(
                x: position.x + CGFloat.random(in: -15...15),
                y: position.y + CGFloat.random(in: -15...15)
            )
            particle.fillColor = currentFluid.color.withAlphaComponent(CGFloat.random(in: 0.5...0.9))
            particle.strokeColor = .clear
            particle.glowWidth = 1
            particle.name = "particle"

            let body = SKPhysicsBody(circleOfRadius: radius)
            body.mass = 0.01
            body.friction = 0.0
            body.restitution = 0.1
            body.linearDamping = currentFluid.damping
            body.allowsRotation = false
            body.fieldBitMask = 0x1
            particle.physicsBody = body

            addChild(particle)
        }
    }
}

#Preview {
    NavigationStack {
        FluidSimulationView()
            .navigationTitle("Fluid Simulation")
    }
}
