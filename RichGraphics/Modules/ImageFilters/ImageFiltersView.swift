import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImageFiltersView: View {
    @State private var selectedFilter: ImageFilterType = .none
    @State private var intensity: Double = 0.8
    @State private var processedImage: UIImage?

    private let context = CIContext()

    enum ImageFilterType: String, CaseIterable, Identifiable {
        case none = "Original"
        case sepiaTone = "Sepia"
        case bloom = "Bloom"
        case noir = "Noir"
        case chrome = "Chrome"
        case fade = "Fade"
        case instant = "Instant"
        case vignette = "Vignette"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if let image = processedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8)
                    .padding(24)
            } else {
                ProgressView("Generating sample image...")
            }

            Spacer()

            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ImageFilterType.allCases) { filter in
                            Button {
                                selectedFilter = filter
                                applyFilter()
                            } label: {
                                Text(filter.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.pink : Color(.systemGray5))
                                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if selectedFilter != .none {
                    HStack {
                        Text("Intensity")
                            .font(.subheadline)
                        Slider(value: $intensity, in: 0...1, step: 0.05)
                            .onChange(of: intensity) { _, _ in
                                applyFilter()
                            }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            applyFilter()
        }
    }

    private func generateSampleImage() -> CIImage {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { ctx in
            // Sky gradient
            let skyColors = [UIColor.systemCyan.cgColor, UIColor.systemBlue.cgColor]
            let skyGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: skyColors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(skyGradient, start: .zero, end: CGPoint(x: 0, y: size.height * 0.6), options: [])

            // Ground
            let groundColors = [UIColor.systemGreen.cgColor, UIColor(red: 0.2, green: 0.5, blue: 0.1, alpha: 1).cgColor]
            let groundGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: groundColors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(groundGradient, start: CGPoint(x: 0, y: size.height * 0.6), end: CGPoint(x: 0, y: size.height), options: [])

            // Sun
            ctx.cgContext.setFillColor(UIColor.systemYellow.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 420, y: 40, width: 80, height: 80))

            // Mountains
            ctx.cgContext.setFillColor(UIColor.systemGray.cgColor)
            ctx.cgContext.move(to: CGPoint(x: 0, y: size.height * 0.6))
            ctx.cgContext.addLine(to: CGPoint(x: 150, y: size.height * 0.25))
            ctx.cgContext.addLine(to: CGPoint(x: 300, y: size.height * 0.6))
            ctx.cgContext.fillPath()

            ctx.cgContext.setFillColor(UIColor.systemGray2.cgColor)
            ctx.cgContext.move(to: CGPoint(x: 200, y: size.height * 0.6))
            ctx.cgContext.addLine(to: CGPoint(x: 400, y: size.height * 0.2))
            ctx.cgContext.addLine(to: CGPoint(x: 600, y: size.height * 0.6))
            ctx.cgContext.fillPath()

            // Tree
            ctx.cgContext.setFillColor(UIColor.brown.cgColor)
            ctx.cgContext.fill(CGRect(x: 90, y: size.height * 0.55, width: 20, height: 60))
            ctx.cgContext.setFillColor(UIColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 1).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 55, y: size.height * 0.35, width: 90, height: 90))
        }
        return CIImage(image: uiImage)!
    }

    private func applyFilter() {
        let inputImage = generateSampleImage()
        let outputImage: CIImage

        switch selectedFilter {
        case .none:
            outputImage = inputImage
        case .sepiaTone:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = inputImage
            filter.intensity = Float(intensity)
            outputImage = filter.outputImage ?? inputImage
        case .bloom:
            let filter = CIFilter.bloom()
            filter.inputImage = inputImage
            filter.intensity = Float(intensity * 2)
            filter.radius = Float(intensity * 20)
            outputImage = filter.outputImage ?? inputImage
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = inputImage
            outputImage = filter.outputImage ?? inputImage
        case .chrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = inputImage
            outputImage = filter.outputImage ?? inputImage
        case .fade:
            let filter = CIFilter.photoEffectFade()
            filter.inputImage = inputImage
            outputImage = filter.outputImage ?? inputImage
        case .instant:
            let filter = CIFilter.photoEffectInstant()
            filter.inputImage = inputImage
            outputImage = filter.outputImage ?? inputImage
        case .vignette:
            let filter = CIFilter.vignette()
            filter.inputImage = inputImage
            filter.intensity = Float(intensity * 5)
            filter.radius = Float(intensity * 3)
            outputImage = filter.outputImage ?? inputImage
        }

        if let cgImage = context.createCGImage(outputImage, from: inputImage.extent) {
            processedImage = UIImage(cgImage: cgImage)
        }
    }
}

#Preview {
    NavigationStack {
        ImageFiltersView()
            .navigationTitle("Image Filters")
    }
}
