import SwiftUI

// Consolidated module that merges three previously-separate modules:
// - SpriteKit Physics
// - 3D World (SceneKit / Metal)
// - Particle Effects
//
// Only the curated sub-demos are exposed; the hidden demos live in their
// original folders and can be re-enabled later.

struct ThreeDWorldAndPhysicsDemo: Identifiable {
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

struct ThreeDWorldAndPhysicsSection: Identifiable {
    let id = UUID()
    let title: String
    let footer: String?
    let demos: [ThreeDWorldAndPhysicsDemo]
}

struct ThreeDWorldAndPhysicsView: View {
    @MainActor
    private var sections: [ThreeDWorldAndPhysicsSection] {
        [
            ThreeDWorldAndPhysicsSection(
                title: String(localized: "SpriteKit Physics"),
                footer: String(localized: "2D physics engine — gravity, collision, bounds"),
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Gravity Balls",
                        description: String(localized: "Tap to spawn balls; tilt the device to steer gravity"),
                        icon: "circle.fill",
                        color: .blue
                    ) {
                        GravityBallsView()
                    },
                ]
            ),
            ThreeDWorldAndPhysicsSection(
                title: String(localized: "3D World"),
                footer: String(localized: "3D scenes built with SceneKit"),
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Solar System",
                        description: String(localized: "Sun + 5 planets orbit, with Moon and speed control"),
                        icon: "globe.europe.africa.fill",
                        color: .indigo
                    ) {
                        SolarSystemView()
                    },
                ]
            ),
            ThreeDWorldAndPhysicsSection(
                title: String(localized: "Particle Effects"),
                footer: String(localized: "Particle systems based on CAEmitterLayer"),
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Weather",
                        description: String(localized: "Snow, rain, and cherry blossom particles"),
                        icon: "cloud.snow.fill",
                        color: .cyan
                    ) {
                        WeatherView()
                    },
                    ThreeDWorldAndPhysicsDemo(
                        title: "Confetti",
                        description: String(localized: "Button-triggered or continuous celebration effect"),
                        icon: "party.popper.fill",
                        color: .pink
                    ) {
                        ConfettiView()
                    },
                ]
            ),
        ]
    }

    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.demos) { demo in
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
                } header: {
                    Text(section.title)
                        .font(.subheadline.bold())
                        .textCase(nil)
                } footer: {
                    if let footer = section.footer {
                        Text(footer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        ThreeDWorldAndPhysicsView()
            .navigationTitle("3D World & Physics")
    }
}
