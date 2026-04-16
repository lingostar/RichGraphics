import SwiftUI
import UIKit

struct FireSmokeView: View {
    @State private var fireIntensity: Float = 0.6
    @State private var windEnabled = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            FireSmokeEmitterView(intensity: fireIntensity, windEnabled: windEnabled)
                .ignoresSafeArea()

            VStack {
                Spacer()

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

struct FireSmokeEmitterView: UIViewRepresentable {
    let intensity: Float
    let windEnabled: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let fireLayer = CAEmitterLayer()
        fireLayer.name = "fire"
        fireLayer.renderMode = .additive
        view.layer.addSublayer(fireLayer)

        let smokeLayer = CAEmitterLayer()
        smokeLayer.name = "smoke"
        view.layer.addSublayer(smokeLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let bounds = uiView.bounds
        guard bounds.width > 0 else { return }

        guard let fireLayer = uiView.layer.sublayers?.first(where: { $0.name == "fire" }) as? CAEmitterLayer,
              let smokeLayer = uiView.layer.sublayers?.first(where: { $0.name == "smoke" }) as? CAEmitterLayer else { return }

        configureFire(fireLayer, bounds: bounds)
        configureSmoke(smokeLayer, bounds: bounds)
    }

    private func configureFire(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY - 50)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: 80, height: 1)

        let windX: CGFloat = windEnabled ? 60 : 0

        let core = CAEmitterCell()
        core.birthRate = 100 * intensity
        core.lifetime = 1.0
        core.lifetimeRange = 0.3
        core.velocity = 80
        core.velocityRange = 30
        core.emissionLongitude = -.pi / 2
        core.emissionRange = .pi / 8
        core.scale = 0.08
        core.scaleSpeed = -0.04
        core.alphaSpeed = -0.8
        core.xAcceleration = windX
        core.contents = Self.makeGlowImage(color: .yellow)
        core.color = UIColor(red: 1, green: 0.6, blue: 0, alpha: 1).cgColor

        let outer = CAEmitterCell()
        outer.birthRate = 60 * intensity
        outer.lifetime = 1.5
        outer.lifetimeRange = 0.4
        outer.velocity = 100
        outer.velocityRange = 40
        outer.emissionLongitude = -.pi / 2
        outer.emissionRange = .pi / 5
        outer.scale = 0.1
        outer.scaleSpeed = -0.04
        outer.alphaSpeed = -0.5
        outer.xAcceleration = windX
        outer.contents = Self.makeGlowImage(color: .orange)
        outer.color = UIColor.red.cgColor
        outer.redRange = 0.2
        outer.greenRange = 0.1

        let sparks = CAEmitterCell()
        sparks.birthRate = 15 * intensity
        sparks.lifetime = 2.0
        sparks.lifetimeRange = 0.5
        sparks.velocity = 150
        sparks.velocityRange = 60
        sparks.emissionLongitude = -.pi / 2
        sparks.emissionRange = .pi / 4
        sparks.scale = 0.015
        sparks.scaleSpeed = -0.005
        sparks.alphaSpeed = -0.4
        sparks.yAcceleration = -20
        sparks.xAcceleration = windX * 1.5
        sparks.contents = Self.makeGlowImage(color: .yellow)

        layer.emitterCells = [core, outer, sparks]
    }

    private func configureSmoke(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY - 120)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: 60, height: 1)

        let windX: CGFloat = windEnabled ? 40 : 0

        let smoke = CAEmitterCell()
        smoke.birthRate = 8 * intensity
        smoke.lifetime = 6.0
        smoke.lifetimeRange = 2.0
        smoke.velocity = 30
        smoke.velocityRange = 15
        smoke.emissionLongitude = -.pi / 2
        smoke.emissionRange = .pi / 6
        smoke.scale = 0.1
        smoke.scaleSpeed = 0.04
        smoke.alphaSpeed = -0.12
        smoke.xAcceleration = windX
        smoke.color = UIColor(white: 0.4, alpha: 0.3).cgColor
        smoke.contents = Self.makeSmokeImage()

        layer.emitterCells = [smoke]
    }

    private static func makeGlowImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 10, y: 10), startRadius: 0,
                endCenter: CGPoint(x: 10, y: 10), endRadius: 10,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }

    private static func makeSmokeImage() -> CGImage? {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(white: 0.6, alpha: 0.4).cgColor,
                         UIColor(white: 0.6, alpha: 0).cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 32, y: 32), startRadius: 0,
                endCenter: CGPoint(x: 32, y: 32), endRadius: 32,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }
}

#Preview {
    FireSmokeView()
}
