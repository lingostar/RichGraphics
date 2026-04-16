import SwiftUI

private enum ScrollPreset: String, CaseIterable, Identifiable {
    case scaleFade = "Scale & Fade"
    case rotation3D = "3D Carousel"
    case parallax = "Parallax"

    var id: String { rawValue }
}

struct ScrollEffectsView: View {
    @State private var selectedPreset: ScrollPreset = .scaleFade

    var body: some View {
        VStack(spacing: 0) {
            Picker("Effect", selection: $selectedPreset) {
                ForEach(ScrollPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            switch selectedPreset {
            case .scaleFade:
                scaleFadeScroll
            case .rotation3D:
                carouselScroll
            case .parallax:
                parallaxScroll
            }
        }
    }

    // MARK: - Scale & Fade

    private let verticalColors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .red, .indigo]

    private var scaleFadeScroll: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(verticalColors.enumerated()), id: \.offset) { index, color in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.gradient)
                        .frame(height: 160)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.largeTitle)
                                Text("Card \(index + 1)")
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.white)
                        )
                        .shadow(color: color.opacity(0.3), radius: 8, y: 4)
                        .scrollTransition(.animated(.spring())) { content, phase in
                            content
                                .scaleEffect(1.0 - abs(phase.value) * 0.15)
                                .opacity(1.0 - abs(phase.value) * 0.4)
                                .rotationEffect(.degrees(phase.value * 5))
                        }
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - 3D Carousel

    private let carouselColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .teal, .indigo, .mint]

    private var carouselScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(Array(carouselColors.enumerated()), id: \.offset) { index, color in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.gradient)
                        .frame(width: 220, height: 320)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "cube.transparent.fill")
                                    .font(.system(size: 40))
                                Text("Item \(index + 1)")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(.white)
                        )
                        .shadow(color: color.opacity(0.4), radius: 10, y: 6)
                        .scrollTransition(.animated(.spring()), axis: .horizontal) { content, phase in
                            content
                                .rotation3DEffect(
                                    .degrees(phase.value * 35),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.5
                                )
                                .scaleEffect(1.0 - abs(phase.value) * 0.15)
                        }
                }
            }
            .padding(.horizontal, 80)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Parallax

    private let parallaxItems: [(String, Color, String)] = [
        ("mountain.2.fill", .blue, "Mountains"),
        ("water.waves", .teal, "Ocean"),
        ("sun.max.fill", .orange, "Sunset"),
        ("leaf.fill", .green, "Forest"),
        ("snowflake", .cyan, "Winter"),
        ("cloud.sun.fill", .indigo, "Sky"),
    ]

    private var parallaxScroll: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(parallaxItems.enumerated()), id: \.offset) { index, item in
                    let (icon, color, title) = item
                    ZStack {
                        // Background color
                        Rectangle().fill(color.gradient)

                        // Decorative background icon with parallax via scrollTransition
                        Image(systemName: icon)
                            .font(.system(size: 120))
                            .foregroundStyle(.white.opacity(0.15))
                            .scrollTransition(.animated(.easeInOut)) { content, phase in
                                content
                                    .offset(y: phase.value * 40)
                            }

                        // Foreground content
                        VStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.system(size: 44))
                            Text(title)
                                .font(.title.bold())
                            Text("Section \(index + 1)")
                                .font(.subheadline)
                                .opacity(0.8)
                        }
                        .foregroundStyle(.white)
                        .scrollTransition(.animated(.easeInOut)) { content, phase in
                            content
                                .opacity(1.0 - abs(phase.value) * 0.6)
                                .scaleEffect(1.0 - abs(phase.value) * 0.1)
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollEffectsView()
            .navigationTitle("Scroll Effects")
    }
}
