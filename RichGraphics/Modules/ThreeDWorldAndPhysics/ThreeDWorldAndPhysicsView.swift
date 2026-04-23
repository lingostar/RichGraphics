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
                title: "SpriteKit Physics",
                footer: "2D 물리엔진 — 중력, 충돌, 경계",
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Gravity Balls",
                        description: "탭으로 공 생성, 디바이스 기울기로 중력 방향 제어",
                        icon: "circle.fill",
                        color: .blue
                    ) {
                        GravityBallsView()
                    },
                ]
            ),
            ThreeDWorldAndPhysicsSection(
                title: "3D World",
                footer: "SceneKit으로 만드는 3D 장면",
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Solar System",
                        description: "태양 + 5행성 공전, 달, 속도 조절",
                        icon: "globe.europe.africa.fill",
                        color: .indigo
                    ) {
                        SolarSystemView()
                    },
                ]
            ),
            ThreeDWorldAndPhysicsSection(
                title: "Particle Effects",
                footer: "CAEmitterLayer 기반 파티클 시스템",
                demos: [
                    ThreeDWorldAndPhysicsDemo(
                        title: "Weather",
                        description: "눈, 비, 벚꽃 파티클",
                        icon: "cloud.snow.fill",
                        color: .cyan
                    ) {
                        WeatherView()
                    },
                    ThreeDWorldAndPhysicsDemo(
                        title: "Confetti",
                        description: "버튼 트리거 + 연속 모드 축하 이펙트",
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
