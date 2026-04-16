import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Camera Filter Type

private enum CameraFilter: String, CaseIterable, Identifiable, Sendable {
    case normal = "Normal"
    case sepia = "Sepia"
    case noir = "Noir"
    case comic = "Comic"
    case pixellate = "Pixellate"
    case bloom = "Bloom"
    case thermal = "Thermal"
    case pencil = "Pencil"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .normal: "circle"
        case .sepia: "sun.dust"
        case .noir: "moon"
        case .comic: "bubble.left.and.text.bubble.right"
        case .pixellate: "square.grid.3x3"
        case .bloom: "sparkle"
        case .thermal: "thermometer.sun"
        case .pencil: "pencil.line"
        }
    }

    nonisolated func apply(to input: CIImage) -> CIImage {
        switch self {
        case .normal:
            return input
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = input
            f.intensity = 0.8
            return f.outputImage ?? input
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = input
            return f.outputImage ?? input
        case .comic:
            let f = CIFilter.comicEffect()
            f.inputImage = input
            return f.outputImage ?? input
        case .pixellate:
            let f = CIFilter.pixellate()
            f.inputImage = input
            f.scale = 12
            return f.outputImage ?? input
        case .bloom:
            let f = CIFilter.bloom()
            f.inputImage = input
            f.intensity = 1.5
            f.radius = 15
            return f.outputImage ?? input
        case .thermal:
            let f = CIFilter.colorInvert()
            f.inputImage = input
            return f.outputImage ?? input
        case .pencil:
            let f = CIFilter(name: "CILineOverlay")!
            f.setValue(input, forKey: kCIInputImageKey)
            f.setValue(0.07, forKey: "inputNRNoiseLevel")
            f.setValue(0.71, forKey: "inputNRSharpness")
            f.setValue(1.0, forKey: "inputEdgeIntensity")
            f.setValue(0.1, forKey: "inputThreshold")
            f.setValue(50.0, forKey: "inputContrast")
            return f.outputImage ?? input
        }
    }
}

// MARK: - Camera Pipeline (runs off main actor)

private final class CameraPipeline: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let queue = DispatchQueue(label: "camera.pipeline")
    private var currentFilter: CameraFilter = .normal
    private var onFrame: (@Sendable (CGImage, Int) -> Void)?

    private var frameCount = 0
    private var lastFPSDate = Date()
    private var currentFPS = 0

    func configure(filter: CameraFilter) {
        queue.async { [self] in
            currentFilter = filter
        }
    }

    func setFrameHandler(_ handler: @escaping @Sendable (CGImage, Int) -> Void) {
        queue.async { [self] in
            onFrame = handler
        }
    }

    func processCIImage(_ ciImage: CIImage) {
        queue.async { [self] in
            let filtered = currentFilter.apply(to: ciImage)
            if let cgImage = ciContext.createCGImage(filtered, from: ciImage.extent) {
                updateFPS()
                onFrame?(cgImage, currentFPS)
            }
        }
    }

    private func updateFPS() {
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSDate)
        if elapsed >= 1.0 {
            currentFPS = Int(Double(frameCount) / elapsed)
            frameCount = 0
            lastFPSDate = now
        }
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let filtered = currentFilter.apply(to: ciImage)
        if let cgImage = ciContext.createCGImage(filtered, from: ciImage.extent) {
            updateFPS()
            onFrame?(cgImage, currentFPS)
        }
    }
}

// MARK: - Camera Manager

@MainActor
private final class CameraManager: ObservableObject {
    @Published var currentFrame: CGImage?
    @Published var fps: Int = 0
    @Published var isCameraAvailable = false

    private let pipeline = CameraPipeline()
    private var captureSession: AVCaptureSession?
    private var fallbackTimer: Timer?
    private var fallbackPhase: CGFloat = 0

    var selectedFilter: CameraFilter = .normal {
        didSet {
            pipeline.configure(filter: selectedFilter)
        }
    }

    func startSession() {
        pipeline.setFrameHandler { [weak self] cgImage, fps in
            Task { @MainActor [weak self] in
                self?.currentFrame = cgImage
                self?.fps = fps
            }
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )

        if let camera = discoverySession.devices.first {
            isCameraAvailable = true
            setupCamera(camera)
        } else {
            isCameraAvailable = false
            startFallbackMode()
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    // MARK: Real Camera

    private func setupCamera(_ device: AVCaptureDevice) {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(pipeline, queue: DispatchQueue(label: "camera.output"))

        if session.canAddOutput(output) { session.addOutput(output) }
        captureSession = session

        session.startRunning()
    }

    // MARK: Fallback (Simulator)

    private func startFallbackMode() {
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.generateFallbackFrame()
            }
        }
    }

    private func generateFallbackFrame() {
        fallbackPhase += 0.05
        let phase = fallbackPhase
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { ctx in
            let c = ctx.cgContext
            let r = CGFloat(sin(phase) * 0.5 + 0.5)
            let g = CGFloat(sin(phase + 2) * 0.5 + 0.5)
            let b = CGFloat(sin(phase + 4) * 0.5 + 0.5)

            let colors = [
                UIColor(red: r, green: g, blue: b, alpha: 1).cgColor,
                UIColor(red: 1 - r, green: 1 - g, blue: b, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray, locations: [0, 1])!
            c.drawLinearGradient(gradient, start: .zero,
                                end: CGPoint(x: size.width, y: size.height), options: [])

            for i in 0..<6 {
                let p = phase + Double(i) * 1.0
                let cx = size.width * 0.5 + CGFloat(cos(p)) * 120
                let cy = size.height * 0.5 + CGFloat(sin(p * 0.7)) * 80
                let radius: CGFloat = 30 + CGFloat(sin(p * 2)) * 15
                let hue = CGFloat(i) / 6.0
                c.setFillColor(UIColor(hue: hue, saturation: 0.9, brightness: 1, alpha: 0.7).cgColor)
                c.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius,
                                         width: radius * 2, height: radius * 2))
            }

            let label = "Simulator Preview" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            let labelSize = label.size(withAttributes: attrs)
            label.draw(at: CGPoint(x: (size.width - labelSize.width) / 2, y: 10), withAttributes: attrs)
        }

        let ciImage = CIImage(image: uiImage)!
        pipeline.processCIImage(ciImage)
    }
}

// MARK: - View

struct CameraFiltersView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedFilter: CameraFilter = .normal

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Camera preview
                ZStack(alignment: .topTrailing) {
                    if let frame = cameraManager.currentFrame {
                        Image(decorative: frame, scale: 1)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay { ProgressView("Starting...").foregroundStyle(.white) }
                            .padding(.horizontal, 8)
                    }

                    // FPS counter
                    Text("\(cameraManager.fps) FPS")
                        .font(.caption.monospaced().bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)

                // Source indicator
                if !cameraManager.isCameraAvailable {
                    Text("Simulator mode -- using animated procedural input")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }

                // Filter picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CameraFilter.allCases) { filter in
                            Button {
                                selectedFilter = filter
                                cameraManager.selectedFilter = filter
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: filter.iconName)
                                        .font(.title3)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedFilter == filter
                                                ? Color.orange
                                                : Color(.systemGray5)
                                        )
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        .clipShape(Circle())
                                    Text(filter.rawValue)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(selectedFilter == filter ? .orange : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

#Preview {
    NavigationStack {
        CameraFiltersView()
            .navigationTitle("Camera Filters")
    }
}
