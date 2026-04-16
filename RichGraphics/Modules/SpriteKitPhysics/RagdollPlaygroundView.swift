import SwiftUI
import SpriteKit

struct RagdollPlaygroundView: View {
    @State private var scene: RagdollScene = {
        let scene = RagdollScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor.systemBackground
        return scene
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Spacer()
                Button("Reset") {
                    scene.resetRagdoll()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

@MainActor
final class RagdollScene: SKScene {
    private var ragdollParts: [SKNode] = []
    private var draggedNode: SKNode?
    private var dragJoint: SKPhysicsJointPin?

    private let headRadius: CGFloat = 22
    private let torsoSize = CGSize(width: 30, height: 60)
    private let limbSize = CGSize(width: 14, height: 40)
    private let forearmSize = CGSize(width: 12, height: 35)

    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.8
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        buildRagdoll(at: CGPoint(x: frame.midX, y: frame.midY + 80))
    }

    private func buildRagdoll(at center: CGPoint) {
        removeRagdoll()

        // Head
        let head = makeCircle(radius: headRadius, color: .systemYellow, name: "head")
        head.position = CGPoint(x: center.x, y: center.y + torsoSize.height / 2 + headRadius + 4)
        addChild(head)
        ragdollParts.append(head)

        // Torso
        let torso = makeRect(size: torsoSize, color: .systemBlue, name: "torso")
        torso.position = center
        addChild(torso)
        ragdollParts.append(torso)

        // Pin head to torso
        pinJoint(nodeA: head, nodeB: torso,
                 anchor: CGPoint(x: center.x, y: center.y + torsoSize.height / 2))

        // Left upper arm
        let leftArm = makeRect(size: limbSize, color: .systemTeal, name: "leftArm")
        leftArm.position = CGPoint(x: center.x - torsoSize.width / 2 - limbSize.width / 2,
                                    y: center.y + torsoSize.height / 2 - 8)
        addChild(leftArm)
        ragdollParts.append(leftArm)
        pinJoint(nodeA: torso, nodeB: leftArm,
                 anchor: CGPoint(x: center.x - torsoSize.width / 2,
                                 y: center.y + torsoSize.height / 2 - 8))

        // Left forearm
        let leftForearm = makeRect(size: forearmSize, color: .systemTeal, name: "leftForearm")
        leftForearm.position = CGPoint(x: leftArm.position.x,
                                        y: leftArm.position.y - limbSize.height / 2 - forearmSize.height / 2)
        addChild(leftForearm)
        ragdollParts.append(leftForearm)
        pinJoint(nodeA: leftArm, nodeB: leftForearm,
                 anchor: CGPoint(x: leftArm.position.x,
                                 y: leftArm.position.y - limbSize.height / 2))

        // Right upper arm
        let rightArm = makeRect(size: limbSize, color: .systemTeal, name: "rightArm")
        rightArm.position = CGPoint(x: center.x + torsoSize.width / 2 + limbSize.width / 2,
                                     y: center.y + torsoSize.height / 2 - 8)
        addChild(rightArm)
        ragdollParts.append(rightArm)
        pinJoint(nodeA: torso, nodeB: rightArm,
                 anchor: CGPoint(x: center.x + torsoSize.width / 2,
                                 y: center.y + torsoSize.height / 2 - 8))

        // Right forearm
        let rightForearm = makeRect(size: forearmSize, color: .systemTeal, name: "rightForearm")
        rightForearm.position = CGPoint(x: rightArm.position.x,
                                         y: rightArm.position.y - limbSize.height / 2 - forearmSize.height / 2)
        addChild(rightForearm)
        ragdollParts.append(rightForearm)
        pinJoint(nodeA: rightArm, nodeB: rightForearm,
                 anchor: CGPoint(x: rightArm.position.x,
                                 y: rightArm.position.y - limbSize.height / 2))

        // Left upper leg
        let leftLeg = makeRect(size: limbSize, color: .systemGreen, name: "leftLeg")
        leftLeg.position = CGPoint(x: center.x - 10,
                                    y: center.y - torsoSize.height / 2 - limbSize.height / 2)
        addChild(leftLeg)
        ragdollParts.append(leftLeg)
        pinJoint(nodeA: torso, nodeB: leftLeg,
                 anchor: CGPoint(x: center.x - 10,
                                 y: center.y - torsoSize.height / 2))

        // Left shin
        let leftShin = makeRect(size: forearmSize, color: .systemGreen, name: "leftShin")
        leftShin.position = CGPoint(x: leftLeg.position.x,
                                     y: leftLeg.position.y - limbSize.height / 2 - forearmSize.height / 2)
        addChild(leftShin)
        ragdollParts.append(leftShin)
        pinJoint(nodeA: leftLeg, nodeB: leftShin,
                 anchor: CGPoint(x: leftLeg.position.x,
                                 y: leftLeg.position.y - limbSize.height / 2))

        // Right upper leg
        let rightLeg = makeRect(size: limbSize, color: .systemGreen, name: "rightLeg")
        rightLeg.position = CGPoint(x: center.x + 10,
                                     y: center.y - torsoSize.height / 2 - limbSize.height / 2)
        addChild(rightLeg)
        ragdollParts.append(rightLeg)
        pinJoint(nodeA: torso, nodeB: rightLeg,
                 anchor: CGPoint(x: center.x + 10,
                                 y: center.y - torsoSize.height / 2))

        // Right shin
        let rightShin = makeRect(size: forearmSize, color: .systemGreen, name: "rightShin")
        rightShin.position = CGPoint(x: rightLeg.position.x,
                                      y: rightLeg.position.y - limbSize.height / 2 - forearmSize.height / 2)
        addChild(rightShin)
        ragdollParts.append(rightShin)
        pinJoint(nodeA: rightLeg, nodeB: rightShin,
                 anchor: CGPoint(x: rightLeg.position.x,
                                 y: rightLeg.position.y - limbSize.height / 2))
    }

    private func makeCircle(radius: CGFloat, color: UIColor, name: String) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.7)
        node.lineWidth = 2
        node.name = name

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = 0.5
        body.friction = 0.3
        body.restitution = 0.2
        body.linearDamping = 0.3
        body.angularDamping = 0.3
        node.physicsBody = body
        return node
    }

