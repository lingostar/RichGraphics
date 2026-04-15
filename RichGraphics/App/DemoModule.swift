import SwiftUI

enum DemoModule: String, CaseIterable, Identifiable {
    case swiftUIAnimations
    case drawingCanvas
    case spriteKitPhysics
    case sceneKit3D
    case imageFilters
    case particleEffects
    case uiKitDynamics

    var id: String { rawValue }

    var name: String {
        switch self {
        case .swiftUIAnimations: "SwiftUI Animations"
        case .drawingCanvas: "Drawing Canvas"
        case .spriteKitPhysics: "SpriteKit Physics"
        case .sceneKit3D: "3D World"
        case .imageFilters: "Image Filters"
        case .particleEffects: "Particle Effects"
        case .uiKitDynamics: "UIKit Dynamics"
        }
    }

    var description: String {
        switch self {
        case .swiftUIAnimations: "Spring animations with adjustable parameters"
        case .drawingCanvas: "Freehand drawing with CoreGraphics"
        case .spriteKitPhysics: "Tap to drop bouncing balls with gravity"
        case .sceneKit3D: "Interactive rotating 3D cube"
        case .imageFilters: "Live Core Image filter effects"
        case .particleEffects: "CAEmitterLayer confetti and snow"
        case .uiKitDynamics: "Gravity and collision dynamics"
        }
    }

    var iconName: String {
        switch self {
        case .swiftUIAnimations: "wand.and.stars"
        case .drawingCanvas: "paintbrush.pointed"
        case .spriteKitPhysics: "atom"
        case .sceneKit3D: "cube.transparent"
        case .imageFilters: "camera.filters"
        case .particleEffects: "sparkles"
        case .uiKitDynamics: "arrow.triangle.bounce"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .swiftUIAnimations:
            LinearGradient(colors: [.purple, .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .drawingCanvas:
            LinearGradient(colors: [.orange, .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .spriteKitPhysics:
            LinearGradient(colors: [.blue, .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sceneKit3D:
            LinearGradient(colors: [.green, .green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .imageFilters:
            LinearGradient(colors: [.pink, .pink.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .particleEffects:
            LinearGradient(colors: [.red, .red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .uiKitDynamics:
            LinearGradient(colors: [.teal, .teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    @MainActor @ViewBuilder
    var destinationView: some View {
        switch self {
        case .swiftUIAnimations: SwiftUIAnimationsView()
        case .drawingCanvas: DrawingCanvasView()
        case .spriteKitPhysics: SpriteKitPhysicsView()
        case .sceneKit3D: SceneKit3DView()
        case .imageFilters: ImageFiltersView()
        case .particleEffects: ParticleEffectsView()
        case .uiKitDynamics: UIKitDynamicsView()
        }
    }
}
