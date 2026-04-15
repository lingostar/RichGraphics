import SwiftUI
import UIKit

struct ParticleEffectsView: View {
    @State private var selectedEffect: ParticleEffect = .confetti

    enum ParticleEffect: String, CaseIterable, Identifiable {
        case confetti = "Confetti"
        case snow = "Snow"
        case fire = "Fire"
        case stars = "Stars"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black

                ParticleEmitterView(effect: selectedEffect)
                    .id(selectedEffect)

                VStack {
                    Spacer()
                    Text(selectedEffect.rawValue)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                    Spacer()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ParticleEffect.allCases) { effect in
                        Button {
                            selectedEffect = effect
                        } label: {
                            Text(effect.rawValue)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedEffect == effect ? Color.red : Color(.systemGray5))
                                .foregroundStyle(selectedEffect == effect ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct ParticleEmitterView: UIViewRepresentable {
    let effect: ParticleEffectsView.ParticleEffect

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let emitterLayer = CAEmitterLayer()
        emitterLayer.name = "emitter"
        view.layer.addSublayer(emitterLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitterLayer = uiView.layer.sublayers?.first(where: { $0.name == "emitter" }) as? CAEmitterLayer else { return }

        let bounds = uiView.bounds
        guard bounds.width > 0 else { return }

        switch effect {
        case .confetti:
            configureConfetti(emitterLayer, bounds: bounds)
        case .snow:
            configureSnow(emitterLayer, bounds: bounds)
        case .fire:
            configureFire(emitterLayer, bounds: bounds)
        case .stars:
            configureStars(emitterLayer, bounds: bounds)
        }
    }

    private func configureConfetti(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: bounds.width, height: 1)

        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemOrange, .systemPink, .systemPurple]
        layer.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 8
            cell.velocity = 120
            cell.velocityRange = 60
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 4
            cell.spinRange = 8
            cell.scale = 0.04
            cell.scaleRange = 0.02
            cell.contents = makeSquareImage(color: color)
            return cell
        }
    }

    private func configureSnow(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: bounds.width * 1.5, height: 1)

        let cell = CAEmitterCell()
        cell.birthRate = 30
        cell.lifetime = 12
        cell.velocity = 40
        cell.velocityRange = 20
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.spin = 0.5
        cell.spinRange = 1
        cell.scale = 0.03
        cell.scaleRange = 0.02
        cell.alphaSpeed = -0.05
        cell.contents = makeCircleImage(color: .white)

        layer.emitterCells = [cell]
    }

    private func configureFire(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY - 40)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: 80, height: 1)

        let flame = CAEmitterCell()
        flame.birthRate = 80
        flame.lifetime = 2.5
        flame.velocity = 80
        flame.velocityRange = 30
        flame.emissionLongitude = -.pi / 2
        flame.emissionRange = .pi / 6
        flame.scale = 0.06
        flame.scaleSpeed = -0.02
        flame.alphaSpeed = -0.4
        flame.contents = makeCircleImage(color: .orange)
        flame.color = UIColor.red.cgColor
        flame.greenRange = 0.3
        flame.redRange = 0.1

        layer.emitterCells = [flame]
    }

    private func configureStars(_ layer: CAEmitterLayer, bounds: CGRect) {
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.emitterShape = .rectangle
        layer.emitterSize = bounds.size

        let star = CAEmitterCell()
        star.birthRate = 3
        star.lifetime = 5
        star.velocity = 0
        star.scale = 0.02
        star.scaleRange = 0.02
        star.alphaRange = 0.5
        star.alphaSpeed = -0.1
        star.contents = makeStarImage(color: .white)

        let twinkle = CAEmitterCell()
        twinkle.birthRate = 5
        twinkle.lifetime = 3
        twinkle.velocity = 0
        twinkle.scale = 0.01
        twinkle.scaleRange = 0.01
        twinkle.alphaRange = 0.8
        twinkle.alphaSpeed = -0.2
        twinkle.contents = makeCircleImage(color: .yellow)

        layer.emitterCells = [star, twinkle]
    }

    private func makeSquareImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }.cgImage
    }

    private func makeCircleImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }.cgImage
    }

    private func makeStarImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let center = CGPoint(x: 10, y: 10)
            let path = UIBezierPath()
            let points = 5
            let outerRadius: CGFloat = 10
            let innerRadius: CGFloat = 4
            for i in 0..<(points * 2) {
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
                let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.close()
            color.setFill()
            path.fill()
        }.cgImage
    }
}

#Preview {
    NavigationStack {
        ParticleEffectsView()
            .navigationTitle("Particle Effects")
    }
}
