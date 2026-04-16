import SwiftUI
import SceneKit

struct ProceduralGeometryView: View {
    @State private var gridResolution: Double = 40
    @State private var amplitude: Double = 2.0
    @State private var frequency: Double = 0.15
    @State private var showTrees = true
    @State private var scene: SCNScene = SCNScene()
    @State private var didSetup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(
                scene: scene,
                options: [.allowsCameraControl]
            )
            .ignoresSafeArea(edges: .bottom)

            controlPanel
        }
        .onAppear { if !didSetup { setupScene(); didSetup = true } }
        .onChange(of: gridResolution) { _, _ in rebuildTerrain() }
        .onChange(of: amplitude) { _, _ in rebuildTerrain() }
        .onChange(of: frequency) { _, _ in rebuildTerrain() }
        .onChange(of: showTrees) { _, _ in rebuildTerrain() }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Grid: \(Int(gridResolution))")
                    .font(.caption.bold())
                    .frame(width: 70, alignment: .leading)
                Slider(value: $gridResolution, in: 10...80, step: 5)
            }
            HStack {
                Text("Height: \(amplitude, specifier: "%.1f")")
                    .font(.caption.bold())
                    .frame(width: 70, alignment: .leading)
                Slider(value: $amplitude, in: 0.5...5.0)
            }
            HStack {
                Text("Freq: \(frequency, specifier: "%.2f")")
                    .font(.caption.bold())
                    .frame(width: 70, alignment: .leading)
                Slider(value: $frequency, in: 0.05...0.4)
            }
            Toggle("Trees", isOn: $showTrees)
                .font(.caption.bold())
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
        scene.background.contents = UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1)

        let camera = SCNCamera()
        camera.fieldOfView = 60
        camera.zFar = 200
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(15, 12, 15)
        camNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camNode)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1000
        sun.light?.castsShadow = true
        sun.position = SCNVector3(10, 20, 10)
        sun.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sun)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        rebuildTerrain()
    }

    // MARK: - Terrain Generation

    @MainActor
    private func rebuildTerrain() {
        scene.rootNode.childNode(withName: "terrain", recursively: false)?.removeFromParentNode()

        let res = Int(gridResolution)
        let freq = Float(frequency)
        let amp = Float(amplitude)
        let size: Float = 20.0
        let step = size / Float(res)

        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var colors: [SCNVector4] = []
        var indices: [UInt32] = []

        for z in 0...res {
            for x in 0...res {
                let px = Float(x) * step - size / 2
                let pz = Float(z) * step - size / 2
                let h = heightAt(x: px, z: pz, freq: freq, amp: amp)
                vertices.append(SCNVector3(px, h, pz))

                let color = colorForHeight(h, amp: amp)
                colors.append(color)

                // Approximate normal via central differences
                let hL = heightAt(x: px - step, z: pz, freq: freq, amp: amp)
                let hR = heightAt(x: px + step, z: pz, freq: freq, amp: amp)
                let hD = heightAt(x: px, z: pz - step, freq: freq, amp: amp)
                let hU = heightAt(x: px, z: pz + step, freq: freq, amp: amp)
                let nx = hL - hR
                let nz = hD - hU
                let ny: Float = 2.0 * step
                let len = sqrtf(nx * nx + ny * ny + nz * nz)
                normals.append(SCNVector3(nx / len, ny / len, nz / len))
            }
        }

        let w = res + 1
        for z in 0..<res {
            for x in 0..<res {
                let tl = UInt32(z * w + x)
                let tr = tl + 1
                let bl = UInt32((z + 1) * w + x)
                let br = bl + 1
                indices.append(contentsOf: [tl, bl, tr, tr, bl, br])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)

        let colorData = Data(bytes: colors, count: colors.count * MemoryLayout<SCNVector4>.stride)
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector4>.stride
        )

        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, colorSource], elements: [element])

        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.roughness.contents = 0.8
        mat.metalness.contents = 0.0
        geometry.materials = [mat]

        let terrainNode = SCNNode(geometry: geometry)
        terrainNode.name = "terrain"

        if showTrees {
            addTrees(to: terrainNode, res: res, freq: freq, amp: amp, size: size)
        }

        scene.rootNode.addChildNode(terrainNode)
    }

    private func heightAt(x: Float, z: Float, freq: Float, amp: Float) -> Float {
        let f1 = freq
        let f2 = freq * 2.3
        let f3 = freq * 4.1
        let h = sinf(x * f1) * cosf(z * f1) * amp
            + sinf(x * f2 + 1.3) * cosf(z * f2 + 0.7) * amp * 0.4
            + sinf(x * f3 + 2.1) * cosf(z * f3 + 1.5) * amp * 0.15
        return h
    }

    private func colorForHeight(_ h: Float, amp: Float) -> SCNVector4 {
        let normalized = (h / amp + 1.0) * 0.5  // 0..1
        if normalized < 0.3 {
            return SCNVector4(0.2, 0.4, 0.8, 1)    // water blue
        } else if normalized < 0.55 {
            return SCNVector4(0.3, 0.7, 0.2, 1)    // grass green
        } else if normalized < 0.75 {
            return SCNVector4(0.55, 0.4, 0.25, 1)  // brown mountain
        } else {
            return SCNVector4(0.95, 0.95, 0.95, 1) // snow white
        }
    }

    @MainActor
    private func addTrees(to parent: SCNNode, res: Int, freq: Float, amp: Float, size: Float) {
        // Deterministic pseudo-random positions
        let treeCount = max(5, res / 2)
        for i in 0..<treeCount {
            let seed = Float(i) * 137.5
            let tx = sinf(seed) * size * 0.4
            let tz = cosf(seed * 0.7 + 3.0) * size * 0.4
            let th = heightAt(x: tx, z: tz, freq: freq, amp: amp)

            let normalized = (th / amp + 1.0) * 0.5
            guard normalized > 0.35 && normalized < 0.6 else { continue }

            let trunk = SCNCylinder(radius: 0.08, height: 0.5)
            let trunkMat = SCNMaterial()
            trunkMat.diffuse.contents = UIColor.brown
            trunk.materials = [trunkMat]
            let trunkNode = SCNNode(geometry: trunk)
            trunkNode.position = SCNVector3(tx, th + 0.25, tz)

            let foliage = SCNCone(topRadius: 0, bottomRadius: 0.35, height: 0.7)
            let foliageMat = SCNMaterial()
            foliageMat.diffuse.contents = UIColor(red: 0.1, green: 0.55, blue: 0.15, alpha: 1)
            foliage.materials = [foliageMat]
            let foliageNode = SCNNode(geometry: foliage)
            foliageNode.position = SCNVector3(tx, th + 0.85, tz)

            parent.addChildNode(trunkNode)
            parent.addChildNode(foliageNode)
        }
    }
}

#Preview {
    NavigationStack {
        ProceduralGeometryView()
            .navigationTitle("Procedural Geometry")
    }
}
