import SwiftUI

struct PhysicsDemo: Identifiable {
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

struct SpriteKitPhysicsView: View {
    @MainActor
    private var demos: [PhysicsDemo] {
        [
            PhysicsDemo(
                title: "Gravity Balls",
                description: "Tap to spawn colorful balls with real gravity and device tilt",
                icon: "circle.circle.fill",
                color: .blue
            ) {
                GravityBallsView()
            },
            PhysicsDemo(
                title: "Ragdoll Playground",
                description: "Drag and fling a jointed ragdoll with realistic physics",
                icon: "figure.fall",
                color: .orange
            ) {
                RagdollPlaygroundView()
            },
            PhysicsDemo(
                title: "Fluid Simulation",
                description: "Touch to spawn fluid particles with surface tension effects",
                icon: "drop.fill",
                color: .cyan
            ) {
                FluidSimulationView()
            },
            PhysicsDemo(
                title: "Breakout Mini-Game",
                description: "Classic brick-breaker with paddle, ball, and score tracking",
                icon: "rectangle.split.3x3.fill",
                color: .red
            ) {
                BreakoutGameView()
            },
            PhysicsDemo(
                title: "Magnetic Field",
                description: "Place attractors and repellers to control floating particles",
                icon: "magnet",
                color: .purple
            ) {
                MagneticFieldView()
            },
            PhysicsDemo(
                title: "Destruction Physics",
                description: "Tap shapes to shatter them into flying fragments",
                icon: "bolt.trianglebadge.exclamationmark.fill",
                color: .pink
            ) {
                DestructionPhysicsView()
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
        SpriteKitPhysicsView()
            .navigationTitle("SpriteKit Physics")
    }
}
