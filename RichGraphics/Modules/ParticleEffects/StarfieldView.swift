import SwiftUI
import UIKit

struct StarfieldView: View {
    @State private var warpSpeed: Float = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            StarfieldEmitterView(warpSpeed: warpSpeed)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "tortoise")
                            .foregroundStyle(.white.opacity(0.5))
                        Slider(value: $warpSpeed, in: 0.1...1.0)
                            .tint(.cyan)
                        Image(systemName: "hare")
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text("Warp Speed: \(Int(warpSpeed * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.cyan.opacity(0.8))
                }
                .padding(20)
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

struct StarfieldEmitterView: UIViewRepresentable {
    let warpSpeed: Float

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let emitterLayer = CAEmitterLayer()
        emitterLayer.name = "starfield"
        emitterLayer.renderMode = .additive
        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitterLayer = uiView.layer.sublayers?.first(where: { $0.name == "starfield" }) as? CAEmitterLayer else { return }

        let bounds = uiView.bounds
        guard bounds.width > 0 else { return }

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterShape = .point

        let baseVelocity: CGFloat = CGFloat(100 + 300 * warpSpeed)
        let baseBirthRate: Float = 20 + 80 * warpSpeed

        let whiteStar = makeStarCell(
            color: .white,
            birthRate: baseBirthRate,
            velocity: baseVelocity,
            scale: 0.02
        )

        let blueStar = makeStarCell(
            color: UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1),
            birthRate: baseBirthRate * 0.4,
            velocity: baseVelocity * 0.9,
            scale: 0.025
        )

        let yellowStar = makeStarCell(
            color: UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1),
            birthRate: baseBirthRate * 0.2,
            velocity: baseVelocity * 1.1,
            scale: 0.018
        )

        emitterLayer.emitterCells = [whiteStar, blueStar, yellowStar]
    }

    private func makeStarCell(color: UIColor, birthRate: Float, velocity: CGFloat, scale: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = birthRate
        cell.lifetime = 3.0
        cell.lifetimeRange = 1.0
        cell.velocity = velocity
        cell.velocityRange = velocity * 0.3
        cell.emissionRange = .pi * 2
        cell.scale = 0.001
        cell.scaleSpeed = scale * 1.5
        cell.alphaSpeed = -0.2
        cell.color = color.cgColor
        cell.contents = Self.makeStarGlow(color: color)
        return cell
    }

    private static func makeStarGlow(color: UIColor) -> CGImage? {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 8, y: 8), startRadius: 0,
                endCenter: CGPoint(x: 8, y: 8), endRadius: 8,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }
}

#Preview {
    StarfieldView()
}
