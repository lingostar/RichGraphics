import SwiftUI

private struct SpirographPreset: Identifiable {
    let id = UUID()
    let name: String
    let outerRadius: Double
    let innerRadius: Double
    let penOffset: Double
}

struct GenerativeArtView: View {
    @State private var outerRadius: Double = 200
    @State private var innerRadius: Double = 80
    @State private var penOffset: Double = 60
    @State private var progress: Double = 0.0
    @State private var isAnimating = false
    @State private var timer: Timer?
    @State private var hueStart: Double = 0.0

    private let presets: [SpirographPreset] = [
        SpirographPreset(name: "Rose", outerRadius: 200, innerRadius: 120, penOffset: 90),
        SpirographPreset(name: "Mandala", outerRadius: 180, innerRadius: 60, penOffset: 40),
        SpirographPreset(name: "Celtic Knot", outerRadius: 220, innerRadius: 100, penOffset: 110),
    ]

    var body: some View {
        VStack(spacing: 0) {
            spirographCanvas
            Divider()
            controlsPanel
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Canvas

    private var spirographCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = min(size.width, size.height) / 500.0

            let totalSteps = 2000
            let visibleSteps = Int(progress * Double(totalSteps))

            guard visibleSteps > 1 else { return }

            let R = outerRadius * scale
            let r = innerRadius * scale
            let d = penOffset * scale
            let diff = R - r

            // Draw in colored segments
            let segmentSize = max(1, visibleSteps / 200)

            for segStart in stride(from: 0, to: visibleSteps - 1, by: segmentSize) {
                let segEnd = min(segStart + segmentSize + 1, visibleSteps)
                var segPath = Path()

                for i in segStart..<segEnd {
                    let t = Double(i) / Double(totalSteps) * .pi * 20
                    let x = center.x + diff * cos(t) + d * cos(diff / r * t)
                    let y = center.y + diff * sin(t) - d * sin(diff / r * t)
                    let point = CGPoint(x: x, y: y)

                    if i == segStart {
                        segPath.move(to: point)
                    } else {
                        segPath.addLine(to: point)
                    }
                }

                let hue = (hueStart + Double(segStart) / Double(totalSteps)) .truncatingRemainder(dividingBy: 1.0)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)

                context.stroke(
                    segPath,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Controls

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Presets
                HStack(spacing: 10) {
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            outerRadius = preset.outerRadius
                            innerRadius = preset.innerRadius
                            penOffset = preset.penOffset
                            restartAnimation()
                        }
                        .buttonStyle(.bordered)
                        .font(.subheadline)
                    }

                    Spacer()

                    Button {
                        randomizeParameters()
                    } label: {
                        Image(systemName: "dice")
                    }
                    .buttonStyle(.bordered)
                }

                // Sliders
                VStack(spacing: 8) {
                    sliderRow(label: "Outer R", value: $outerRadius, range: 50...300)
                    sliderRow(label: "Inner R", value: $innerRadius, range: 10...200)
                    sliderRow(label: "Pen Offset", value: $penOffset, range: 5...200)
                }

                // Animation controls
                HStack {
                    Button {
                        if isAnimating {
                            stopAnimation()
                        } else {
                            startAnimation()
                        }
                    } label: {
                        Label(
                            isAnimating ? "Pause" : "Animate",
                            systemImage: isAnimating ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        restartAnimation()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 240)
        .background(Color(.systemGroupedBackground))
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Slider(value: value, in: range)
                .onChange(of: value.wrappedValue) {
                    restartAnimation()
                }
            Text("\(Int(value.wrappedValue))")
                .font(.caption)
                .monospacedDigit()
                .frame(width: 36)
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        isAnimating = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                if progress < 1.0 {
                    progress += 0.005
                } else {
                    stopAnimation()
                }
            }
        }
    }

    private func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
    }

    private func restartAnimation() {
        stopAnimation()
        progress = 0
        hueStart = Double.random(in: 0...1)
        startAnimation()
    }

    private func randomizeParameters() {
        outerRadius = Double.random(in: 100...280)
        innerRadius = Double.random(in: 20...160)
        penOffset = Double.random(in: 10...150)
        restartAnimation()
    }
}

#Preview {
    NavigationStack {
        GenerativeArtView()
            .navigationTitle("Generative Art")
    }
}
