import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Effect Type

private enum CustomEffect: String, CaseIterable, Identifiable, Sendable {
    case glitch = "Glitch"
    case vintage = "Vintage"
    case popArt = "Pop Art"
    case neonGlow = "Neon Glow"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .glitch: "Affine tile + color channel shifts"
        case .vintage: "Sepia + vignette + noise overlay"
        case .popArt: "Posterize + saturate + halftone"
        case .neonGlow: "Edges + bloom + color overlay"
        }
    }

    var iconName: String {
        switch self {
        case .glitch: "tv"
        case .vintage: "camera.on.rectangle"
        case .popArt: "paintpalette"
        case .neonGlow: "bolt.fill"
        }
    }
}

// MARK: - View

struct CustomEffectsView: View {
    @State private var selectedEffect: CustomEffect = .glitch
    @State private var intensity: Double = 0.7
    @State private var dividerPosition: CGFloat = 0.5
    @State private var sourceImage: CGImage?
    @State private var effectImage: CGImage?
    @State private var isDragging = false

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        VStack(spacing: 0) {
            // Effect selector
            Picker("Effect", selection: $selectedEffect) {
                ForEach(CustomEffect.allCases) { effect in
                    Label(effect.rawValue, systemImage: effect.iconName)
                        .tag(effect)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .onChange(of: selectedEffect) { _, _ in
                applyEffect()
            }

            // Description
            Text(selectedEffect.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            // Before/After comparison with divider
            GeometryReader { geo in
                let imageWidth = geo.size.width - 32
                let imageHeight = min(geo.size.height - 20, 300)

                ZStack {
                    if let source = sourceImage, let effect = effectImage {
                        // "Before" (original) image -- full width, clipped from divider
                        Image(decorative: source, scale: 1)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // "After" (effect) image -- clipped to left of divider
                        Image(decorative: effect, scale: 1)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .mask(
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .frame(width: imageWidth * dividerPosition)
                                    Spacer(minLength: 0)
                                }
                            )

                        // Divider line
                        Rectangle()
                            .fill(.white)
                            .frame(width: 3, height: imageHeight)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .offset(x: imageWidth * (dividerPosition - 0.5))

                        // Drag handle
                        Circle()
                            .fill(.white)
                            .frame(width: 30, height: 30)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .overlay {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.gray)
                            }
                            .offset(x: imageWidth * (dividerPosition - 0.5))
                            .scaleEffect(isDragging ? 1.2 : 1.0)

                        // Labels
                        HStack {
                            Text("EFFECT")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.leading, 8)
                            Spacer()
                            Text("ORIGINAL")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.trailing, 8)
                        }
                        .frame(width: imageWidth)
                        .offset(y: imageHeight / 2 - 16)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray5))
                            .frame(width: imageWidth, height: imageHeight)
                            .overlay { ProgressView() }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let x = value.location.x - 16 // account for padding
                            dividerPosition = min(max(x / imageWidth, 0), 1)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Intensity slider
            HStack {
                Text("Intensity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Slider(value: $intensity, in: 0...1, step: 0.05)
                    .tint(.teal)
                    .onChange(of: intensity) { _, _ in
                        applyEffect()
                    }
                Text("\(Int(intensity * 100))%")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .task {
            let source = FilterGalleryView.generateProceduralImage()
            sourceImage = source
            applyEffect()
        }
    }

    // MARK: - Effect Application

    private func applyEffect() {
        guard let source = sourceImage else { return }
        let ciInput = CIImage(cgImage: source)
        let extent = ciInput.extent
        let result: CIImage

        switch selectedEffect {
        case .glitch:
            result = applyGlitch(to: ciInput, intensity: intensity)
        case .vintage:
            result = applyVintage(to: ciInput, intensity: intensity)
        case .popArt:
            result = applyPopArt(to: ciInput, intensity: intensity)
        case .neonGlow:
            result = applyNeonGlow(to: ciInput, intensity: intensity)
        }

        if let cg = context.createCGImage(result, from: extent) {
            effectImage = cg
        }
    }

    // MARK: Glitch Effect

    private func applyGlitch(to input: CIImage, intensity: Double) -> CIImage {
        let offset = CGFloat(intensity * 15)

        // Shift the color channels by applying transforms
        let transformRight = CGAffineTransform(translationX: offset, y: 0)
        let transformLeft = CGAffineTransform(translationX: -offset, y: offset * 0.3)

        // Create color-channel shifted versions
        let redShift = input.transformed(by: transformRight)
        let blueShift = input.transformed(by: transformLeft)

        // Blend them together
        let blend1 = CIFilter.sourceOverCompositing()
        blend1.inputImage = redShift.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.6))
        ])
        blend1.backgroundImage = input

        guard let mid = blend1.outputImage else { return input }

        let blend2 = CIFilter.sourceOverCompositing()
        blend2.inputImage = blueShift.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.6))
        ])
        blend2.backgroundImage = mid

        return blend2.outputImage ?? input
    }

    // MARK: Vintage Effect

    private func applyVintage(to input: CIImage, intensity: Double) -> CIImage {
        // Step 1: Sepia
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = input
        sepia.intensity = Float(intensity * 0.8)
        let sepiaOut = sepia.outputImage ?? input

        // Step 2: Vignette
        let vignette = CIFilter.vignette()
        vignette.inputImage = sepiaOut
        vignette.intensity = Float(intensity * 4)
        vignette.radius = Float(intensity * 2)
        let vignetteOut = vignette.outputImage ?? sepiaOut

        // Step 3: Reduce contrast slightly for faded look
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = vignetteOut
        colorControls.contrast = Float(1.0 - intensity * 0.3)
        colorControls.brightness = Float(intensity * 0.05)
        colorControls.saturation = Float(1.0 - intensity * 0.3)

        return colorControls.outputImage ?? vignetteOut
    }

    // MARK: Pop Art Effect

    private func applyPopArt(to input: CIImage, intensity: Double) -> CIImage {
        // Step 1: Boost saturation
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = input
        colorControls.saturation = Float(1.0 + intensity * 2.5)
        colorControls.contrast = Float(1.0 + intensity * 0.5)
        let saturated = colorControls.outputImage ?? input

        // Step 2: Posterize
        let posterize = CIFilter(name: "CIColorPosterize")
        posterize?.setValue(saturated, forKey: kCIInputImageKey)
        posterize?.setValue(NSNumber(value: max(2, 8 - intensity * 6)), forKey: "inputLevels")
        let posterized = posterize?.outputImage ?? saturated

        // Step 3: Dot screen (halftone)
        let dotScreen = CIFilter.dotScreen()
        dotScreen.inputImage = posterized
        dotScreen.width = Float(max(2, intensity * 8))
        dotScreen.angle = 0
        dotScreen.sharpness = 0.7

        return dotScreen.outputImage ?? posterized
    }

    // MARK: Neon Glow Effect

    private func applyNeonGlow(to input: CIImage, intensity: Double) -> CIImage {
        // Step 1: Edge detection
        let edges = CIFilter.edges()
        edges.inputImage = input
        edges.intensity = Float(intensity * 10)
        let edgesOut = edges.outputImage ?? input

        // Step 2: Color invert for bright-on-dark
        let invert = CIFilter.colorInvert()
        invert.inputImage = edgesOut
        let inverted = invert.outputImage ?? edgesOut

        // Step 3: Bloom for glow
        let bloom = CIFilter.bloom()
        bloom.inputImage = inverted
        bloom.intensity = Float(intensity * 2)
        bloom.radius = Float(intensity * 15)
        let bloomed = bloom.outputImage ?? inverted

        // Step 4: Tint with color
        let hueAdjust = CIFilter.hueAdjust()
        hueAdjust.inputImage = bloomed
        hueAdjust.angle = Float(intensity * .pi)

        return hueAdjust.outputImage ?? bloomed
    }
}

#Preview {
    NavigationStack {
        CustomEffectsView()
            .navigationTitle("Custom Effects")
    }
}
