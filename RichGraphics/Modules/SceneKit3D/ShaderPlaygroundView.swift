import SwiftUI
import SceneKit

enum ShaderPreset: String, CaseIterable, Identifiable {
    case rainbowWave = "Rainbow Wave"
    case checkerboard = "Checkerboard"
    case noise = "Noise"
    case plasma = "Plasma"
    case ripple = "Ripple"

    var id: String { rawValue }

    var surfaceModifier: String {
        switch self {
        case .rainbowWave:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 uv = _surface.diffuseTexcoord;
            float wave = sin(uv.x * 10.0 + uTime * 2.0) * 0.5 + 0.5;
            float r = sin(wave * 3.14159 + 0.0) * 0.5 + 0.5;
            float g = sin(wave * 3.14159 + 2.094) * 0.5 + 0.5;
            float b = sin(wave * 3.14159 + 4.189) * 0.5 + 0.5;
            _surface.diffuse = float4(r, g, b, 1.0);
            """
        case .checkerboard:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 uv = _surface.diffuseTexcoord;
            float scale = 8.0;
            float offset = uTime * 0.5;
            float cx = floor((uv.x + offset) * scale);
            float cy = floor((uv.y + offset * 0.7) * scale);
            float checker = fmod(cx + cy, 2.0);
            _surface.diffuse = float4(checker, checker, checker, 1.0);
            """
        case .noise:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 uv = _surface.diffuseTexcoord;
            float2 p = uv * 15.0 + float2(uTime * 0.3, uTime * 0.2);
            float n = fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            float n2 = fract(sin(dot(p * 0.5, float2(269.5, 183.3))) * 43758.5453);
            float val = n * 0.6 + n2 * 0.4;
            _surface.diffuse = float4(val * 0.3, val * 0.8, val, 1.0);
            """
        case .plasma:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 uv = _surface.diffuseTexcoord;
            float t = uTime;
            float v1 = sin(uv.x * 10.0 + t);
            float v2 = sin(uv.y * 10.0 + t);
            float v3 = sin((uv.x + uv.y) * 10.0 + t);
            float v4 = sin(length(uv - 0.5) * 20.0 - t * 2.0);
            float v = (v1 + v2 + v3 + v4) * 0.25;
            float r = sin(v * 3.14159) * 0.5 + 0.5;
            float g = sin(v * 3.14159 + 2.094) * 0.5 + 0.5;
            float b = sin(v * 3.14159 + 4.189) * 0.5 + 0.5;
            _surface.diffuse = float4(r, g, b, 1.0);
            """
        case .ripple:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 uv = _surface.diffuseTexcoord;
            float2 center = float2(0.5, 0.5);
            float dist = length(uv - center);
            float wave = sin(dist * 30.0 - uTime * 4.0) * 0.5 + 0.5;
            float fade = 1.0 - smoothstep(0.0, 0.5, dist);
            float val = wave * fade;
            _surface.diffuse = float4(val * 0.2, val * 0.6, val, 1.0);
            """
        }
    }

    var geometryModifier: String? {
        switch self {
        case .ripple:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float2 pos = float2(_geometry.position.x, _geometry.position.z);
            float dist = length(pos);
            float wave = sin(dist * 8.0 - uTime * 3.0) * 0.15;
            _geometry.position.y += wave;
            """
        case .rainbowWave:
            return """
            #pragma arguments
            float uTime;
            #pragma body
            float wave = sin(_geometry.position.x * 3.0 + uTime * 2.0) * 0.1;
            _geometry.position.y += wave;
            """
        default:
            return nil
        }
    }
}

@MainActor
final class ShaderSceneController: NSObject, ObservableObject {
    let scene = SCNScene()
    @Published var selectedPreset: ShaderPreset = .plasma
    nonisolated(unsafe) var renderStartTime: TimeInterval = 0
    nonisolated(unsafe) var renderShaderNode: SCNNode?

    func setup() {
        scene.background.contents = UIColor(white: 0.1, alpha: 1)

        let camera = SCNCamera()
        camera.fieldOfView = 50
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(0, 3, 5)
        camNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 600
        scene.rootNode.addChildNode(ambient)

        applyPreset()
    }

    func applyPreset() {
        renderShaderNode?.removeFromParentNode()

        let geometry: SCNGeometry
        if selectedPreset == .ripple || selectedPreset == .rainbowWave {
            geometry = SCNPlane(width: 4, height: 4)
            (geometry as? SCNPlane)?.widthSegmentCount = 60
            (geometry as? SCNPlane)?.heightSegmentCount = 60
        } else if selectedPreset == .checkerboard || selectedPreset == .noise {
            geometry = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.1)
        } else {
            geometry = SCNSphere(radius: 1.5)
            (geometry as? SCNSphere)?.segmentCount = 64
        }

        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.isDoubleSided = true
        mat.shaderModifiers = [
            .surface: selectedPreset.surfaceModifier,
        ]
        if let geoMod = selectedPreset.geometryModifier {
            mat.shaderModifiers?[.geometry] = geoMod
        }
        mat.setValue(Float(0), forKey: "uTime")
        geometry.materials = [mat]

        let node = SCNNode(geometry: geometry)
        node.name = "shaderObject"

        if selectedPreset == .ripple || selectedPreset == .rainbowWave {
            node.eulerAngles.x = -.pi / 3
        }

        let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 12)
        node.runAction(SCNAction.repeatForever(spin))

        scene.rootNode.addChildNode(node)
        renderShaderNode = node
        renderStartTime = 0
    }

}

// MARK: - Render Delegate (called on SceneKit render thread)

final class ShaderRenderDelegate: NSObject, SCNSceneRendererDelegate {
    private weak var controller: ShaderSceneController?

    init(controller: ShaderSceneController) {
        self.controller = controller
    }

    func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let controller else { return }
        if controller.renderStartTime == 0 { controller.renderStartTime = time }
        let elapsed = Float(time - controller.renderStartTime)
        controller.renderShaderNode?.geometry?.materials.first?.setValue(elapsed, forKey: "uTime")
    }
}

struct ShaderPlaygroundView: View {
    @StateObject private var controller = ShaderSceneController()
    @State private var didSetup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ShaderSceneRepresentable(controller: controller)
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 8) {
                Text("Shader Preset")
                    .font(.caption.bold())
                Picker("Preset", selection: $controller.selectedPreset) {
                    ForEach(ShaderPreset.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear {
            if !didSetup { controller.setup(); didSetup = true }
        }
        .onChange(of: controller.selectedPreset) { _, _ in
            controller.applyPreset()
        }
    }
}

// MARK: - UIViewRepresentable for SCNSceneRendererDelegate

struct ShaderSceneRepresentable: UIViewRepresentable {
    let controller: ShaderSceneController

    func makeCoordinator() -> ShaderRenderDelegate {
        ShaderRenderDelegate(controller: controller)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = controller.scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = .black
        scnView.delegate = context.coordinator
        scnView.isPlaying = true
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

#Preview {
    NavigationStack {
        ShaderPlaygroundView()
            .navigationTitle("Shader Playground")
    }
}
