import SwiftUI

struct SpringPlaygroundView: View {
    @State private var response: Double = 0.5
    @State private var dampingFraction: Double = 0.5
    @State private var blendDuration: Double = 0.0
    @State private var animated = false
    @State private var selectedPreset: SpringPreset = .bouncy

    private enum SpringPreset: String, CaseIterable, Identifiable {
        case bouncy, smooth, snappy, custom
        var id: String { rawValue }

        var label: String {
            rawValue.capitalized
        }
    }

    private var currentSpring: Animation {
        switch selectedPreset {
        case .bouncy:
            .spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0)
        case .smooth:
            .spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0)
        case .snappy:
            .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
        case .custom:
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }

    private let shapes: [(Color, CGFloat)] = [
        (.purple, 60), (.blue, 50), (.teal, 55),
        (.green, 45), (.orange, 50), (.pink, 55),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                animationArea
                controlsSection
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Animation Area

    private var animationArea: some View {
        ZStack {
            ForEach(Array(shapes.enumerated()), id: \.offset) { index, item in
                let angle = Double(index) * (.pi * 2.0 / Double(shapes.count))
                let (color, size) = item
                Group {
                    if index.isMultiple(of: 2) {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: size, height: size)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.gradient)
                            .frame(width: size, height: size)
                    }
                }
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                .offset(
                    x: animated ? cos(angle) * 110 : 0,
                    y: animated ? sin(angle) * 110 : 0
                )
                .scaleEffect(animated ? 1.0 : 0.3)
                .opacity(animated ? 1.0 : 0.5)
                .rotationEffect(.degrees(animated ? Double(index) * 60 : 0))
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 16) {
            Picker("Preset", selection: $selectedPreset) {
                ForEach(SpringPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if selectedPreset == .custom {
                VStack(spacing: 14) {
                    sliderRow(title: "Response", value: $response, range: 0.1...2.0)
                    sliderRow(title: "Damping", value: $dampingFraction, range: 0.05...1.0)
                    sliderRow(title: "Blend", value: $blendDuration, range: 0.0...1.0)
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                withAnimation(currentSpring) {
                    animated.toggle()
                }
            } label: {
                Text(animated ? "Collapse" : "Expand")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.purple.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title): \(value.wrappedValue, specifier: "%.2f")")
                .font(.subheadline.monospaced())
            Slider(value: value, in: range, step: 0.05)
        }
    }
}

#Preview {
    NavigationStack {
        SpringPlaygroundView()
            .navigationTitle("Spring Playground")
    }
}
