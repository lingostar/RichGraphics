import SwiftUI
import SceneKit

struct SceneKit3DView: View {
    @State private var rotationSpeed: Double = 1.0
    @State private var scene: SCNScene = makeScene()

    var body: some View {
        VStack(spacing: 0) {
            SceneView(
                scene: scene,
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 8) {
                Text("Rotation Speed: \(rotationSpeed, specifier: "%.1f")x")
                    .font(.subheadline.monospaced())

                Slider(value: $rotationSpeed, in: 0...5, step: 0.5)
                    .padding(.horizontal, 32)
                    .onChange(of: rotationSpeed) { _, newValue in
                        updateRotation(speed: newValue)
                    }

                Text("Drag to orbit the camera")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func updateRotation(speed: Double) {
        guard let cube = scene.rootNode.childNode(withName: "cube", recursively: false) else { return }
        cube.removeAllActions()
        if speed > 0 {
            let rotation = SCNAction.rotateBy(
                x: CGFloat(speed),
                y: CGFloat(speed * 1.3),
                z: 0,
                duration: 1.0
            )
            cube.runAction(SCNAction.repeatForever(rotation))
        }
    }

    private static func makeScene() -> SCNScene {
        let scene = SCNScene()

        // Cube
        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemGreen
        material.specular.contents = UIColor.white
        material.roughness.contents = 0.3
        box.materials = [material]

        let cubeNode = SCNNode(geometry: box)
        cubeNode.name = "cube"
        let rotation = SCNAction.rotateBy(x: 1, y: 1.3, z: 0, duration: 1.0)
        cubeNode.runAction(SCNAction.repeatForever(rotation))
        scene.rootNode.addChildNode(cubeNode)

        // Floor
        let floor = SCNFloor()
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor.systemGray5
        floorMaterial.roughness.contents = 1.0
        floor.materials = [floorMaterial]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -2, 0)
        scene.rootNode.addChildNode(floorNode)

        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = 50
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(5, 3, 5)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Lights
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 800
        lightNode.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(lightNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)

        return scene
    }
}

#Preview {
    NavigationStack {
        SceneKit3DView()
            .navigationTitle("3D World")
    }
}
