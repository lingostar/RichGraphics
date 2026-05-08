import SwiftUI

// MARK: - Quiz Data Model
//
// A quiz is a sequence of QuizQuestion entries. Each question has:
// - The prompt text (shown first)
// - The answer (revealed with animation on "Reveal answer" tap)
// - Optional explanation content (comparison table, image, extended text, ...)
// The explanation is modelled as an enum so we can add new formats as we
// build out more quiz pages without forcing every question into the same shape.

// A quiz "page" is one of two kinds:
// - .question: an interactive Q&A page (the original concept)
// - .info: a non-interactive page (image + heading + body text), used for
//   things like "where to go next" wrap-up screens.

enum QuizPage: Identifiable {
    case question(QuizQuestion)
    case info(InfoPage)

    var id: UUID {
        switch self {
        case .question(let q): q.id
        case .info(let i): i.id
        }
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    /// 4 multiple-choice options. One of them must equal `answer`.
    let options: [String]
    let answer: String
    let explanation: QuizExplanation
}

struct InfoPage: Identifiable {
    let id = UUID()
    let imageName: String?
    let heading: String
    let body: String?
}

enum QuizExplanation {
    case comparisonTable(ComparisonTable)
    case text(String)
    case none
}

struct ComparisonTable {
    let headerA: String
    let headerB: String
    let rows: [ComparisonRow]
}

struct ComparisonRow: Identifiable {
    let id = UUID()
    let label: String
    let optionA: String
    let optionB: String
}

// MARK: - Catalogue

extension QuizPage {
    @MainActor static let all: [QuizPage] = QuizQuestion.all.map { .question($0) } + [
        // Final page — wrap-up direction
        .info(InfoPage(
            imageName: "FloorPlan5F",
            heading: String(localized: "Next: head to ML-Sound at Homigot"),
            body: nil
        )),
    ]
}

extension QuizQuestion {
    @MainActor static let all: [QuizQuestion] = [
        // Page 1 — Phase vs Keyframe
        QuizQuestion(
            question: String(localized: "Which SwiftUI animation type best fits a ball's motion path on a soccer field?"),
            options: [
                String(localized: "Phase Animation"),
                String(localized: "Keyframe Animation"),
                String(localized: "Spring Animation"),
                String(localized: "Morphing Animation"),
            ],
            answer: String(localized: "Keyframe Animation"),
            explanation: .comparisonTable(ComparisonTable(
                headerA: "PhaseAnimator",
                headerB: "KeyframeAnimator",
                rows: [
                    ComparisonRow(label: String(localized: "Role"),         optionA: String(localized: "State machine"),                          optionB: String(localized: "Timeline animation")),
                    ComparisonRow(label: String(localized: "Each step"),    optionA: String(localized: "Named phases"),                           optionB: String(localized: "Keyframes at absolute times")),
                    ComparisonRow(label: String(localized: "Control unit"), optionA: String(localized: "One phase = one static style"),          optionB: String(localized: "One property = time-based interpolation")),
                    ComparisonRow(label: String(localized: "Timing"),       optionA: String(localized: "Animation specified per phase transition"), optionB: String(localized: "Explicit time and curve control")),
                    ComparisonRow(label: String(localized: "Best for"),     optionA: String(localized: "Loading, pulse, status indicators"),     optionB: String(localized: "Complex motion sequences (bounce, trajectory)")),
                ]
            ))
        ),

        // Page 2 — CoreGraphics vs PencilKit
        QuizQuestion(
            question: String(localized: "Want to quickly build a writing app that responds to Apple Pencil pressure and tilt automatically?"),
            options: [
                "CoreGraphics",
                "UIKit Drawing",
                "SwiftUI Canvas",
                "PencilKit",
            ],
            answer: "PencilKit",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "CoreGraphics",
                headerB: "PencilKit",
                rows: [
                    ComparisonRow(label: String(localized: "Pressure & tilt"), optionA: String(localized: "Manual event handling"), optionB: String(localized: "Built-in automatic")),
                    ComparisonRow(label: String(localized: "Tool UI"),         optionA: String(localized: "Build it yourself"),     optionB: String(localized: "PKToolPicker provided")),
                    ComparisonRow(label: String(localized: "Save & restore"),  optionA: String(localized: "Manual serialization"),  optionB: String(localized: "PKDrawing automatic")),
                    ComparisonRow(label: String(localized: "Customization"),   optionA: String(localized: "Full freedom"),          optionB: String(localized: "Limited")),
                    ComparisonRow(label: String(localized: "Best for"),        optionA: String(localized: "Charts, custom drawing"), optionB: String(localized: "Notes, sketches, signatures")),
                ]
            ))
        ),

