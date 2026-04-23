import SwiftUI

struct DrawingCanvasDemo: Identifiable {
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

struct DrawingCanvasView: View {
    @MainActor
    private var demos: [DrawingCanvasDemo] {
        [
            DrawingCanvasDemo(
                title: "Freehand Drawing",
                description: "CoreGraphics-based drawing with color palette and undo/redo",
                icon: "hand.draw",
                color: .orange
            ) {
                FreehandDrawingView()
            },
            DrawingCanvasDemo(
                title: "PencilKit Canvas",
                description: "Full PencilKit integration with tool picker and image export",
                icon: "pencil.tip.crop.circle",
                color: .blue
            ) {
                PencilKitCanvasView()
            },
            DrawingCanvasDemo(
                title: "Shape Builder",
                description: "Draw lines, rectangles, circles, and triangles by gesture",
                icon: "rectangle.on.rectangle",
                color: .green
            ) {
                ShapeBuilderView()
            },
            // Hidden from UI (files kept in project for future reference):
            // - Generative Art: covered by Freehand Drawing paradigm shift
            // - Signature Pad: overlaps heavily with Freehand Drawing
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
        DrawingCanvasView()
            .navigationTitle("Drawing Canvas")
    }
}
