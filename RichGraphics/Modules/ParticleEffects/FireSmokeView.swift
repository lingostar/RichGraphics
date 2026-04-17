import SwiftUI
import UIKit

struct FireSmokeView: View {
    @State private var fireIntensity: Float = 0.6
    @State private var windEnabled = false

    var body: some View {
        ZStack {
            // Dark gradient background (slight warmth near bottom)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.05, blue: 0.02),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            FireSmokeEmitterView(intensity: fireIntensity, windEnabled: windEnabled)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Tap anywhere to throw a log 🪵")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 8)

                VStack(spacing: 16) {
                    HStack {
                        Text("Fire Intensity")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(fireIntensity * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    Slider(value: $fireIntensity, in: 0.1...1.0)
                        .tint(.orange)

                    Toggle(isOn: $windEnabled) {
                        HStack {
                            Image(systemName: "wind")
                            Text("Wind")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    .tint(.orange)
                }
                .padding(20)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Emitter (UIViewRepresentable)

struct FireSmokeEmitterView: UIViewRepresentable {
    let intensity: Float
    let windEnabled: Bool

    func makeUIView(context: Context) -> FireSmokeUIView {
        let view = FireSmokeUIView()
        view.backgroundColor = .clear
        view.intensity = intensity
        view.windEnabled = windEnabled
        return view
    }

    func updateUIView(_ uiView: FireSmokeUIView, context: Context) {
        uiView.intensity = intensity
        uiView.windEnabled = windEnabled
        uiView.refresh()
    }
}

// MARK: - Custom UIView

final class FireSmokeUIView: UIView {
    var intensity: Float = 0.6
    var windEnabled: Bool = false

    private let fireLayer = CAEmitterLayer()
    private let smokeLayer = CAEmitterLayer()
    private let glowLayer = CALayer()

    private var configuredWidth: CGFloat = 0
    private var configuredIntensity: Float = -1
    private var configuredWind: Bool?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        // Soft glow halo behind fire (very subtle ambient light)
        glowLayer.contents = Self.makeHaloImage()?.cgImage
        glowLayer.opacity = 0.25
        glowLayer.compositingFilter = "screenBlendMode"
        layer.addSublayer(glowLayer)

        // Smoke layer (behind fire in z-order)
        smokeLayer.renderMode = .unordered
        layer.addSublayer(smokeLayer)

        // Fire layer (additive → brighter overlapping = hotter)
        fireLayer.renderMode = .additive
        layer.addSublayer(fireLayer)

        // Tap gesture — "throw a log" to boost fire briefly
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Briefly boost the fire: increase birthRate for ~0.8s
        guard let cells = fireLayer.emitterCells, !cells.isEmpty else { return }
        let originalRates = cells.map { $0.birthRate }
        for cell in cells {
            cell.birthRate *= 3.5
        }
        // Pulse the halo too
        let haloPulse = CABasicAnimation(keyPath: "opacity")
        haloPulse.fromValue = glowLayer.opacity * 2.5
        haloPulse.toValue = glowLayer.opacity
        haloPulse.duration = 0.8
        haloPulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        glowLayer.add(haloPulse, forKey: "pulse")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, let currentCells = self.fireLayer.emitterCells else { return }
            for (i, cell) in currentCells.enumerated() where i < originalRates.count {
                cell.birthRate = originalRates[i]
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refresh()
    }

    func refresh() {
        guard bounds.width > 0 else { return }

        let needsReconfig = configuredWidth != bounds.width
            || abs(configuredIntensity - intensity) > 0.001
            || configuredWind != windEnabled

        guard needsReconfig else { return }

        let baseY = bounds.maxY - 250    // where the fire sits (above the controls)
        let midX = bounds.midX

        // Subtle halo behind fire (smaller + lower opacity)
        let haloSize: CGFloat = 220
        glowLayer.frame = CGRect(
            x: midX - haloSize / 2,
            y: baseY - haloSize / 2 - 30,
            width: haloSize,
            height: haloSize
        )
        glowLayer.opacity = 0.15 + 0.2 * Float(intensity)

        // Fire layer positioning
        fireLayer.frame = bounds
        fireLayer.emitterPosition = CGPoint(x: midX, y: baseY)
        fireLayer.emitterShape = .line
        fireLayer.emitterSize = CGSize(width: 90, height: 4)
        fireLayer.emitterCells = Self.fireCells(intensity: intensity, windEnabled: windEnabled)

        // Smoke layer positioning (higher up than fire)
        smokeLayer.frame = bounds
        smokeLayer.emitterPosition = CGPoint(x: midX, y: baseY - 120)
        smokeLayer.emitterShape = .line
        smokeLayer.emitterSize = CGSize(width: 60, height: 1)
        smokeLayer.emitterCells = Self.smokeCells(intensity: intensity, windEnabled: windEnabled)

        configuredWidth = bounds.width
        configuredIntensity = intensity
        configuredWind = windEnabled
    }

    // MARK: - Fire cells (4 layers: base core → body → flicker → sparks)

    private static func fireCells(intensity: Float, windEnabled: Bool) -> [CAEmitterCell] {
        let glow = makeFlameImage()
        let sparkImg = makeSparkImage()
        let windX: CGFloat = windEnabled ? 80 : 0
        let windXRange: CGFloat = windEnabled ? 30 : 15

        // BASE CORE: hottest, bright white-yellow at the base
        let core = CAEmitterCell()
        core.birthRate = 80 * intensity
        core.lifetime = 0.6
        core.lifetimeRange = 0.2
        core.velocity = 120
        core.velocityRange = 40
        core.emissionLongitude = -.pi / 2    // upward
        core.emissionRange = .pi / 10
        core.yAcceleration = -100            // pulls it upward faster (buoyancy)
        core.xAcceleration = windX
        core.scale = 0.9
        core.scaleRange = 0.2
        core.scaleSpeed = -0.6
        core.alphaSpeed = -1.5
        core.color = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0).cgColor
        core.redRange = 0.1
        core.greenRange = 0.1
        core.contents = glow

        // BODY: bright orange, main flame body
        let body = CAEmitterCell()
        body.birthRate = 60 * intensity
        body.lifetime = 1.0
        body.lifetimeRange = 0.3
        body.velocity = 150
        body.velocityRange = 60
        body.emissionLongitude = -.pi / 2
        body.emissionRange = .pi / 7
        body.yAcceleration = -80
        body.xAcceleration = windX
        body.scale = 1.1
        body.scaleRange = 0.3
        body.scaleSpeed = -0.3
        body.alphaSpeed = -0.9
        body.color = UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0).cgColor
        body.redRange = 0.1
        body.greenRange = 0.2
        // Color shifts: cools toward red over time
        body.greenSpeed = -0.3
        body.contents = glow

        // OUTER FLICKER: dim red/orange, spreads wider
        let flicker = CAEmitterCell()
        flicker.birthRate = 40 * intensity
        flicker.lifetime = 1.4
        flicker.lifetimeRange = 0.4
        flicker.velocity = 90
        flicker.velocityRange = 50
        flicker.emissionLongitude = -.pi / 2
        flicker.emissionRange = .pi / 5
        flicker.yAcceleration = -50
        flicker.xAcceleration = windX
        flicker.scale = 1.3
        flicker.scaleRange = 0.4
        flicker.scaleSpeed = 0.1
        flicker.alphaSpeed = -0.6
        flicker.color = UIColor(red: 0.9, green: 0.25, blue: 0.05, alpha: 0.8).cgColor
        flicker.redRange = 0.1
        flicker.greenRange = 0.1
        flicker.contents = glow

        // SPARKS: tiny bright dots jumping high
        let sparks = CAEmitterCell()
        sparks.birthRate = 25 * intensity
        sparks.lifetime = 2.5
        sparks.lifetimeRange = 0.8
        sparks.velocity = 240
        sparks.velocityRange = 100
        sparks.emissionLongitude = -.pi / 2
        sparks.emissionRange = .pi / 4
        sparks.yAcceleration = -40
        sparks.xAcceleration = windX * 1.5
        sparks.scale = 0.08
        sparks.scaleRange = 0.04
        sparks.scaleSpeed = -0.02
        sparks.alphaSpeed = -0.4
        sparks.color = UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0).cgColor
        sparks.contents = sparkImg

        return [flicker, body, core, sparks]
    }

    // MARK: - Smoke cells

    private static func smokeCells(intensity: Float, windEnabled: Bool) -> [CAEmitterCell] {
        let img = makeSmokeImage()
        let windX: CGFloat = windEnabled ? 50 : 0

        // Dark smoke (denser, closer)
        let dark = CAEmitterCell()
        dark.birthRate = 8 * intensity
        dark.lifetime = 6.0
        dark.lifetimeRange = 2.0
        dark.velocity = 50
        dark.velocityRange = 20
        dark.emissionLongitude = -.pi / 2
        dark.emissionRange = .pi / 5
        dark.xAcceleration = windX
        dark.scale = 0.6
        dark.scaleRange = 0.2
        dark.scaleSpeed = 0.35
        dark.alphaSpeed = -0.15
        dark.alphaRange = 0.1
        dark.spin = 0.2
        dark.spinRange = 0.4
        dark.color = UIColor(white: 0.25, alpha: 0.45).cgColor
        dark.contents = img

        // Light smoke (wispier, wider)
        let light = CAEmitterCell()
        light.birthRate = 5 * intensity
        light.lifetime = 8.0
        light.lifetimeRange = 2.0
        light.velocity = 40
        light.velocityRange = 15
        light.emissionLongitude = -.pi / 2
        light.emissionRange = .pi / 4
        light.xAcceleration = windX * 1.2
        light.scale = 0.9
        light.scaleRange = 0.3
        light.scaleSpeed = 0.25
        light.alphaSpeed = -0.1
        light.spin = 0.15
        light.spinRange = 0.3
        light.color = UIColor(white: 0.45, alpha: 0.28).cgColor
        light.contents = img

        return [dark, light]
    }

    // MARK: - Particle images

    private static func makeFlameImage() -> CGImage? {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Soft radial gradient: solid center → transparent edge
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 1.0).cgColor,
                    UIColor(white: 1.0, alpha: 0.7).cgColor,
                    UIColor(white: 1.0, alpha: 0.2).cgColor,
                    UIColor(white: 1.0, alpha: 0.0).cgColor,
                ] as CFArray,
                locations: [0, 0.3, 0.7, 1]
            )!
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: size.width / 2,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }

    private static func makeSparkImage() -> CGImage? {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.cgColor,
                    UIColor(white: 1, alpha: 0).cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            let center = CGPoint(x: 8, y: 8)
            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: 8,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }

    private static func makeSmokeImage() -> CGImage? {
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1, alpha: 0.6).cgColor,
                    UIColor(white: 1, alpha: 0.3).cgColor,
                    UIColor(white: 1, alpha: 0).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            )!
            let center = CGPoint(x: 64, y: 64)
            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: 64,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }

    private static func makeHaloImage() -> UIImage? {
        let size = CGSize(width: 220, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 0.18).cgColor,
                    UIColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 0.06).cgColor,
                    UIColor(red: 0.5, green: 0.1, blue: 0.0, alpha: 0.0).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            )!
            let center = CGPoint(x: 110, y: 110)
            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: 110,
                options: .drawsBeforeStartLocation
            )
        }
    }
}

#Preview {
    FireSmokeView()
}
