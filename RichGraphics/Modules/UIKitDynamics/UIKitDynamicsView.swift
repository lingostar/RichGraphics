import SwiftUI

struct DynamicsDemo: Identifiable {
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

struct UIKitDynamicsView: View {
    @MainActor
    private var demos: [DynamicsDemo] {
        [
            DynamicsDemo(title: "Gravity Cards", description: "Cards that respond to device tilt with CoreMotion gravity", icon: "rectangle.on.rectangle.angled", color: .orange) {
                GravityCardsView()
            },
            DynamicsDemo(title: "Snap Grid", description: "Drag items and watch them snap to the nearest grid point", icon: "squareshape.split.3x3", color: .purple) {
                SnapGridView()
            },
            DynamicsDemo(title: "Collision Bubbles", description: "Floating tag bubbles that collide and bounce around", icon: "circle.hexagongrid", color: .blue) {
                CollisionBubblesView()
            },
            DynamicsDemo(title: "Pendulum", description: "Newton's cradle with realistic physics simulation", icon: "lines.measurement.horizontal", color: .red) {
                PendulumView()
            },
            DynamicsDemo(title: "Elastic Menu", description: "Spring-connected menu items with elastic follow behavior", icon: "list.bullet.rectangle", color: .green) {
                ElasticMenuView()
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
        UIKitDynamicsView()
            .navigationTitle("UIKit Dynamics")
    }
}
