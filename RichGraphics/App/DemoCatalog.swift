import SwiftUI

// MARK: - Catalog
//
// Centralized list of every demo in the app, grouped by parent module.
// Used by the iPad sidebar so that sub-demos are directly addressable
// from the sidebar (no extra "module list" middle step on iPad).

struct DemoEntry: Identifiable, Hashable {
    let id: String
    let module: DemoModule
    let title: String
    let description: String
    let icon: String
    let color: Color

    static func == (lhs: DemoEntry, rhs: DemoEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
enum DemoCatalog {
    static let allEntries: [DemoEntry] = [
        // SwiftUI Animations
        DemoEntry(id: "swiftui.spring",     module: .swiftUIAnimations, title: "Spring Playground",   description: "Tune spring parameters and compare curves in real time", icon: "waveform.path.ecg", color: .purple),
        DemoEntry(id: "swiftui.morphing",   module: .swiftUIAnimations, title: "Morphing Shapes",     description: "Custom shapes with animatableData morph between forms", icon: "pentagon", color: .orange),
        DemoEntry(id: "swiftui.keyframe",   module: .swiftUIAnimations, title: "Keyframe Animations", description: "시간 축에 여러 프로퍼티를 동시에 보간 — 복잡한 동작 시퀀스", icon: "film.stack", color: .blue),
        DemoEntry(id: "swiftui.phase",      module: .swiftUIAnimations, title: "Phase Animations",    description: "여러 상태를 자동 순환 — 로딩, 펄스, 상태 표시", icon: "circle.hexagongrid", color: .green),

        // Drawing Canvas
        DemoEntry(id: "drawing.freehand",   module: .drawingCanvas, title: "Freehand Drawing",  description: "CoreGraphics 기반 자유 드로잉, 색상/굵기 조절, undo/redo", icon: "hand.draw", color: .orange),
        DemoEntry(id: "drawing.pencilkit",  module: .drawingCanvas, title: "PencilKit Canvas",  description: "PKCanvasView + PKToolPicker 통합, 이미지 내보내기", icon: "pencil.tip.crop.circle", color: .blue),
        DemoEntry(id: "drawing.shape",      module: .drawingCanvas, title: "Shape Builder",     description: "선·사각형·원·삼각형 그리기와 색상 조합", icon: "rectangle.on.rectangle", color: .green),

        // 3D World & Physics
        DemoEntry(id: "physics.gravity",    module: .threeDWorldAndPhysics, title: "Gravity Balls", description: "탭으로 공 생성, 디바이스 기울기로 중력 방향 제어", icon: "circle.fill", color: .blue),
        DemoEntry(id: "physics.solar",      module: .threeDWorldAndPhysics, title: "Solar System",  description: "태양 + 5행성 공전, 달, 속도 조절", icon: "globe.europe.africa.fill", color: .indigo),
        DemoEntry(id: "physics.weather",    module: .threeDWorldAndPhysics, title: "Weather",       description: "눈, 비, 벚꽃 파티클", icon: "cloud.snow.fill", color: .cyan),
        DemoEntry(id: "physics.confetti",   module: .threeDWorldAndPhysics, title: "Confetti",      description: "버튼 트리거 + 연속 모드 축하 이펙트", icon: "party.popper.fill", color: .pink),

        // Image Filters
        DemoEntry(id: "filter.gallery",     module: .imageFilters, title: "Filter Gallery",     description: "15개 Core Image 필터 + 강도 슬라이더", icon: "photo.on.rectangle", color: .pink),
        DemoEntry(id: "filter.camera",      module: .imageFilters, title: "Camera Filters",     description: "AVCaptureSession 실시간 카메라 필터 8종", icon: "camera", color: .red),
        DemoEntry(id: "filter.chain",       module: .imageFilters, title: "Filter Chain Builder", description: "최대 5개 필터를 스택으로 연결하는 파이프라인", icon: "rectangle.stack", color: .purple),
        DemoEntry(id: "filter.custom",      module: .imageFilters, title: "Custom Effects",     description: "글리치·빈티지·팝아트·네온 + before/after 비교", icon: "sparkles", color: .orange),

        // UIKit Dynamics
        DemoEntry(id: "uikit.cards",        module: .uiKitDynamics, title: "Gravity Cards",      description: "카드에 중력+충돌, 디바이스 기울기 (Portrait Lock)", icon: "rectangle.stack.fill", color: .teal),
        DemoEntry(id: "uikit.snap",         module: .uiKitDynamics, title: "Snap Grid",          description: "드래그 후 가장 가까운 그리드 위치로 snap", icon: "square.grid.3x3", color: .blue),
        DemoEntry(id: "uikit.bubbles",      module: .uiKitDynamics, title: "Collision Bubbles",  description: "버블 충돌과 탭으로 미는 push behavior", icon: "circle.grid.cross", color: .purple),
        DemoEntry(id: "uikit.pendulum",     module: .uiKitDynamics, title: "Pendulum",           description: "UIAttachmentBehavior로 만든 뉴턴의 요람", icon: "atom", color: .gray),
        DemoEntry(id: "uikit.elastic",      module: .uiKitDynamics, title: "Elastic Menu",       description: "스프링 연결된 메뉴, 항목 간 체인 따라가기", icon: "list.bullet", color: .orange),
    ]

    static func entries(for module: DemoModule) -> [DemoEntry] {
        allEntries.filter { $0.module == module }
    }

    @MainActor @ViewBuilder
    static func destinationView(for entry: DemoEntry) -> some View {
        switch entry.id {
        // SwiftUI
        case "swiftui.spring":    SpringPlaygroundView()
        case "swiftui.morphing":  MorphingShapesView()
        case "swiftui.keyframe":  KeyframeAnimationsView()
        case "swiftui.phase":     PhaseAnimationsView()
        // Drawing
        case "drawing.freehand":  FreehandDrawingView()
        case "drawing.pencilkit": PencilKitCanvasView()
        case "drawing.shape":     ShapeBuilderView()
        // 3D & Physics
        case "physics.gravity":   GravityBallsView()
        case "physics.solar":     SolarSystemView()
        case "physics.weather":   WeatherView()
        case "physics.confetti":  ConfettiView()
        // Image Filters
        case "filter.gallery":    FilterGalleryView()
        case "filter.camera":     CameraFiltersView()
        case "filter.chain":      FilterChainBuilderView()
        case "filter.custom":     CustomEffectsView()
        // UIKit Dynamics
        case "uikit.cards":       GravityCardsView()
        case "uikit.snap":        SnapGridView()
        case "uikit.bubbles":     CollisionBubblesView()
        case "uikit.pendulum":    PendulumView()
        case "uikit.elastic":     ElasticMenuView()
        default:                  Text("Demo not found").foregroundStyle(.secondary)
        }
    }
}
