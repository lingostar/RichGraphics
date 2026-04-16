import SwiftUI
import UIKit

struct WeatherView: View {
    enum WeatherType: String, CaseIterable, Identifiable {
        case snow = "Snow"
        case rain = "Rain"
        case cherryBlossom = "Cherry Blossom"

        var id: String { rawValue }
    }

    @State private var weatherType: WeatherType = .snow
    @State private var intensity: Float = 0.5

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            WeatherEmitterView(weatherType: weatherType, intensity: intensity)
                .ignoresSafeArea()
                .id(weatherType)

            VStack {
                Picker("Weather", selection: $weatherType) {
                    ForEach(WeatherType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 8) {
                    Text("Intensity: \(Int(intensity * 100))%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $intensity, in: 0.1...1.0)
                        .tint(.white)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
            .padding(.top, 10)
        }
    }

    private var backgroundGradient: some View {
        Group {
            switch weatherType {
            case .snow:
                LinearGradient(colors: [Color(white: 0.3), Color(white: 0.5)],
                               startPoint: .top, endPoint: .bottom)
            case .rain:
                LinearGradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.25),
                                        Color(red: 0.2, green: 0.2, blue: 0.3)],
                               startPoint: .top, endPoint: .bottom)
            case .cherryBlossom:
                LinearGradient(colors: [Color(red: 0.55, green: 0.75, blue: 0.95),
                                        Color(red: 0.7, green: 0.85, blue: 0.95)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
    }
}

struct WeatherEmitterView: UIViewRepresentable {
    let weatherType: WeatherView.WeatherType
    let intensity: Float

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let emitterLayer = CAEmitterLayer()
        emitterLayer.name = "weather"
        view.layer.addSublayer(emitterLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitterLayer = uiView.layer.sublayers?.first(where: { $0.name == "weather" }) as? CAEmitterLayer else { return }

        let bounds = uiView.bounds
        guard bounds.width > 0 else { return }

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.5, height: 1)

        switch weatherType {
        case .snow:
            configureSnow(emitterLayer)
        case .rain:
            configureRain(emitterLayer)
        case .cherryBlossom:
            configureCherryBlossom(emitterLayer)
        }
    }

    private func configureSnow(_ layer: CAEmitterLayer) {
        let baseBirthRate = 30 * intensity

        let small = CAEmitterCell()
        small.birthRate = baseBirthRate
        small.lifetime = 14
        small.velocity = 30
        small.velocityRange = 15
        small.emissionLongitude = .pi
        small.emissionRange = .pi / 6
        small.xAcceleration = 5
        small.scale = 0.02
        small.scaleRange = 0.01
        small.alphaRange = 0.3
        small.contents = Self.makeCircleImage(color: .white)

        let large = CAEmitterCell()
        large.birthRate = baseBirthRate * 0.3
        large.lifetime = 16
        large.velocity = 25
        large.velocityRange = 10
        large.emissionLongitude = .pi
        large.emissionRange = .pi / 8
        large.xAcceleration = 3
        large.scale = 0.05
        large.scaleRange = 0.02
        large.alphaRange = 0.2
        large.spin = 0.3
        large.spinRange = 0.6
        large.contents = Self.makeCircleImage(color: .white)

        layer.emitterCells = [small, large]
    }

    private func configureRain(_ layer: CAEmitterLayer) {
        let baseBirthRate = 80 * intensity

        let drop = CAEmitterCell()
        drop.birthRate = baseBirthRate
        drop.lifetime = 4
        drop.velocity = 400
        drop.velocityRange = 100
        drop.emissionLongitude = .pi
        drop.emissionRange = .pi / 30
        drop.scale = 0.06
        drop.scaleRange = 0.03
        drop.alphaRange = 0.3
        drop.contents = Self.makeRainDropImage()

        layer.emitterCells = [drop]
    }

    private func configureCherryBlossom(_ layer: CAEmitterLayer) {
        let baseBirthRate = 12 * intensity

        let petal = CAEmitterCell()
        petal.birthRate = baseBirthRate
        petal.lifetime = 12
        petal.lifetimeRange = 3
        petal.velocity = 25
        petal.velocityRange = 15
        petal.emissionLongitude = .pi
        petal.emissionRange = .pi / 4
        petal.xAcceleration = 8
        petal.spin = 1.5
        petal.spinRange = 3.0
        petal.scale = 0.06
        petal.scaleRange = 0.03
        petal.alphaSpeed = -0.05
        petal.contents = Self.makePetalImage()

        let smallPetal = CAEmitterCell()
        smallPetal.birthRate = baseBirthRate * 0.5
        smallPetal.lifetime = 10
        smallPetal.velocity = 20
        smallPetal.velocityRange = 10
        smallPetal.emissionLongitude = .pi
        smallPetal.emissionRange = .pi / 3
        smallPetal.xAcceleration = 12
        smallPetal.spin = 2.0
        smallPetal.spinRange = 4.0
        smallPetal.scale = 0.03
        smallPetal.scaleRange = 0.015
        smallPetal.alphaSpeed = -0.06
        smallPetal.contents = Self.makePetalImage()

        layer.emitterCells = [petal, smallPetal]
    }

    private static func makeCircleImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }.cgImage
    }

    private static func makeRainDropImage() -> CGImage? {
        let size = CGSize(width: 3, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.8).cgColor,
                         UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.2).cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 1.5, y: 0),
                end: CGPoint(x: 1.5, y: 16),
                options: []
            )
        }.cgImage
    }

    private static func makePetalImage() -> CGImage? {
        let size = CGSize(width: 16, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let pink = UIColor(red: 1.0, green: 0.7, blue: 0.78, alpha: 0.9)
            pink.setFill()
            let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            path.fill()
        }.cgImage
    }
}

#Preview {
    WeatherView()
}
