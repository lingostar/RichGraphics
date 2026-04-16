import SwiftUI

struct AnimationDemo: Identifiable {
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

struct SwiftUIAnimationsView: View {
    @MainActor
    private var demos: [AnimationDemo] {
        [
            AnimationDemo(title: "Spring Playground", description: "Tune spring parameters and compare curves in real time", icon: "waveform.path.ecg", color: .purple) {
                SpringPlaygroundView()
            },
            AnimationDemo(title: "Morphing Shapes", description: "Custom shapes with animatableData morph between forms", icon: "pentagon", color: .orange) {
                MorphingShapesView()
            },
            AnimationDemo(title: "Keyframe Animations", description: "Multi-property keyframe sequences with iOS 17 API", icon: "film.stack", color: .blue) {
                KeyframeAnimationsView()
            },
            AnimationDemo(title: "Phase Animations", description: "State-machine animations using PhaseAnimator", icon: "circle.hexagongrid", color: .green) {
                PhaseAnimationsView()
            },
            AnimationDemo(title: "Matched Geometry", description: "Hero transitions with shared element effects", icon: "rectangle.on.rectangle.angled", color: .pink) {
                MatchedGeometryView()
            },
            AnimationDemo(title: "Custom Transitions", description: "Build unique AnyTransition effects from scratch", icon: "rectangle.2.swap", color: .teal) {
                CustomTransitionsView()
            },
            AnimationDemo(title: "Scroll Effects", description: "ScrollView visual effects with parallax and 3D rotation", icon: "scroll", color: .indigo) {
                ScrollEffectsView()
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
        SwiftUIAnimationsView()
            .navigationTitle("SwiftUI Animations")
    }
}
