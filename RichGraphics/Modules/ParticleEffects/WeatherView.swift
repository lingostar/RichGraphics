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
                LinearGradient(colors: [Color(white: 0.15), Color(white: 0.35)],
                               startPoint: .top, endPoint: .bottom)
            case .rain:
                LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.18),
                                        Color(red: 0.12, green: 0.14, blue: 0.22)],
                               startPoint: .top, endPoint: .bottom)
            case .cherryBlossom:
                LinearGradient(colors: [Color(red: 0.55, green: 0.75, blue: 0.95),
                                        Color(red: 0.7, green: 0.85, blue: 0.95)],
                               startPoint: .top, endPoint: .bottom)
            }
        }
    }
}

// MARK: - Emitter View (UIViewRepresentable)

struct WeatherEmitterView: UIViewRepresentable {
    let weatherType: WeatherView.WeatherType
    let intensity: Float

    func makeUIView(context: Context) -> WeatherEmitterUIView {
        let view = WeatherEmitterUIView()
        view.backgroundColor = .clear
        view.weatherType = weatherType
        view.intensity = intensity
        return view
    }

    func updateUIView(_ uiView: WeatherEmitterUIView, context: Context) {
        uiView.weatherType = weatherType
        uiView.intensity = intensity
        uiView.refreshIfNeeded()
    }
}

// MARK: - Custom UIView that configures emitter on layout

final class WeatherEmitterUIView: UIView {
    var weatherType: WeatherView.WeatherType = .snow
    var intensity: Float = 0.5

    private let emitterLayer = CAEmitterLayer()
    private var configuredBoundsWidth: CGFloat = 0
    private var configuredWeatherType: WeatherView.WeatherType?
    private var configuredIntensity: Float = -1

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(emitterLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(emitterLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        refreshIfNeeded()
    }

    func refreshIfNeeded() {
        guard bounds.width > 0 else { return }
        // Avoid re-configuring if nothing meaningful changed
        let needsReconfig = configuredBoundsWidth != bounds.width
            || configuredWeatherType != weatherType
            || abs(configuredIntensity - intensity) > 0.001

        guard needsReconfig else { return }

        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -30)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.3, height: 1)
        emitterLayer.renderMode = .unordered

        switch weatherType {
        case .snow:
            emitterLayer.emitterCells = Self.snowCells(intensity: intensity)
        case .rain:
            emitterLayer.emitterCells = Self.rainCells(intensity: intensity)
        case .cherryBlossom:
            emitterLayer.emitterCells = Self.cherryBlossomCells(intensity: intensity)
        }