    private func makeRect(size: CGSize, color: UIColor, name: String) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: 4)
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.7)
        node.lineWidth = 2
        node.name = name

        let body = SKPhysicsBody(rectangleOf: size)
        body.mass = 0.3
        body.friction = 0.3
        body.restitution = 0.2
        body.linearDamping = 0.3
        body.angularDamping = 0.3
        node.physicsBody = body
        return node
    }

    private func pinJoint(nodeA: SKNode, nodeB: SKNode, anchor: CGPoint) {
        let joint = SKPhysicsJointPin.joint(withBodyA: nodeA.physicsBody!,
                                            bodyB: nodeB.physicsBody!,
                                            anchor: anchor)
        joint.shouldEnableLimits = true
        joint.lowerAngleLimit = -.pi / 3
        joint.upperAngleLimit = .pi / 3
        joint.frictionTorque = 0.2
        physicsWorld.add(joint)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let tappedNodes = nodes(at: location)
        for node in tappedNodes {
            if ragdollParts.contains(node) {
                draggedNode = node
                node.physicsBody?.isDynamic = false
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggedNode else { return }
        let location = touch.location(in: self)
        node.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggedNode else { return }
        let location = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        let velocity = CGVector(dx: (location.x - previous.x) * 20,
                                dy: (location.y - previous.y) * 20)

        node.physicsBody?.isDynamic = true
        node.physicsBody?.applyImpulse(velocity)
        draggedNode = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggedNode?.physicsBody?.isDynamic = true
        draggedNode = nil
    }

    func resetRagdoll() {
        buildRagdoll(at: CGPoint(x: frame.midX, y: frame.midY + 80))
    }

    private func removeRagdoll() {
        physicsWorld.removeAllJoints()
        ragdollParts.forEach { $0.removeFromParent() }
        ragdollParts.removeAll()
    }
}

#Preview {
    NavigationStack {
        RagdollPlaygroundView()
            .navigationTitle("Ragdoll Playground")
    }
}
