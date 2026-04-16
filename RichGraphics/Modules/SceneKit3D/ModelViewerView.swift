import SwiftUI
import SceneKit

// MARK: - Model Types

enum PrimitiveShape: String, CaseIterable, Identifiable {
    case sphere = "Sphere"
    case cube = "Cube"
    case torus = "Torus"
    case capsule = "Capsule"
    case cone = "Cone"
    case cylinder = "Cylinder"

    var id: String { rawValue }

    @MainActor
    func geometry() -> SCNGeometry {
        switch self {
        case .sphere: return SCNSphere(radius: 1.0)
        case .cube: return SCNBox(width: 1.8, height: 1.8, length: 1.8, chamferRadius: 0.05)
        case .torus: return SCNTorus(ringRadius: 1.0, pipeRadius: 0.35)
        case .capsule: return SCNCapsule(capRadius: 0.5, height: 2.0)
        case .cone: return SCNCone(topRadius: 0, bottomRadius: 1.0, height: 2.0)
        case .cylinder: return SCNCylinder(radius: 0.8, height: 2.0)
        }
    }
}

enum MaterialStyle: String, CaseIterable, Identifiable {
    case metallic = "Metallic"
    case plastic = "Plastic"
    case glass = "Glass"
    case wireframe = "Wireframe"

    var id: String { rawValue }

    @MainActor
    func apply(to material: SCNMaterial) {
        material.isDoubleSided = true
        switch self {
        case .metallic:
            material.lightingModel = .physicallyBased
            material.metalness.contents = 1.0
            material.roughness.contents = 0.2
            material.diffuse.contents = UIColor.systemGray
            material.fillMode = .fill
        case .plastic:
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.0
            material.roughness.contents = 0.6
            material.diffuse.contents = UIColor.systemBlue
            material.fillMode = .fill
        case .glass:
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.0
            material.roughness.contents = 0.05
            material.diffuse.contents = UIColor.systemCyan.withAlphaComponent(0.3)
            material.transparency = 0.4
            material.fillMode = .fill
        case .wireframe:
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.systemGreen
            material.fillMode = .lines
        }
    }
}

// MARK: - View

struct ModelViewerView: View {
    @State private var selectedShape: PrimitiveShape = .sphere
    @State private var selectedMaterial: MaterialStyle = .metallic
    @State private var ambientIntensity: Double = 400
    @State private var directionalLightOn = true
    @State private var bgColor: Color = .black
    @State private var scene: SCNScene = SCNScene()
    @State private var didSetup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(
                scene: scene,
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .background(bgColor)
            .ignoresSafeArea(edges: .bottom)

            controlPanel
        }
        .onAppear { if !didSetup { setupScene(); didSetup = true } }
        .onChange(of: selectedShape) { _, _ in rebuildModel() }
        .onChange(of: selectedMaterial) { _, _ in rebuildModel() }
        .onChange(of: ambientIntensity) { _, val in updateAmbient(val) }
        .onChange(of: directionalLightOn) { _, val in updateDirectional(val) }
    }

    // MARK: - Controls

    private var controlPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Shape")
                    .font(.caption.bold())
                Spacer()
                Picker("Shape", selection: $selectedShape) {
                    ForEach(PrimitiveShape.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Material")
                    .font(.caption.bold())
                Spacer()
                Picker("Material", selection: $selectedMaterial) {
                    ForEach(MaterialStyle.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Text("Ambient")
                    .font(.caption.bold())
                Slider(value: $ambientIntensity, in: 0...1000)
            }

            HStack {
                Toggle("Directional Light", isOn: $directionalLightOn)
                    .font(.caption.bold())
            }

            ColorPicker("Background", selection: $bgColor)
                .font(.caption.bold())
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Scene Setup

    @MainActor
    private func setupScene() {
        let camera = SCNCamera()
        camera.fieldOfView = 50
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(4, 3, 4)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.name = "ambient"
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = CGFloat(ambientIntensity)
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        directional.name = "directional"
        directional.light = SCNLight()
        directional.light?.type = .directional
        directional.light?.intensity = 800
        directional.light?.castsShadow = true
        directional.position = SCNVector3(5, 10, 5)
        directional.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directional)

        let floor = SCNFloor()
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor.darkGray
        floorMat.roughness.contents = 1.0
        floor.materials = [floorMat]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -1.5, 0)
        scene.rootNode.addChildNode(floorNode)

        rebuildModel()
    }

    @MainActor
    private func rebuildModel() {
        scene.rootNode.childNode(withName: "model", recursively: false)?.removeFromParentNode()

        let geo = selectedShape.geometry()
        let mat = SCNMaterial()
        selectedMaterial.apply(to: mat)
        geo.materials = [mat]

        let node = SCNNode(geometry: geo)
        node.name = "model"

        let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
        node.runAction(SCNAction.repeatForever(spin))

        scene.rootNode.addChildNode(node)
    }

    @MainActor
    private func updateAmbient(_ value: Double) {
        scene.rootNode.childNode(withName: "ambient", recursively: false)?.light?.intensity = CGFloat(value)
    }

    @MainActor
    private func updateDirectional(_ on: Bool) {
        scene.rootNode.childNode(withName: "directional", recursively: false)?.light?.intensity = on ? 800 : 0
    }
}

#Preview {
    NavigationStack {
        ModelViewerView()
            .navigationTitle("3D Model Viewer")
    }
}
