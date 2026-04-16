import SwiftUI

// MARK: - Keyframe Animation Values

private struct AnimationValues {
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    var scale: CGFloat = 1.0
    var rotation: Double = 0
}

// MARK: - Track Model for Timeline Visualization

private struct TrackInfo: Identifiable {
    let id: String
    let name: String
    let color: Color
    let icon: String
    let keyframes: [(time: Double, value: Double)]  // normalized 0...1
    let totalDuration: Double
}

// MARK: - Main View

struct KeyframeAnimationsView: View {
    @State private var playTrigger = 0
    @State private var isPlaying = false
    @State private var elapsed: Double = 0
    @State private var timer: Timer?

    // Animation total duration
    private let totalDuration: Double = 2.0

    // Track metadata for the timeline visualization
    private var tracks: [TrackInfo] {
        [
            TrackInfo(
                id: "x", name: "X Offset", color: .red, icon: "arrow.left.and.right",
                keyframes: [
                    (0.0, 0.5), (0.25, 1.0), (0.5, 0.5), (0.75, 0.0), (1.0, 0.5)
                ],
                totalDuration: totalDuration
            ),
            TrackInfo(
                id: "y", name: "Y Offset", color: .blue, icon: "arrow.up.and.down",
                keyframes: [
                    (0.0, 0.5), (0.15, 0.0), (0.35, 0.7), (0.55, 0.15), (0.75, 0.6), (1.0, 0.5)
                ],
                totalDuration: totalDuration
            ),
            TrackInfo(
                id: "scale", name: "Scale", color: .green, icon: "arrow.up.left.and.arrow.down.right",
                keyframes: [
                    (0.0, 0.5), (0.2, 0.8), (0.4, 0.3), (0.6, 0.9), (0.8, 0.4), (1.0, 0.5)
                ],
                totalDuration: totalDuration
            ),
            TrackInfo(
                id: "rotation", name: "Rotation", color: .orange, icon: "arrow.trianglehead.2.clockwise.rotate.90",
                keyframes: [
                    (0.0, 0.5), (0.5, 1.0), (1.0, 0.5)
                ],
                totalDuration: totalDuration
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // — Top: Animation Stage —
            animationStage
                .frame(maxHeight: .infinity)

            Divider()
                .background(Color.gray.opacity(0.3))

            // — Bottom: Timeline + Controls —
            VStack(spacing: 12) {
                timelineHeader
                timelineTracks
                playControls
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Animation Stage

    private var animationStage: some View {
        ZStack {
            // Grid background to show movement clearly
            GridBackgroundView()

            // The animated object
            KeyframeAnimator(initialValue: AnimationValues(), trigger: playTrigger) { values in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 12)
                }
                .offset(x: values.xOffset, y: values.yOffset)
                .scaleEffect(values.scale)
                .rotationEffect(.degrees(values.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.xOffset) {
                    CubicKeyframe(80, duration: 0.5)
                    CubicKeyframe(0, duration: 0.5)
                    CubicKeyframe(-80, duration: 0.5)
                    CubicKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.yOffset) {
                    SpringKeyframe(-60, duration: 0.3, spring: .bouncy)
                    SpringKeyframe(30, duration: 0.4, spring: .smooth)
                    SpringKeyframe(-30, duration: 0.4, spring: .bouncy)
                    SpringKeyframe(20, duration: 0.4, spring: .smooth)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.4, duration: 0.4)
                    LinearKeyframe(0.6, duration: 0.4)
                    SpringKeyframe(1.6, duration: 0.4, spring: .bouncy)
                    LinearKeyframe(0.7, duration: 0.4)
                    SpringKeyframe(1.0, duration: 0.4, spring: .smooth)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(180, duration: 1.0)
                    LinearKeyframe(360, duration: 1.0)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Timeline Header

    private var timelineHeader: some View {
        HStack {
            Text("KEYFRAME TRACKS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            if isPlaying {
                Text(String(format: "%.1fs / %.1fs", elapsed, totalDuration))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            // Legend
            HStack(spacing: 8) {
                legendDot(color: .cyan, label: "Cubic")
                legendDot(color: .yellow, label: "Spring")
                legendDot(color: .white, label: "Linear")
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Timeline Tracks

    private var timelineTracks: some View {
        VStack(spacing: 6) {
            ForEach(tracks) { track in
                TimelineTrackRow(track: track, progress: isPlaying ? elapsed / totalDuration : 0)
            }
        }
    }

    // MARK: - Play Controls

    private var playControls: some View {
        HStack(spacing: 16) {
            Button {
                play()
            } label: {
                Label(isPlaying ? "Playing..." : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPlaying ? Color.gray : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isPlaying)

            VStack(alignment: .leading, spacing: 2) {
                Text("각 트랙이 독립적인 타이밍으로")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("동시에 진행되는 것을 관찰하세요")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Playback

    private func play() {
        guard !isPlaying else { return }
        isPlaying = true
        elapsed = 0
        playTrigger += 1

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            Task { @MainActor in
                elapsed += 1.0 / 30.0
                if elapsed >= totalDuration {
                    elapsed = totalDuration
                    timer?.invalidate()
                    timer = nil
                    // Small delay before resetting
                    try? await Task.sleep(for: .milliseconds(300))
                    isPlaying = false
                }
            }
        }
    }
}

// MARK: - Timeline Track Row

private struct TimelineTrackRow: View {
    let track: TrackInfo
    let progress: Double  // 0...1

    var body: some View {
        HStack(spacing: 8) {
            // Track label
            HStack(spacing: 4) {
                Image(systemName: track.icon)
                    .font(.system(size: 9))
                    .foregroundStyle(track.color)
                    .frame(width: 12)
                Text(track.name)
                    .font(.system(size: 10, weight: .medium).monospaced())
                    .foregroundStyle(track.color)
            }
            .frame(width: 85, alignment: .leading)

            // Track bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))

                    // Keyframe segments visualization
                    keyframeSegments(in: geo.size)

                    // Progress playhead
                    if progress > 0 {
                        Rectangle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 2)
                            .offset(x: geo.size.width * min(CGFloat(progress), 1.0) - 1)
                            .animation(.linear(duration: 1.0 / 30.0), value: progress)
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private func keyframeSegments(in size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let points = track.keyframes
            guard points.count >= 2 else { return }

            // Draw the curve
            var path = Path()
            for (i, point) in points.enumerated() {
                let x = point.time * canvasSize.width
                let y = (1.0 - point.value) * canvasSize.height
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Filled area under curve
            var filled = path
            filled.addLine(to: CGPoint(x: points.last!.time * canvasSize.width, y: canvasSize.height))
            filled.addLine(to: CGPoint(x: points.first!.time * canvasSize.width, y: canvasSize.height))
            filled.closeSubpath()
            ctx.fill(filled, with: .color(track.color.opacity(0.15)))

            // Stroke
            ctx.stroke(path, with: .color(track.color.opacity(0.6)), lineWidth: 1.5)

            // Keyframe dots
            for point in points {
                let x = point.time * canvasSize.width
                let y = (1.0 - point.value) * canvasSize.height
                let dotRect = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
                ctx.fill(Path(ellipseIn: dotRect), with: .color(track.color))
            }
        }
    }
}

// MARK: - Grid Background

private struct GridBackgroundView: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 30
            let color = Color.gray.opacity(0.1)

            // Vertical lines
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
                x += step
            }

            // Horizontal lines
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
                y += step
            }

            // Center crosshair
            let centerX = size.width / 2
            let centerY = size.height / 2
            var hLine = Path()
            hLine.move(to: CGPoint(x: 0, y: centerY))
            hLine.addLine(to: CGPoint(x: size.width, y: centerY))
            ctx.stroke(hLine, with: .color(Color.gray.opacity(0.2)), lineWidth: 1)

            var vLine = Path()
            vLine.move(to: CGPoint(x: centerX, y: 0))
            vLine.addLine(to: CGPoint(x: centerX, y: size.height))
            ctx.stroke(vLine, with: .color(Color.gray.opacity(0.2)), lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        KeyframeAnimationsView()
            .navigationTitle("Keyframe Animations")
    }
}
