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

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let emitterLayer = CAEmitterLayer()
        emitterLayer.name = "confetti"
        emitterLayer.birthRate = 0
        view.layer.addSublayer(emitterLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitterLayer = uiView.layer.sublayers?.first(where: { $0.name == "confetti" }) as? CAEmitterLayer else { return }

        let bounds = uiView.bounds
        guard bounds.width > 0 else { return }

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)

        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow,
                                  .systemOrange, .systemPink, .systemPurple, .cyan,
                                  .magenta, .systemTeal]

        var cells: [CAEmitterCell] = []
        for color in colors {
            let rect = CAEmitterCell()
            rect.birthRate = 4
            rect.lifetime = 8
            rect.lifetimeRange = 2
            rect.velocity = 150
            rect.velocityRange = 60
            rect.emissionLongitude = .pi
            rect.emissionRange = .pi / 4
            rect.spin = 3
            rect.spinRange = 6
            rect.scale = 0.04
            rect.scaleRange = 0.02
            rect.yAcceleration = 40
            rect.contents = Self.makeRectImage(color: color)
            cells.append(rect)

            let circle = CAEmitterCell()
            circle.birthRate = 2
            circle.lifetime = 8
            circle.lifetimeRange = 2
            circle.velocity = 130
            circle.velocityRange = 50
            circle.emissionLongitude = .pi
            circle.emissionRange = .pi / 3
            circle.spin = 2
            circle.spinRange = 4
            circle.scale = 0.03
            circle.scaleRange = 0.015
            circle.yAcceleration = 35
            circle.contents = Self.makeCircleImage(color: color)
            cells.append(circle)
        }

        emitterLayer.emitterCells = cells

        if continuousMode {
            emitterLayer.birthRate = 1
        } else if triggerBurst {
            emitterLayer.birthRate = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emitterLayer.birthRate = 0
            }
            DispatchQueue.main.async {
                self.triggerBurst = false
            }
        } else {
            emitterLayer.birthRate = 0
        }
    }

    private static func makeRectImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 12, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }.cgImage
    }

    private static func makeCircleImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 10, height: 10)
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
