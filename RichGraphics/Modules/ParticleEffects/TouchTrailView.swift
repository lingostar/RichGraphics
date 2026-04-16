import SwiftUI
import UIKit

struct TouchTrailView: View {
    enum TrailColor: String, CaseIterable, Identifiable {
        case rainbow = "Rainbow"
        case fire = "Fire"
        case ice = "Ice"
        case gold = "Gold"

        var id: String { rawValue }
    }

    @State private var trailColor: TrailColor = .rainbow

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TouchTrailEmitterView(trailColor: trailColor)
                .ignoresSafeArea()

            VStack {
                Picker("Color", selection: $trailColor) {
                    ForEach(TrailColor.allCases) { color in
                        Text(color.rawValue).tag(color)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                Text("Drag your finger across the screen")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
    }
}

struct TouchTrailEmitterView: UIViewRepresentable {
    let trailColor: TouchTrailView.TrailColor

    func makeUIView(context: Context) -> TouchTrailUIView {
        let view = TouchTrailUIView()
        view.trailColor = trailColor
        return view
    }

    func updateUIView(_ uiView: TouchTrailUIView, context: Context) {
        uiView.trailColor = trailColor
        uiView.updateEmitterColors()
    }
}

@MainActor
final class TouchTrailUIView: UIView {
    var trailColor: TouchTrailView.TrailColor = .rainbow

    private let emitterLayer = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false

        emitterLayer.name = "trail"
        emitterLayer.renderMode = .additive
        emitterLayer.birthRate = 0
        layer.addSublayer(emitterLayer)

        setupEmitter()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEmitter() {
        emitterLayer.emitterShape = .point
        updateEmitterColors()
    }

    func updateEmitterColors() {
        let colors = colorsForTrail(trailColor)

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 80
            cell.lifetime = 1.2
            cell.lifetimeRange = 0.4
            cell.velocity = 30
            cell.velocityRange = 20
            cell.emissionRange = .pi * 2
            cell.scale = 0.04
            cell.scaleSpeed = -0.02
            cell.alphaSpeed = -0.7
            cell.contents = Self.makeGlowImage(color: color)
            cells.append(cell)
        }

        // Extra sparkle
        let sparkle = CAEmitterCell()
        sparkle.birthRate = 20
        sparkle.lifetime = 0.6
        sparkle.lifetimeRange = 0.2
        sparkle.velocity = 60
        sparkle.velocityRange = 30
        sparkle.emissionRange = .pi * 2
        sparkle.scale = 0.015
        sparkle.scaleSpeed = -0.02
        sparkle.alphaSpeed = -1.2
        sparkle.contents = Self.makeGlowImage(color: .white)
        cells.append(sparkle)

        emitterLayer.emitterCells = cells
    }

    private func colorsForTrail(_ trail: TouchTrailView.TrailColor) -> [UIColor] {
        switch trail {
        case .rainbow:
            return [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemCyan, .systemBlue, .systemPurple]
        case .fire:
            return [.red, .orange, .yellow, UIColor(red: 1, green: 0.3, blue: 0, alpha: 1)]
        case .ice:
            return [.cyan, .systemBlue, .white, UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)]
        case .gold:
            return [.yellow, .orange, UIColor(red: 1, green: 0.84, blue: 0, alpha: 1),
                    UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1)]
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        emitterLayer.emitterPosition = point
        emitterLayer.birthRate = 1
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        emitterLayer.emitterPosition = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        emitterLayer.birthRate = 0
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        emitterLayer.birthRate = 0
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
}

#Preview {
    TouchTrailView()
}
