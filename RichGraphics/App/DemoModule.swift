import SwiftUI

enum DemoModule: String, CaseIterable, Identifiable {
    case swiftUIAnimations
    case drawingCanvas
    case threeDWorldAndPhysics
    case imageFilters
    case uiKitDynamics

    var id: String { rawValue }

    var name: String {
        switch self {
        case .swiftUIAnimations: "SwiftUI Animations"
        case .drawingCanvas: "Drawing Canvas"
        case .threeDWorldAndPhysics: "3D World & Physics"
        case .imageFilters: "Image Filters"
        case .uiKitDynamics: "UIKit Dynamics"
        }
    }

    var description: String {
        switch self {
        case .swiftUIAnimations: "Spring animations with adjustable parameters"
        case .drawingCanvas: "Freehand drawing with CoreGraphics"
        case .threeDWorldAndPhysics: "SpriteKit, SceneKit and particle systems"
        case .imageFilters: "Live Core Image filter effects"
        case .uiKitDynamics: "Gravity and collision dynamics"
        }
    }

    var iconName: String {
        switch self {
        case .swiftUIAnimations: "wand.and.stars"
        case .drawingCanvas: "paintbrush.pointed"
        case .threeDWorldAndPhysics: "cube.transparent"
        case .imageFilters: "camera.filters"
        case .uiKitDynamics: "arrow.triangle.bounce"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .swiftUIAnimations:
            LinearGradient(colors: [.purple, .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .drawingCanvas:
            LinearGradient(colors: [.orange, .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .threeDWorldAndPhysics:
            LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .imageFilters:
            LinearGradient(colors: [.pink, .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .uiKitDynamics:
            LinearGradient(colors: [.teal, .teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    @MainActor @ViewBuilder
    var destinationView: some View {
        switch self {
        case .swiftUIAnimations: SwiftUIAnimationsView()
        case .drawingCanvas: DrawingCanvasView()
        case .threeDWorldAndPhysics: ThreeDWorldAndPhysicsView()
        case .imageFilters: ImageFiltersView()
        case .uiKitDynamics: UIKitDynamicsView()
        }
    }
}
