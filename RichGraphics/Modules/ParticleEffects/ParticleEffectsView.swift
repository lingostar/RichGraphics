import SwiftUI

struct ParticleDemo: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView

    @MainActor
    init<V: View>(title: String, description: String, icon: String, color: Color, @ViewBuilder destination: () -> V) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.destination = AnyView(destination())
    }
}

struct ParticleEffectsView: View {
    @MainActor
    private var demos: [ParticleDemo] {
        [
            ParticleDemo(title: "Fireworks", description: "Tap to launch fireworks with explosive particle bursts", icon: "sparkles", color: .red) {
                FireworksView()
            },
            ParticleDemo(title: "Weather", description: "Snow, rain, and cherry blossom weather effects", icon: "cloud.snow", color: .cyan) {
                WeatherView()
            },
            ParticleDemo(title: "Fire & Smoke", description: "Realistic fire and smoke simulation with wind", icon: "flame", color: .orange) {
                FireSmokeView()
            },
            ParticleDemo(title: "Confetti Celebration", description: "Colorful confetti burst with tumbling particles", icon: "party.popper", color: .purple) {
                ConfettiView()
            },
            ParticleDemo(title: "Starfield", description: "Warp-speed starfield flying through space", icon: "star.circle", color: .indigo) {
                StarfieldView()
            },
            ParticleDemo(title: "Touch Trail", description: "Magical sparkle trail following your finger", icon: "hand.draw", color: .pink) {
                TouchTrailView()
            },
        ]
    }

    var body: some View {
        List(demos) { demo in
            NavigationLink {
                demo.destination
                    .navigationTitle(demo.title)
                    .disableSwipeBack()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: demo.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(demo.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(demo.title)
                            .font(.headline)
                        Text(demo.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        ParticleEffectsView()
            .navigationTitle("Particle Effects")
    }
}
