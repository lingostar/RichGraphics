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

    func makeUIView(context: Context) -> StarfieldUIView {
        let view = StarfieldUIView()
        view.backgroundColor = .clear
        view.warpSpeed = warpSpeed
        return view
    }

    func updateUIView(_ uiView: StarfieldUIView, context: Context) {
        uiView.warpSpeed = warpSpeed
        uiView.refreshIfNeeded()
    }
}

final class StarfieldUIView: UIView {
    var warpSpeed: Float = 0.5

    private let emitterLayer = CAEmitterLayer()
    private var configuredSize: CGSize = .zero
    private var configuredWarpSpeed: Float = -1

    override init(frame: CGRect) {
        super.init(frame: frame)
        emitterLayer.renderMode = .additive
        layer.addSublayer(emitterLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        emitterLayer.renderMode = .additive
        layer.addSublayer(emitterLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        guard bounds.width > 0 else { return }
        let sameSize = configuredSize == bounds.size
        let sameSpeed = abs(configuredWarpSpeed - warpSpeed) < 0.001
        guard !(sameSize && sameSpeed) else { return }

        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterShape = .point

        let baseVelocity: CGFloat = CGFloat(150 + 450 * warpSpeed)
        let baseBirthRate: Float = 30 + 120 * warpSpeed

        let whiteStar = Self.makeStarCell(
            color: .white,
            birthRate: baseBirthRate,
            velocity: baseVelocity,
            finalScale: 0.8
        )

        let blueStar = Self.makeStarCell(
            color: UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1),
            birthRate: baseBirthRate * 0.4,
            velocity: baseVelocity * 0.9,
            finalScale: 1.0
        )

        let yellowStar = Self.makeStarCell(
            color: UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1),
            birthRate: baseBirthRate * 0.2,
            velocity: baseVelocity * 1.1,
            finalScale: 0.7
        )

        emitterLayer.emitterCells = [whiteStar, blueStar, yellowStar]

        configuredSize = bounds.size
        configuredWarpSpeed = warpSpeed
    }

    private static func makeStarCell(
        color: UIColor,
        birthRate: Float,
        velocity: CGFloat,
        finalScale: CGFloat
    ) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = birthRate
        cell.lifetime = 3.0
        cell.lifetimeRange = 1.0
        cell.velocity = velocity
        cell.velocityRange = velocity * 0.3
        cell.emissionRange = .pi * 2
        // Start tiny, grow over lifetime → warp-speed feel
        cell.scale = 0.02
        cell.scaleSpeed = Float(finalScale) / 3.0
        cell.alphaRange = 0.3
        cell.color = color.cgColor
        cell.contents = makeStarGlow(color: color)
        return cell
    }

    private static func makeStarGlow(color: UIColor) -> CGImage? {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    color.cgColor,
                    color.withAlphaComponent(0.6).cgColor,
                    color.withAlphaComponent(0).cgColor,
                ] as CFArray,
                locations: [0, 0.4, 1]
            )!
            let center = CGPoint(x: 16, y: 16)
            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: 16,
                options: .drawsBeforeStartLocation
            )
        }.cgImage
    }
}

#Preview {
    StarfieldView()
}
