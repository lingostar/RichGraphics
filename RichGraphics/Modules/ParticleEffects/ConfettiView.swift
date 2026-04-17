import SwiftUI
import UIKit

struct ConfettiView: View {
    @State private var triggerBurst = false
    @State private var continuousMode = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.15),
                                    Color(red: 0.15, green: 0.1, blue: 0.2)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ConfettiEmitterView(triggerBurst: $triggerBurst, continuousMode: continuousMode)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Button {
                        triggerBurst = true
                    } label: {
                        Text("Celebrate!")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.purple, .pink],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Toggle(isOn: $continuousMode) {
                        Text("Continuous Mode")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .tint(.purple)
                }
                .padding(20)
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

struct ConfettiEmitterView: UIViewRepresentable {
    @Binding var triggerBurst: Bool
    let continuousMode: Bool

    func makeUIView(context: Context) -> ConfettiUIView {
        let view = ConfettiUIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
        uiView.continuousMode = continuousMode
        uiView.refreshIfNeeded()

        if triggerBurst {
            uiView.celebrate()
            DispatchQueue.main.async {
                self.triggerBurst = false
            }
        }
    }
}

final class ConfettiUIView: UIView {
    var continuousMode: Bool = false {
        didSet {
            if continuousMode != oldValue {
                emitterLayer.birthRate = continuousMode ? 1 : 0
            }
        }
    }

    private let emitterLayer = CAEmitterLayer()
    private var configuredWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        emitterLayer.birthRate = 0
        layer.addSublayer(emitterLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        emitterLayer.birthRate = 0
        layer.addSublayer(emitterLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        guard bounds.width > 0, configuredWidth != bounds.width else { return }

        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
        emitterLayer.renderMode = .unordered
        emitterLayer.emitterCells = Self.makeCells()
        emitterLayer.birthRate = continuousMode ? 1 : 0

        configuredWidth = bounds.width
    }

    /// Trigger a burst: short dense spawn, then stop
    func celebrate() {
        emitterLayer.birthRate = 2.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.emitterLayer.birthRate = self.continuousMode ? 1 : 0
        }
    }

    private static func makeCells() -> [CAEmitterCell] {
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow,
                                 .systemOrange, .systemPink, .systemPurple, .cyan,
                                 .magenta, .systemTeal]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let rectImg = makeRectImage(color: color)
            let circleImg = makeCircleImage(color: color)

            // Rectangle confetti (tumbling)
            let rect = CAEmitterCell()
            rect.birthRate = 3
            rect.lifetime = 5
            rect.lifetimeRange = 1.5
            rect.velocity = 220
            rect.velocityRange = 80
            rect.emissionLongitude = .pi
            rect.emissionRange = .pi / 4
            rect.spin = 4
            rect.spinRange = 8
            rect.scale = 0.4
            rect.scaleRange = 0.15
            rect.yAcceleration = 120
            rect.alphaSpeed = -0.2
            rect.contents = rectImg
            cells.append(rect)

            // Circle confetti (smaller, accent)
            let circle = CAEmitterCell()
            circle.birthRate = 1.5
            circle.lifetime = 5
            circle.lifetimeRange = 1.5
            circle.velocity = 200
            circle.velocityRange = 60
            circle.emissionLongitude = .pi
            circle.emissionRange = .pi / 3
            circle.spin = 3
            circle.spinRange = 6
            circle.scale = 0.3
            circle.scaleRange = 0.1
            circle.yAcceleration = 110
            circle.alphaSpeed = -0.2
            circle.contents = circleImg
            cells.append(circle)
        }
        return cells
    }

    private static func makeRectImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 18, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2).fill()
        }.cgImage
    }

    private static func makeCircleImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 14, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }.cgImage
    }
}

#Preview {
    ConfettiView()
}
