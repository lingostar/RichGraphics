import SwiftUI
import SceneKit

struct SolarSystemView: View {
    @State private var scene: SCNScene = SCNScene()
    @State private var didSetup = false
    @State private var speedMultiplier: Double = 1.0

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(
                scene: scene,
                options: [.allowsCameraControl]
            )
            .background(.black)
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 6) {
                Text("Speed: \(speedMultiplier, specifier: "%.1f")x")
                    .font(.caption.bold().monospaced())
                Slider(value: $speedMultiplier, in: 0.1...10.0, step: 0.1)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear { if !didSetup { setupScene(); didSetup = true } }
        .onChange(of: speedMultiplier) { _, val in updateSpeed(val) }
    }

    // MARK: - Planet Definition

    private struct PlanetDef {
        let name: String
        let radius: CGFloat
        let distance: CGFloat
        let orbitDuration: TimeInterval
        let color: UIColor
        let hasMoon: Bool
    }

    private var planets: [PlanetDef] {
        [
            PlanetDef(name: "mercury", radius: 0.15, distance: 3.0, orbitDuration: 4, color: .systemGray, hasMoon: false),
            PlanetDef(name: "venus", radius: 0.25, distance: 4.5, orbitDuration: 7, color: .orange, hasMoon: false),
            PlanetDef(name: "earth", radius: 0.27, distance: 6.0, orbitDuration: 10, color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1), hasMoon: true),
            PlanetDef(name: "mars", radius: 0.2, distance: 7.5, orbitDuration: 14, color: UIColor(red: 0.85, green: 0.3, blue: 0.15, alpha: 1), hasMoon: false),
            PlanetDef(name: "jupiter", radius: 0.6, distance: 10.0, orbitDuration: 24, color: UIColor(red: 0.8, green: 0.6, blue: 0.3, alpha: 1), hasMoon: false),
        ]
    }

    // MARK: - Scene

    @MainActor
    private func setupScene() {
        scene.background.contents = UIColor.black

        let camera = SCNCamera()
        camera.fieldOfView = 60
        camera.zFar = 100
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(0, 15, 18)
        camNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camNode)

        // Sun
        let sunGeo = SCNSphere(radius: 1.2)
        let sunMat = SCNMaterial()
        sunMat.lightingModel = .constant
        sunMat.diffuse.contents = UIColor.yellow
        sunMat.emission.contents = UIColor(red: 1, green: 0.9, blue: 0.3, alpha: 1)
        sunGeo.materials = [sunMat]
        let sunNode = SCNNode(geometry: sunGeo)
        sunNode.name = "sun"
        scene.rootNode.addChildNode(sunNode)

        // Sun point light
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .omni
        sunLight.light?.intensity = 1200
        sunLight.light?.color = UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 1)
        scene.rootNode.addChildNode(sunLight)

        // Ambient
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 100
        scene.rootNode.addChildNode(ambient)

        // Planets
        for planet in planets {
            addPlanet(planet)
        }

        // Stars background
        addStarfield()
    }

    @MainActor
    private func addPlanet(_ def: PlanetDef) {
        // Orbit pivot node at origin
        let orbitNode = SCNNode()
        orbitNode.name = "orbit_\(def.name)"
        scene.rootNode.addChildNode(orbitNode)

        // Planet positioned at distance from orbit center
        let sphere = SCNSphere(radius: def.radius)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = def.color
        mat.roughness.contents = 0.6
        mat.metalness.contents = 0.1
        sphere.materials = [mat]

        let planetNode = SCNNode(geometry: sphere)
        planetNode.name = def.name
        planetNode.position = SCNVector3(Float(def.distance), 0, 0)
        orbitNode.addChildNode(planetNode)

        // Self-rotation
        let selfSpin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 3)
        planetNode.runAction(SCNAction.repeatForever(selfSpin), forKey: "selfSpin")

        // Orbit rotation
        let duration = def.orbitDuration / speedMultiplier
        let orbitAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)
        orbitNode.runAction(SCNAction.repeatForever(orbitAction), forKey: "orbit")

        // Orbit ring
        let ringGeo = SCNTorus(ringRadius: def.distance, pipeRadius: 0.015)
        let ringMat = SCNMaterial()
        ringMat.lightingModel = .constant
        ringMat.diffuse.contents = UIColor.white.withAlphaComponent(0.15)
        ringGeo.materials = [ringMat]
        let ringNode = SCNNode(geometry: ringGeo)
        scene.rootNode.addChildNode(ringNode)

        // Moon for Earth
        if def.hasMoon {
            let moonSphere = SCNSphere(radius: 0.08)
            let moonMat = SCNMaterial()
            moonMat.diffuse.contents = UIColor.lightGray
            moonMat.roughness.contents = 0.9
            moonSphere.materials = [moonMat]

            let moonOrbit = SCNNode()
            moonOrbit.name = "moonOrbit"
            planetNode.addChildNode(moonOrbit)

            let moonNode = SCNNode(geometry: moonSphere)
            moonNode.position = SCNVector3(Float(def.radius + 0.4), 0, 0)
            moonOrbit.addChildNode(moonNode)

            let moonAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.0 / speedMultiplier)
            moonOrbit.runAction(SCNAction.repeatForever(moonAction), forKey: "moonOrbit")
        }
    }

    @MainActor
    private func addStarfield() {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 0
        particleSystem.loops = false

        // Instead of particles, use small sphere nodes for stars
        for i in 0..<200 {
            let seed = Float(i)
            let theta = seed * 2.399_963 // golden angle
            let phi = acosf(1.0 - 2.0 * (seed + 0.5) / 200.0)
            let r: Float = 40.0

            let x = r * sinf(phi) * cosf(theta)
            let y = r * sinf(phi) * sinf(theta)
            let z = r * cosf(phi)

            let starGeo = SCNSphere(radius: 0.06)
            let starMat = SCNMaterial()
            starMat.lightingModel = .constant
            starMat.diffuse.contents = UIColor.white
            starGeo.materials = [starMat]

            let starNode = SCNNode(geometry: starGeo)
            starNode.position = SCNVector3(x, y, z)
            scene.rootNode.addChildNode(starNode)
        }
    }

    @MainActor
    private func updateSpeed(_ speed: Double) {
        for planet in planets {
            let orbitName = "orbit_\(planet.name)"
            guard let orbitNode = scene.rootNode.childNode(withName: orbitName, recursively: false) else { continue }
            orbitNode.removeAction(forKey: "orbit")
            let duration = planet.orbitDuration / speed
            let orbitAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)
            orbitNode.runAction(SCNAction.repeatForever(orbitAction), forKey: "orbit")

            // Update moon orbit too
            if planet.hasMoon,
               let planetNode = orbitNode.childNode(withName: planet.name, recursively: false),
               let moonOrbit = planetNode.childNode(withName: "moonOrbit", recursively: false) {
                moonOrbit.removeAction(forKey: "moonOrbit")
                let moonAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.0 / speed)
                moonOrbit.runAction(SCNAction.repeatForever(moonAction), forKey: "moonOrbit")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SolarSystemView()
            .navigationTitle("Solar System")
    }
}
