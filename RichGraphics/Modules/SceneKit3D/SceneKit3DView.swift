import SwiftUI

struct SceneKit3DDemo: Identifiable {
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

struct SceneKit3DView: View {
    @MainActor
    private var demos: [SceneKit3DDemo] {
        [
            SceneKit3DDemo(
                title: "3D Model Viewer",
                description: "Explore primitives with material and lighting controls",
                icon: "cube.fill",
                color: .blue
            ) { ModelViewerView() },
            SceneKit3DDemo(
                title: "Procedural Geometry",
                description: "Generate terrain with height maps and vegetation",
                icon: "mountain.2.fill",
                color: .green
            ) { ProceduralGeometryView() },
            SceneKit3DDemo(
                title: "Hologram Effect",
                description: "Sci-fi wireframe with scanlines and glitch effects",
                icon: "waveform",
                color: .cyan
            ) { HologramEffectView() },
            SceneKit3DDemo(
                title: "Solar System",
                description: "Animated orbiting planets around the sun",
                icon: "sun.max.fill",
                color: .orange
            ) { SolarSystemView() },
            SceneKit3DDemo(
                title: "Shader Playground",
                description: "Realtime shader modifiers: plasma, ripple, noise",
                icon: "paintpalette.fill",
                color: .purple
            ) { ShaderPlaygroundView() },
        ]
    }

    var body: some View {
        List(demos) { demo in
            NavigationLink {
                demo.destination
                    .navigationTitle(demo.title)
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
        SceneKit3DView()
            .navigationTitle("SceneKit 3D")
    }
}
