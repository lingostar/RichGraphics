import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Filter Definition

enum GalleryFilter: String, CaseIterable, Identifiable, Sendable {
    case sepia = "Sepia"
    case chrome = "Chrome"
    case fade = "Fade"
    case instant = "Instant"
    case noir = "Noir"
    case process = "Process"
    case tonal = "Tonal"
    case transfer = "Transfer"
    case bloom = "Bloom"
    case vignette = "Vignette"
    case pixellate = "Pixellate"
    case comic = "Comic"
    case crystallize = "Crystallize"
    case pointillize = "Pointillize"
    case edges = "Edges"

    var id: String { rawValue }

    var supportsIntensity: Bool {
        switch self {
        case .sepia, .bloom, .vignette, .pixellate, .crystallize, .pointillize:
            return true
        default:
            return false
        }
    }
}

// MARK: - View

struct FilterGalleryView: View {
    @State private var selectedFilter: GalleryFilter? = nil
    @State private var intensity: Double = 0.7
    @State private var sourceImage: CGImage?
    @State private var thumbnails: [GalleryFilter: CGImage] = [:]
    @State private var fullPreview: CGImage?

    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            // Full-size preview
            Group {
                if let preview = fullPreview ?? sourceImage {
                    Image(decorative: preview, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay { ProgressView() }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
            }
            .frame(maxHeight: 260)

            // Intensity slider
            if let filter = selectedFilter, filter.supportsIntensity {
                HStack {
                    Text("Intensity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Slider(value: $intensity, in: 0...1, step: 0.05)
                        .tint(.pink)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .onChange(of: intensity) { _, _ in
                    updateFullPreview()
                }
            }

            // Thumbnail grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(GalleryFilter.allCases) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                            updateFullPreview()
                        } label: {
                            VStack(spacing: 4) {
                                if let thumb = thumbnails[filter] {
                                    Image(decorative: thumb, scale: 1)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 75)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedFilter == filter ? Color.pink : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 100, height: 75)
                                        .overlay { ProgressView().scaleEffect(0.6) }
                                }
                                Text(filter.rawValue)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(selectedFilter == filter ? .pink : .primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .task {
            await generateContent()
        }
    }

    // MARK: - Image Generation

    private func generateContent() async {
        let source = Self.generateProceduralImage()
        sourceImage = source

        // Generate thumbnails for each filter
        let ciSource = CIImage(cgImage: source)
        var newThumbnails: [GalleryFilter: CGImage] = [:]

        for filter in GalleryFilter.allCases {
            let filtered = Self.applyFilter(filter, to: ciSource, intensity: 0.7)
            if let cg = context.createCGImage(filtered, from: ciSource.extent) {
                newThumbnails[filter] = cg
            }
        }

        thumbnails = newThumbnails
        fullPreview = source
    }

    private func updateFullPreview() {
        guard let source = sourceImage else { return }
        let ciSource = CIImage(cgImage: source)
        if let filter = selectedFilter {
            let filtered = Self.applyFilter(filter, to: ciSource, intensity: intensity)
            if let cg = context.createCGImage(filtered, from: ciSource.extent) {
                fullPreview = cg
            }
        } else {
            fullPreview = source
        }
    }

    // MARK: - Procedural Image

    nonisolated static func generateProceduralImage() -> CGImage {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { ctx in
            let c = ctx.cgContext

            // Colorful gradient background
            let bgColors = [
                UIColor.systemCyan.cgColor,
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ]
            let bgGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: bgColors as CFArray,
                locations: [0, 0.5, 1]
            )!
            c.drawLinearGradient(bgGradient, start: .zero,
                                end: CGPoint(x: size.width, y: size.height), options: [])

            // Sun / star burst
            c.setFillColor(UIColor.systemYellow.cgColor)
            c.fillEllipse(in: CGRect(x: 430, y: 30, width: 100, height: 100))
            c.setFillColor(UIColor.systemOrange.withAlphaComponent(0.4).cgColor)
            c.fillEllipse(in: CGRect(x: 410, y: 10, width: 140, height: 140))

            // Mountains
            c.setFillColor(UIColor.systemGray.withAlphaComponent(0.7).cgColor)
            c.move(to: CGPoint(x: -20, y: 300))
            c.addLine(to: CGPoint(x: 150, y: 120))
            c.addLine(to: CGPoint(x: 320, y: 300))
            c.fillPath()

            c.setFillColor(UIColor.systemGray2.withAlphaComponent(0.7).cgColor)
            c.move(to: CGPoint(x: 200, y: 300))
            c.addLine(to: CGPoint(x: 420, y: 80))
            c.addLine(to: CGPoint(x: 640, y: 300))
            c.fillPath()

            // Green ground
            let groundColors = [UIColor.systemGreen.cgColor,
                                UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1).cgColor]
            let groundGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: groundColors as CFArray,
                locations: [0, 1]
            )!
            c.drawLinearGradient(groundGradient,
                                start: CGPoint(x: 0, y: 300),
                                end: CGPoint(x: 0, y: size.height), options: [])

            // Colorful flowers
            let flowerColors: [UIColor] = [.systemRed, .systemPink, .systemYellow,
                                           .systemOrange, .magenta]
            for i in 0..<12 {
                let x = CGFloat(30 + (i * 50) % Int(size.width - 40))
                let y = CGFloat(320 + (i * 17) % 70)
                let r: CGFloat = CGFloat(6 + i % 4)
                c.setFillColor(flowerColors[i % flowerColors.count].cgColor)
                c.fillEllipse(in: CGRect(x: x, y: y, width: r * 2, height: r * 2))
            }

            // Tree
            c.setFillColor(UIColor.brown.cgColor)
            c.fill(CGRect(x: 85, y: 240, width: 18, height: 60))
            c.setFillColor(UIColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 1).cgColor)
            c.fillEllipse(in: CGRect(x: 50, y: 190, width: 90, height: 70))
        }
        return uiImage.cgImage!
    }

    // MARK: - Filter Application

    nonisolated static func applyFilter(_ filter: GalleryFilter, to input: CIImage, intensity: Double) -> CIImage {
        switch filter {
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = input
            f.intensity = Float(intensity)
            return f.outputImage ?? input
        case .chrome:
            let f = CIFilter.photoEffectChrome()
            f.inputImage = input
            return f.outputImage ?? input
        case .fade:
            let f = CIFilter.photoEffectFade()
            f.inputImage = input
            return f.outputImage ?? input
        case .instant:
            let f = CIFilter.photoEffectInstant()
            f.inputImage = input
            return f.outputImage ?? input
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = input
            return f.outputImage ?? input
        case .process:
            let f = CIFilter.photoEffectProcess()
            f.inputImage = input
            return f.outputImage ?? input
        case .tonal:
            let f = CIFilter.photoEffectTonal()
            f.inputImage = input
            return f.outputImage ?? input
        case .transfer:
            let f = CIFilter.photoEffectTransfer()
            f.inputImage = input
            return f.outputImage ?? input
        case .bloom:
            let f = CIFilter.bloom()
            f.inputImage = input
            f.intensity = Float(intensity * 2)
            f.radius = Float(intensity * 20)
            return f.outputImage ?? input
        case .vignette:
            let f = CIFilter.vignette()
            f.inputImage = input
            f.intensity = Float(intensity * 5)
            f.radius = Float(intensity * 3)
            return f.outputImage ?? input
        case .pixellate:
            let f = CIFilter.pixellate()
            f.inputImage = input
            f.scale = Float(max(1, intensity * 30))
            return f.outputImage ?? input
        case .comic:
            let f = CIFilter.comicEffect()
            f.inputImage = input
            return f.outputImage ?? input
        case .crystallize:
            let f = CIFilter.crystallize()
            f.inputImage = input
            f.radius = Float(max(1, intensity * 40))
            return f.outputImage ?? input
        case .pointillize:
            let f = CIFilter.pointillize()
            f.inputImage = input
            f.radius = Float(max(1, intensity * 30))
            return f.outputImage ?? input
        case .edges:
            let f = CIFilter.edges()
            f.inputImage = input
            f.intensity = Float(intensity * 10)
            return f.outputImage ?? input
        }
    }
}

#Preview {
    NavigationStack {
        FilterGalleryView()
            .navigationTitle("Filter Gallery")
    }
}
