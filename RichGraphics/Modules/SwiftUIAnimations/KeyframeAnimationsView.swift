import SwiftUI

private struct AnimationValues {
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    var scale: CGFloat = 1.0
    var rotation: Double = 0
    var opacity: Double = 1.0
}

private enum KeyframePreset: String, CaseIterable, Identifiable {
    case bounce = "Bounce"
    case orbit = "Orbit"
    case shake = "Shake"
    case wave = "Wave"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bounce: "arrow.up.and.down"
        case .orbit: "arrow.triangle.2.circlepath"
        case .shake: "waveform"
        case .wave: "water.waves"
        }
    }

    var color: Color {
        switch self {
        case .bounce: .blue
        case .orbit: .purple
        case .shake: .red
        case .wave: .teal
        }
    }

    var emoji: String {
        switch self {
        case .bounce: "🏀"
        case .orbit: "🪐"
        case .shake: "📳"
        case .wave: "🌊"
        }
    }
}

struct KeyframeAnimationsView: View {
    @State private var selectedPreset: KeyframePreset = .bounce
    @State private var playTrigger = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            animationStage
            Spacer()
            presetPicker
            playButton
                .padding(.bottom, 32)
        }
    }

    // MARK: - Stage

    private var animationStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(height: 300)

            switch selectedPreset {
            case .bounce:
                bounceAnimation
            case .orbit:
                orbitAnimation
            case .shake:
                shakeAnimation
            case .wave:
                waveAnimation
            }
        }
        .padding(.horizontal, 16)
    }

    private var bounceAnimation: some View {
        KeyframeAnimator(initialValue: AnimationValues(), trigger: playTrigger) { values in
            Text("🏀")
                .font(.system(size: 64))
                .offset(x: values.xOffset, y: values.yOffset)
                .scaleEffect(values.scale)
                .rotationEffect(.degrees(values.rotation))
        } keyframes: { _ in
            KeyframeTrack(\.yOffset) {
                SpringKeyframe(0, duration: 0.2)
                SpringKeyframe(-80, duration: 0.3, spring: .bouncy)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                SpringKeyframe(-40, duration: 0.25, spring: .bouncy)
                SpringKeyframe(0, duration: 0.25, spring: .bouncy)
                SpringKeyframe(-15, duration: 0.2, spring: .bouncy)
                SpringKeyframe(0, duration: 0.2, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.0, duration: 0.2)
                LinearKeyframe(0.85, duration: 0.15)
                LinearKeyframe(1.2, duration: 0.15)
                LinearKeyframe(1.0, duration: 0.3)
                LinearKeyframe(0.9, duration: 0.15)
                LinearKeyframe(1.1, duration: 0.15)
                LinearKeyframe(1.0, duration: 0.35)
            }
            KeyframeTrack(\.rotation) {
                LinearKeyframe(0, duration: 0.5)
                LinearKeyframe(15, duration: 0.2)
                LinearKeyframe(-10, duration: 0.2)
                LinearKeyframe(5, duration: 0.2)
                LinearKeyframe(0, duration: 0.35)
            }
        }
    }

    private var orbitAnimation: some View {
        KeyframeAnimator(initialValue: AnimationValues(), trigger: playTrigger) { values in
            Text("🪐")
                .font(.system(size: 64))
                .offset(x: values.xOffset, y: values.yOffset)
                .scaleEffect(values.scale)
                .rotationEffect(.degrees(values.rotation))
        } keyframes: { _ in
            KeyframeTrack(\.xOffset) {
                LinearKeyframe(80, duration: 0.4)
                LinearKeyframe(0, duration: 0.4)
                LinearKeyframe(-80, duration: 0.4)
                LinearKeyframe(0, duration: 0.4)
            }
            KeyframeTrack(\.yOffset) {
                LinearKeyframe(0, duration: 0.4)
                LinearKeyframe(-60, duration: 0.4)
                LinearKeyframe(0, duration: 0.4)
                LinearKeyframe(60, duration: 0.4)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.2, duration: 0.4)
                LinearKeyframe(1.0, duration: 0.4)
                LinearKeyframe(0.8, duration: 0.4)
                LinearKeyframe(1.0, duration: 0.4)
            }
            KeyframeTrack(\.rotation) {
                LinearKeyframe(360, duration: 1.6)
            }
        }
    }

    private var shakeAnimation: some View {
        KeyframeAnimator(initialValue: AnimationValues(), trigger: playTrigger) { values in
            Text("📳")
                .font(.system(size: 64))
                .offset(x: values.xOffset, y: values.yOffset)
                .scaleEffect(values.scale)
                .opacity(values.opacity)
        } keyframes: { _ in
            KeyframeTrack(\.xOffset) {
                LinearKeyframe(-20, duration: 0.06)
                LinearKeyframe(20, duration: 0.06)
                LinearKeyframe(-15, duration: 0.06)
                LinearKeyframe(15, duration: 0.06)
                LinearKeyframe(-10, duration: 0.06)
                LinearKeyframe(10, duration: 0.06)
                LinearKeyframe(-5, duration: 0.06)
                LinearKeyframe(0, duration: 0.06)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.3, duration: 0.12)
                LinearKeyframe(1.0, duration: 0.36)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(0.5, duration: 0.06)
                LinearKeyframe(1.0, duration: 0.06)
                LinearKeyframe(0.5, duration: 0.06)
                LinearKeyframe(1.0, duration: 0.06)
                LinearKeyframe(0.5, duration: 0.06)
                LinearKeyframe(1.0, duration: 0.22)
            }
        }
    }

    private var waveAnimation: some View {
        KeyframeAnimator(initialValue: AnimationValues(), trigger: playTrigger) { values in
            Text("🌊")
                .font(.system(size: 64))
                .offset(x: values.xOffset, y: values.yOffset)
                .scaleEffect(values.scale)
                .rotationEffect(.degrees(values.rotation))
        } keyframes: { _ in
            KeyframeTrack(\.yOffset) {
                SpringKeyframe(-30, duration: 0.3, spring: .smooth)
                SpringKeyframe(20, duration: 0.3, spring: .smooth)
                SpringKeyframe(-20, duration: 0.3, spring: .smooth)
                SpringKeyframe(15, duration: 0.3, spring: .smooth)
                SpringKeyframe(0, duration: 0.3, spring: .smooth)
            }
            KeyframeTrack(\.xOffset) {
                LinearKeyframe(40, duration: 0.375)
                LinearKeyframe(-40, duration: 0.75)
                LinearKeyframe(0, duration: 0.375)
            }
            KeyframeTrack(\.rotation) {
                LinearKeyframe(-10, duration: 0.375)
                LinearKeyframe(10, duration: 0.75)
                LinearKeyframe(0, duration: 0.375)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.2, duration: 0.3)
                LinearKeyframe(0.9, duration: 0.3)
                LinearKeyframe(1.1, duration: 0.3)
                LinearKeyframe(1.0, duration: 0.6)
            }
        }
    }

    // MARK: - Controls

    private var presetPicker: some View {
        HStack(spacing: 12) {
            ForEach(KeyframePreset.allCases) { preset in
                Button {
                    selectedPreset = preset
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: preset.icon)
                            .font(.title3)
                        Text(preset.rawValue)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(selectedPreset == preset ? .white : preset.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPreset == preset ? preset.color : preset.color.opacity(0.12))
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var playButton: some View {
        Button {
            playTrigger += 1
        } label: {
            Label("Play", systemImage: "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        KeyframeAnimationsView()
            .navigationTitle("Keyframe Animations")
    }
}
