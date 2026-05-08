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
        DemoEntry(id: "swiftui.spring",     module: .swiftUIAnimations, title: "Spring Playground",   description: String(localized: "Tune spring parameters and compare curves in real time"), icon: "waveform.path.ecg", color: .purple),
        DemoEntry(id: "swiftui.morphing",   module: .swiftUIAnimations, title: "Morphing Shapes",     description: String(localized: "Custom shapes with animatableData morph between forms"), icon: "pentagon", color: .orange),
        DemoEntry(id: "swiftui.keyframe",   module: .swiftUIAnimations, title: "Keyframe Animations", description: String(localized: "Interpolate multiple properties along a timeline — complex motion sequences"), icon: "film.stack", color: .blue),
        DemoEntry(id: "swiftui.phase",      module: .swiftUIAnimations, title: "Phase Animations",    description: String(localized: "Auto-cycle through multiple states — loading, pulse, status indicators"), icon: "circle.hexagongrid", color: .green),

        // Drawing Canvas
        DemoEntry(id: "drawing.pencilkit",  module: .drawingCanvas, title: "PencilKit Canvas",  description: String(localized: "PKCanvasView + PKToolPicker integration with image export"), icon: "pencil.tip.crop.circle", color: .blue),
        DemoEntry(id: "drawing.freehand",   module: .drawingCanvas, title: "Freehand Drawing",  description: String(localized: "CoreGraphics freehand drawing with color, thickness, undo/redo"), icon: "hand.draw", color: .orange),
        DemoEntry(id: "drawing.shape",      module: .drawingCanvas, title: "Shape Builder",     description: String(localized: "Draw lines, rectangles, circles, and triangles with color combinations"), icon: "rectangle.on.rectangle", color: .green),

        // 3D World & Physics
        DemoEntry(id: "physics.gravity",    module: .threeDWorldAndPhysics, title: "Gravity Balls", description: String(localized: "Tap to spawn balls; tilt the device to steer gravity"), icon: "circle.fill", color: .blue),
        DemoEntry(id: "physics.solar",      module: .threeDWorldAndPhysics, title: "Solar System",  description: String(localized: "Sun + 5 planets orbit, with Moon and speed control"), icon: "globe.europe.africa.fill", color: .indigo),
        DemoEntry(id: "physics.weather",    module: .threeDWorldAndPhysics, title: "Weather",       description: String(localized: "Snow, rain, and cherry blossom particles"), icon: "cloud.snow.fill", color: .cyan),
        DemoEntry(id: "physics.confetti",   module: .threeDWorldAndPhysics, title: "Confetti",      description: String(localized: "Button-triggered or continuous celebration effect"), icon: "party.popper.fill", color: .pink),

        // Image Filters
        DemoEntry(id: "filter.gallery",     module: .imageFilters, title: "Filter Gallery",     description: String(localized: "15 Core Image filters with intensity sliders"), icon: "photo.on.rectangle", color: .pink),
        DemoEntry(id: "filter.camera",      module: .imageFilters, title: "Camera Filters",     description: String(localized: "8 real-time camera filters via AVCaptureSession"), icon: "camera", color: .red),
        DemoEntry(id: "filter.chain",       module: .imageFilters, title: "Filter Chain Builder", description: String(localized: "Stack up to 5 filters into a custom pipeline"), icon: "rectangle.stack", color: .purple),
        DemoEntry(id: "filter.custom",      module: .imageFilters, title: "Custom Effects",     description: String(localized: "Glitch, vintage, pop art, and neon — with before/after compare"), icon: "sparkles", color: .orange),

        // UIKit Dynamics
        DemoEntry(id: "uikit.cards",        module: .uiKitDynamics, title: "Gravity Cards",      description: String(localized: "Cards with gravity and collision via device tilt (Portrait Lock)"), icon: "rectangle.stack.fill", color: .teal),
        DemoEntry(id: "uikit.snap",         module: .uiKitDynamics, title: "Snap Grid",          description: String(localized: "Drag and snap to the nearest grid position"), icon: "square.grid.3x3", color: .blue),
        DemoEntry(id: "uikit.bubbles",      module: .uiKitDynamics, title: "Collision Bubbles",  description: String(localized: "Bubble collisions with tap-to-push behavior"), icon: "circle.grid.cross", color: .purple),
        DemoEntry(id: "uikit.pendulum",     module: .uiKitDynamics, title: "Pendulum",           description: String(localized: "Newton's cradle built with UIAttachmentBehavior"), icon: "atom", color: .gray),
        DemoEntry(id: "uikit.elastic",      module: .uiKitDynamics, title: "Elastic Menu",       description: String(localized: "Spring-connected menu with chained item follow"), icon: "list.bullet", color: .orange),
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
