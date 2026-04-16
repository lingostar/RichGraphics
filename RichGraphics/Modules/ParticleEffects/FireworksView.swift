import SwiftUI
import UIKit

struct FireworksView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FireworksEmitterView()
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            Text("Tap anywhere to launch fireworks")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 40)
        }
    }
}

struct FireworksEmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> FireworksUIView {
        FireworksUIView()
    }

    func updateUIView(_ uiView: FireworksUIView, context: Context) {}
}

@MainActor
final class FireworksUIView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: self)
        launchFirework(to: tapPoint)
    }

    private func launchFirework(to destination: CGPoint) {
        let launchOrigin = CGPoint(x: destination.x, y: bounds.maxY + 10)

        // Stage 1: Trail rising
        let trailLayer = CAEmitterLayer()
        trailLayer.emitterPosition = launchOrigin
        trailLayer.emitterShape = .point
        trailLayer.renderMode = .additive

        let trailCell = CAEmitterCell()
        trailCell.birthRate = 120
        trailCell.lifetime = 0.4
        trailCell.velocity = 0
        trailCell.scale = 0.04
        trailCell.scaleSpeed = -0.05
        trailCell.alphaSpeed = -2.0
        trailCell.emissionRange = .pi * 2
        trailCell.contents = Self.makeGlowImage(color: .white)

        trailLayer.emitterCells = [trailCell]
        layer.addSublayer(trailLayer)

        // Animate the trail position rising
        let riseDuration: CFTimeInterval = 0.6
        let riseAnimation = CABasicAnimation(keyPath: "emitterPosition")
        riseAnimation.fromValue = NSValue(cgPoint: launchOrigin)
        riseAnimation.toValue = NSValue(cgPoint: destination)
        riseAnimation.duration = riseDuration
        riseAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        riseAnimation.isRemovedOnCompletion = false
        riseAnimation.fillMode = .forwards
        trailLayer.add(riseAnimation, forKey: "rise")

        // Stage 2: Explosion after rise
        DispatchQueue.main.asyncAfter(deadline: .now() + riseDuration) { [weak self] in
            trailLayer.birthRate = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                trailLayer.removeFromSuperlayer()
            }

            self?.createExplosion(at: destination)
        }
    }

    private func createExplosion(at point: CGPoint) {
        let explosionLayer = CAEmitterLayer()
        explosionLayer.emitterPosition = point
        explosionLayer.emitterShape = .point
        explosionLayer.renderMode = .additive

        let colors: [UIColor] = [.systemRed, .yellow, .systemBlue, .systemGreen, .white,
                                  .orange, .magenta, .cyan]
        let chosenColors = colors.shuffled().prefix(4)

        var cells: [CAEmitterCell] = []
        for color in chosenColors {
            let cell = CAEmitterCell()
            cell.birthRate = 200
            cell.lifetime = 1.5
            cell.lifetimeRange = 0.5
            cell.velocity = 200
            cell.velocityRange = 80
            cell.emissionRange = .pi * 2
            cell.scale = 0.04
            cell.scaleSpeed = -0.02
            cell.alphaSpeed = -0.6
            cell.yAcceleration = 120
            cell.contents = Self.makeGlowImage(color: color)
            cells.append(cell)
        }

        explosionLayer.emitterCells = cells
        layer.addSublayer(explosionLayer)

        // Stop emission after a brief burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            explosionLayer.birthRate = 0
        }

        // Remove layer after particles fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            explosionLayer.removeFromSuperlayer()
        }
    }

    private static func makeGlowImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
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
            _ = rect
        }.cgImage
    }
}

#Preview {
    FireworksView()
}
