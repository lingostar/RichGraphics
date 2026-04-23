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

struct AnimationSection: Identifiable {
    let id = UUID()
    let title: String
    let footer: String?
    let demos: [AnimationDemo]
}

struct SwiftUIAnimationsView: View {
    @MainActor
    private var sections: [AnimationSection] {
        [
            AnimationSection(
                title: "Foundations",
                footer: "값 변화를 보간하는 기본 애니메이션 패턴",
                demos: [
                    AnimationDemo(title: "Spring Playground", description: "Tune spring parameters and compare curves in real time", icon: "waveform.path.ecg", color: .purple) {
                        SpringPlaygroundView()
                    },
                    AnimationDemo(title: "Morphing Shapes", description: "Custom shapes with animatableData morph between forms", icon: "pentagon", color: .orange) {
                        MorphingShapesView()
                    },
                ]
            ),
            AnimationSection(
                title: "iOS 17 Multi-State APIs",
                footer: "여러 단계를 순차적으로 다루는 iOS 17의 새 애니메이션 API",
                demos: [
                    AnimationDemo(title: "Keyframe Animations", description: "시간 축에 여러 프로퍼티를 동시에 보간 — 복잡한 동작 시퀀스", icon: "film.stack", color: .blue) {
                        KeyframeAnimationsView()
                    },
                    AnimationDemo(title: "Phase Animations", description: "여러 상태를 자동 순환 — 로딩, 펄스, 상태 표시", icon: "circle.hexagongrid", color: .green) {
                        PhaseAnimationsView()
                    },
                ]
            ),
            AnimationSection(
                title: "Transitions & Effects",
                footer: "뷰 전환과 시각 효과",
                demos: [
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
        SwiftUIAnimationsView()
            .navigationTitle("SwiftUI Animations")
    }
}
