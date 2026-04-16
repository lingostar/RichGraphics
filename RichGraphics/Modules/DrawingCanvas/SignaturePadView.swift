import SwiftUI

private struct SignaturePoint {
    let location: CGPoint
    let timestamp: TimeInterval
}

private struct SignatureStroke {
    var points: [SignaturePoint]
}

struct SignaturePadView: View {
    @State private var strokes: [SignatureStroke] = []
    @State private var currentStroke: SignatureStroke?
    @State private var showExportSheet = false
    @State private var exportedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            signatureCanvas

            Spacer(minLength: 20)

            actionButtons
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showExportSheet) {
            if let image = exportedImage {
                signatureExportSheet(image: image)
            }
        }
    }

    // MARK: - Canvas

    @MainActor
    private var signatureCanvas: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                // Draw all completed strokes
                for stroke in strokes {
                    drawSmooth(stroke: stroke, in: &context)
                }
                // Draw current stroke
                if let current = currentStroke {
                    drawSmooth(stroke: current, in: &context)
                }

                // Signature line
                let lineY = size.height - 40
                var linePath = Path()
                linePath.move(to: CGPoint(x: 30, y: lineY))
                linePath.addLine(to: CGPoint(x: size.width - 30, y: lineY))
                context.stroke(
                    linePath,
                    with: .color(.gray.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )

                // X mark
                let xLabel = Text("X")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.gray.opacity(0.5))
                context.draw(
                    context.resolve(xLabel),
                    at: CGPoint(x: 40, y: lineY - 16)
                )
            }
            .gesture(signatureGesture)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: 350)
    }

    private var signatureGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = SignaturePoint(
                    location: value.location,
                    timestamp: Date.timeIntervalSinceReferenceDate
                )
                if currentStroke == nil {
                    currentStroke = SignatureStroke(points: [point])
                } else {
                    currentStroke?.points.append(point)
                }
            }
            .onEnded { _ in
                if let stroke = currentStroke {
                    strokes.append(stroke)
                }
                currentStroke = nil
            }
    }

    private func drawSmooth(stroke: SignatureStroke, in context: inout GraphicsContext) {
        let points = stroke.points
        guard points.count > 1 else { return }

        var path = Path()
        path.move(to: points[0].location)

        if points.count == 2 {
            path.addLine(to: points[1].location)
        } else {
            for i in 1..<points.count {
                let current = points[i].location
                let previous = points[i - 1].location
                let mid = CGPoint(
                    x: (previous.x + current.x) / 2,
                    y: (previous.y + current.y) / 2
                )
                path.addQuadCurve(to: mid, control: previous)
            }
            if let last = points.last {
                path.addLine(to: last.location)
            }
        }

        // Variable width based on speed
        context.stroke(
            path,
            with: .color(.black.opacity(0.85)),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                strokes.removeAll()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(strokes.isEmpty)

            Spacer()

            Button {
                captureSignature()
            } label: {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(strokes.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @MainActor
    private func captureSignature() {
        let renderer = ImageRenderer(
            content: signatureRenderContent
        )
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            exportedImage = image
            showExportSheet = true
        }
    }

    @MainActor
    private var signatureRenderContent: some View {
        Canvas { context, size in
            // White background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white)
            )
            for stroke in strokes {
                drawSmooth(stroke: stroke, in: &context)
            }
        }
        .frame(width: 400, height: 200)
    }

    @MainActor
    private func signatureExportSheet(image: UIImage) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Your Signature")
                    .font(.headline)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal)

                Text("Signature captured successfully")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showExportSheet = false
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignaturePadView()
            .navigationTitle("Signature Pad")
    }
}