        // Page 3 — SpriteKit vs UIKit Dynamics
        QuizQuestion(
            question: String(localized: "Want to add only gravity and snap effects to UIView cards, without bringing in a full game engine?"),
            options: [
                "SpriteKit",
                "SceneKit",
                "UIKit Dynamics",
                "CoreAnimation",
            ],
            answer: "UIKit Dynamics",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "SpriteKit",
                headerB: "UIKit Dynamics",
                rows: [
                    ComparisonRow(label: String(localized: "Target"),             optionA: String(localized: "SKNode (game objects)"),           optionB: String(localized: "UIView (existing UI)")),
                    ComparisonRow(label: String(localized: "Coordinate system"),  optionA: String(localized: "Origin at bottom-left"),           optionB: String(localized: "Origin at top-left")),
                    ComparisonRow(label: String(localized: "Physics scope"),      optionA: String(localized: "Rich (joints, fields)"),           optionB: String(localized: "Basic (gravity, collision, snap)")),
                    ComparisonRow(label: String(localized: "SwiftUI integration"), optionA: "SpriteView",                                         optionB: "UIViewRepresentable"),
                    ComparisonRow(label: String(localized: "Best for"),           optionA: String(localized: "2D games, simulations"),           optionB: String(localized: "Card UI, elastic menus")),
                ]
            ))
        ),

        // Page 4 — SceneKit vs Metal
        QuizQuestion(
            question: String(localized: "Want to display a 3D model when extreme performance isn't critical?"),
            options: ["SceneKit", "Metal", "RealityKit", "SpriteKit"],
            answer: "SceneKit",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "SceneKit",
                headerB: "Metal",
                rows: [
                    ComparisonRow(label: String(localized: "Entry barrier"), optionA: String(localized: "Low (tens of lines)"),  optionB: String(localized: "Very high (hundreds of lines)")),
                    ComparisonRow(label: String(localized: "Customization"), optionA: String(localized: "Shader modifiers"),     optionB: String(localized: "Unlimited")),
                    ComparisonRow(label: String(localized: "Model loading"), optionA: String(localized: "USDZ/DAE built-in"),    optionB: String(localized: "Parse manually")),
                    ComparisonRow(label: String(localized: "Debugging"),     optionA: "Scene Editor",                            optionB: "GPU Frame Debugger"),
                    ComparisonRow(label: String(localized: "Best for"),      optionA: String(localized: "Product viewer, AR"),   optionB: String(localized: "Game engines, scientific visualization")),
                ]
            ))
        ),

        // Page 5 — Core Image vs Custom Metal Shader
        QuizQuestion(
            question: String(localized: "Want to quickly build a filter UI applying sepia and vignette to a photo?"),
            options: [
                "Metal Shader",
                "Core Image",
                "CoreGraphics",
                "AVFoundation",
            ],
            answer: "Core Image",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "Core Image",
                headerB: "Custom Metal Shader",
                rows: [
                    ComparisonRow(label: String(localized: "Built-in filters"), optionA: String(localized: "200+ ready to use"),     optionB: String(localized: "Write your own")),
                    ComparisonRow(label: String(localized: "Chaining"),         optionA: String(localized: "output → input simple"), optionB: String(localized: "Manual implementation")),
                    ComparisonRow(label: String(localized: "GPU acceleration"), optionA: String(localized: "Automatic"),             optionB: String(localized: "Manual control")),
                    ComparisonRow(label: String(localized: "Learning cost"),    optionA: String(localized: "Low"),                   optionB: String(localized: "High (MSL + pipeline)")),
                    ComparisonRow(label: String(localized: "Best for"),         optionA: String(localized: "Photo editing, camera filters"), optionB: String(localized: "High-performance custom effects")),
                ]
            ))
        ),
    ]
}