        configuredBoundsWidth = bounds.width
        configuredWeatherType = weatherType
        configuredIntensity = intensity
    }

    // MARK: - Snow (3 depth layers: far / mid / near)

    private static func snowCells(intensity: Float) -> [CAEmitterCell] {
        let circle = makeCircleImage(color: .white)

        // FAR: tiny, slow, faint
        let far = CAEmitterCell()
        far.birthRate = 60 * intensity
        far.lifetime = 18
        far.velocity = 20
        far.velocityRange = 8
        far.emissionLongitude = .pi
        far.emissionRange = .pi / 10
        far.xAcceleration = 3
        far.scale = 0.08
        far.scaleRange = 0.04
        far.alphaRange = 0.3
        far.color = UIColor(white: 1.0, alpha: 0.4).cgColor
        far.contents = circle

        // MID: medium
        let mid = CAEmitterCell()
        mid.birthRate = 25 * intensity
        mid.lifetime = 14
        mid.velocity = 40
        mid.velocityRange = 15
        mid.emissionLongitude = .pi
        mid.emissionRange = .pi / 8
        mid.xAcceleration = 5
        mid.scale = 0.18
        mid.scaleRange = 0.08
        mid.alphaRange = 0.25
        mid.color = UIColor(white: 1.0, alpha: 0.7).cgColor
        mid.contents = circle
        mid.spin = 0.2
        mid.spinRange = 0.5

        // NEAR: larger, faster, bright
        let near = CAEmitterCell()
        near.birthRate = 10 * intensity
        near.lifetime = 10
        near.velocity = 70
        near.velocityRange = 20
        near.emissionLongitude = .pi
        near.emissionRange = .pi / 6
        near.xAcceleration = 8
        near.scale = 0.32
        near.scaleRange = 0.12
        near.alphaRange = 0.15
        near.color = UIColor(white: 1.0, alpha: 0.95).cgColor
        near.contents = circle
        near.spin = 0.5
        near.spinRange = 1.0

        return [far, mid, near]
    }

    // MARK: - Rain (3 depth layers)

    private static func rainCells(intensity: Float) -> [CAEmitterCell] {
        // FAR: thin, dim, slow
        let far = CAEmitterCell()
        far.birthRate = 120 * intensity
        far.lifetime = 5
        far.velocity = 350
        far.velocityRange = 60
        far.emissionLongitude = .pi
        far.emissionRange = .pi / 40
        far.scale = 0.25
        far.scaleRange = 0.08
        far.alphaRange = 0.25
        far.color = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.35).cgColor
        far.contents = makeRainDropImage(width: 2, height: 14)

        // MID
        let mid = CAEmitterCell()
        mid.birthRate = 70 * intensity
        mid.lifetime = 4
        mid.velocity = 600
        mid.velocityRange = 80
        mid.emissionLongitude = .pi
        mid.emissionRange = .pi / 50
        mid.scale = 0.5
        mid.scaleRange = 0.12
        mid.alphaRange = 0.25
        mid.color = UIColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 0.6).cgColor
        mid.contents = makeRainDropImage(width: 3, height: 18)

        // NEAR: thick, fast, bright streak
        let near = CAEmitterCell()
        near.birthRate = 30 * intensity
        near.lifetime = 3
        near.velocity = 900
        near.velocityRange = 120
        near.emissionLongitude = .pi
        near.emissionRange = .pi / 60
        near.scale = 0.8
        near.scaleRange = 0.15
        near.alphaRange = 0.2
        near.color = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.9).cgColor
        near.contents = makeRainDropImage(width: 4, height: 24)

        return [far, mid, near]
    }

    // MARK: - Cherry Blossom (2 depth layers, smaller than before)

    private static func cherryBlossomCells(intensity: Float) -> [CAEmitterCell] {
        let petal = makePetalImage()

        // FAR / small
        let smallPetal = CAEmitterCell()
        smallPetal.birthRate = 15 * intensity
        smallPetal.lifetime = 14
        smallPetal.lifetimeRange = 3
        smallPetal.velocity = 30
        smallPetal.velocityRange = 10
        smallPetal.emissionLongitude = .pi
        smallPetal.emissionRange = .pi / 4
        smallPetal.xAcceleration = 15
        smallPetal.spin = 2.0
        smallPetal.spinRange = 4.0
        smallPetal.scale = 0.2
        smallPetal.scaleRange = 0.08
        smallPetal.alphaRange = 0.25
        smallPetal.color = UIColor(white: 1.0, alpha: 0.7).cgColor
        smallPetal.contents = petal

        // NEAR / large (80% of previous: 0.8 → 0.5, 0.3 → 0.2 for range)
        let largePetal = CAEmitterCell()
        largePetal.birthRate = 10 * intensity
        largePetal.lifetime = 12
        largePetal.lifetimeRange = 2
        largePetal.velocity = 40
        largePetal.velocityRange = 15
        largePetal.emissionLongitude = .pi
        largePetal.emissionRange = .pi / 5
        largePetal.xAcceleration = 12
        largePetal.spin = 1.5
        largePetal.spinRange = 3.0
        largePetal.scale = 0.4
        largePetal.scaleRange = 0.12
        largePetal.alphaRange = 0.2
        largePetal.color = UIColor(white: 1.0, alpha: 1.0).cgColor
        largePetal.contents = petal

        return [smallPetal, largePetal]
    }

    // MARK: - Particle Images

    private static func makeCircleImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Soft radial gradient for nicer edges
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color.cgColor,
                         color.withAlphaComponent(0.7).cgColor,
                         color.withAlphaComponent(0.0).cgColor] as CFArray,
                locations: [0, 0.6, 1]
            )!
            cg.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: 0,
                endCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                endRadius: size.width / 2,
                options: []
            )
        }.cgImage
    }

    private static func makeRainDropImage(width: CGFloat, height: CGFloat) -> CGImage? {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(white: 1.0, alpha: 0.9).cgColor,
                         UIColor(white: 1.0, alpha: 0.0).cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: width / 2, y: 0),
                end: CGPoint(x: width / 2, y: height),
                options: []
            )
        }.cgImage
    }

    private static func makePetalImage() -> CGImage? {
        let size = CGSize(width: 32, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let pink = UIColor(red: 1.0, green: 0.6, blue: 0.75, alpha: 1.0)
            let darkPink = UIColor(red: 0.95, green: 0.4, blue: 0.6, alpha: 1.0)

            let path = UIBezierPath()
            let w = size.width
            let h = size.height
            path.move(to: CGPoint(x: 2, y: h / 2))
            path.addCurve(
                to: CGPoint(x: w - 2, y: h / 2),
                controlPoint1: CGPoint(x: w * 0.3, y: -2),
                controlPoint2: CGPoint(x: w * 0.7, y: -2)
            )
            path.addCurve(
                to: CGPoint(x: 2, y: h / 2),
                controlPoint1: CGPoint(x: w * 0.7, y: h + 2),
                controlPoint2: CGPoint(x: w * 0.3, y: h + 2)
            )
            path.close()

            cg.saveGState()
            cg.addPath(path.cgPath)
            cg.clip()
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [pink.cgColor, darkPink.cgColor] as CFArray,
                locations: [0, 1]
            )!
            cg.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: w, y: h),
                options: []
            )
            cg.restoreGState()
        }.cgImage
    }
}

#Preview {
    WeatherView()
}
