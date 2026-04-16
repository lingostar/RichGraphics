import SwiftUI
import SceneKit

struct HologramEffectView: View {
    @State private var scene: SCNScene = SCNScene()
    @State private var didSetup = false
    @State private var isWireframe = true
    @State private var opacity: Double = 1.0
    @State private var glitchTimer: Timer?

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(
                scene: scene,
                options: [.allowsCameraControl]
            )
            .background(.black)
            .ignoresSafeArea(edges: .bottom)

            controlPanel
        }
        .onAppear {
            if !didSetup { setupScene(); didSetup = true }
            startGlitchEffect()
        }
        .onDisappear { glitchTimer?.invalidate() }
        .onChange(of: isWireframe) { _, _ in updateHologramMode() }
    }

    private var controlPanel: some View {
        VStack(spacing: 10) {
            Toggle(isWireframe ? "Wireframe Mode" : "Solid Hologram", isOn: $isWireframe)
                .font(.caption.bold())
                .tint(.cyan)

            Text("Hologram flickers automatically")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Scene

    @MainActor
    private func setupScene() {
        scene.background.contents = UIColor.black

        let camera = SCNCamera()
        camera.fieldOfView = 50
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(0, 2, 6)
        camNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camNode)

        // Very dim ambient for the glow feel
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 150
        ambient.light?.color = UIColor.cyan
        scene.rootNode.addChildNode(ambient)

        // Hologram model: torus knot approximation using a torus
        let torus = SCNTorus(ringRadius: 1.2, pipeRadius: 0.4)
        let mat = makeHologramMaterial(wireframe: isWireframe)
        torus.materials = [mat]

        let modelNode = SCNNode(geometry: torus)
        modelNode.name = "hologram"

        let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
        modelNode.runAction(SCNAction.repeatForever(spin))

        let tilt = SCNAction.rotateBy(x: .pi * 2, y: 0, z: 0, duration: 10)
        modelNode.runAction(SCNAction.repeatForever(tilt))

        scene.rootNode.addChildNode(modelNode)

        // Scanline plane overlay
        let scanPlane = SCNPlane(width: 6, height: 6)
        let scanMat = SCNMaterial()
        scanMat.lightingModel = .constant
        scanMat.isDoubleSided = true
        scanMat.diffuse.contents = makeScanlineImage()
        scanMat.diffuse.wrapS = .repeat
        scanMat.diffuse.wrapT = .repeat
        scanMat.transparency = 0.15
        scanMat.writesToDepthBuffer = false
        scanPlane.materials = [scanMat]

        let scanNode = SCNNode(geometry: scanPlane)
        scanNode.name = "scanlines"
        scanNode.position = SCNVector3(0, 0, 2.5)

        let scrollUp = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 2)
        let reset = SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0)
        scanNode.runAction(SCNAction.repeatForever(SCNAction.sequence([scrollUp, reset])))

        scene.rootNode.addChildNode(scanNode)

        // Base ring
        let baseRing = SCNTorus(ringRadius: 1.5, pipeRadius: 0.02)
        let baseMat = SCNMaterial()
        baseMat.lightingModel = .constant
        baseMat.diffuse.contents = UIColor.cyan.withAlphaComponent(0.6)
        baseMat.emission.contents = UIColor.cyan
        baseRing.materials = [baseMat]
        let baseNode = SCNNode(geometry: baseRing)
        baseNode.position = SCNVector3(0, -1.2, 0)
        scene.rootNode.addChildNode(baseNode)
    }

    @MainActor
    private func makeHologramMaterial(wireframe: Bool) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.isDoubleSided = true

        if wireframe {
            mat.fillMode = .lines
            mat.diffuse.contents = UIColor.cyan.withAlphaComponent(0.8)
            mat.emission.contents = UIColor.cyan
            mat.emission.intensity = 0.8
        } else {
            mat.fillMode = .fill
            mat.diffuse.contents = UIColor.cyan.withAlphaComponent(0.25)
            mat.emission.contents = UIColor.cyan
            mat.emission.intensity = 0.5
            mat.transparency = 0.5
        }
        return mat
    }

    @MainActor
    private func updateHologramMode() {
        guard let node = scene.rootNode.childNode(withName: "hologram", recursively: false) else { return }
        let mat = makeHologramMaterial(wireframe: isWireframe)
        node.geometry?.materials = [mat]
    }

    private func makeScanlineImage() -> UIImage {
        let size = CGSize(width: 4, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.setFillColor(UIColor.cyan.withAlphaComponent(0.3).cgColor)
            for y in stride(from: 0, to: Int(size.height), by: 4) {
                ctx.cgContext.fill(CGRect(x: 0, y: y, width: Int(size.width), height: 1))
            }
        }
    }

    private func startGlitchEffect() {
        glitchTimer?.invalidate()
        glitchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                let r = Double.random(in: 0...1)
                if r < 0.08 {
                    // glitch: low opacity
                    scene.rootNode.childNode(withName: "hologram", recursively: false)?.opacity = CGFloat(Double.random(in: 0.1...0.4))
                } else if r < 0.12 {
                    // subtle flicker
                    scene.rootNode.childNode(withName: "hologram", recursively: false)?.opacity = CGFloat(Double.random(in: 0.6...0.8))
                } else {
                    scene.rootNode.childNode(withName: "hologram", recursively: false)?.opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HologramEffectView()
            .navigationTitle("Hologram Effect")
    }
}
