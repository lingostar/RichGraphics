import SwiftUI

private struct FreehandStroke {
    var points: [CGPoint]
    var color: Color
    var lineWidth: Double
    var isEraser: Bool
}

struct FreehandDrawingView: View {
    @State private var strokes: [FreehandStroke] = []
    @State private var currentStroke: FreehandStroke?
    @State private var undoneStrokes: [FreehandStroke] = []
    @State private var selectedColor: Color = .black
    @State private var lineWidth: Double = 4.0
    @State private var isEraserActive = false

    private let colors: [Color] = [
        .black, .red, .orange, .yellow,
        .green, .blue, .purple, .brown,
    ]

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            Divider()
            toolBar
        }
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        Canvas { context, _ in
            for stroke in strokes {
                drawStroke(stroke, in: &context)
            }
            if let current = currentStroke {
                drawStroke(current, in: &context)
            }
        }
        .gesture(drawGesture)
        .background(.white)
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                if currentStroke == nil {
                    currentStroke = FreehandStroke(
                        points: [point],
                        color: isEraserActive ? .white : selectedColor,
                        lineWidth: isEraserActive ? max(lineWidth * 3, 20) : lineWidth,
                        isEraser: isEraserActive
                    )
                } else {
                    currentStroke?.points.append(point)
                }
            }
            .onEnded { _ in
                if let stroke = currentStroke {
                    strokes.append(stroke)
                    undoneStrokes.removeAll()
                }
                currentStroke = nil
            }
    }

    private func drawStroke(_ stroke: FreehandStroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        var path = Path()
        path.move(to: stroke.points[0])
        for i in 1..<stroke.points.count {
            let mid = CGPoint(
                x: (stroke.points[i - 1].x + stroke.points[i].x) / 2,
                y: (stroke.points[i - 1].y + stroke.points[i].y) / 2
            )
            path.addQuadCurve(to: mid, control: stroke.points[i - 1])
        }
        if let last = stroke.points.last {
            path.addLine(to: last)
        }

        if stroke.isEraser {
            context.blendMode = .copy
        }
        context.stroke(
            path,
            with: .color(stroke.color),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
        if stroke.isEraser {
            context.blendMode = .normal
        }
    }

    // MARK: - Toolbar

    private var toolBar: some View {
        VStack(spacing: 10) {
            // Color palette
            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if color == selectedColor && !isEraserActive {
                                Circle()
                                    .stroke(.primary, lineWidth: 3)
                                    .padding(-4)
                            }
                        }
                        .shadow(color: color.opacity(0.4), radius: 2, y: 1)
                        .onTapGesture {
                            selectedColor = color
                            isEraserActive = false
                        }
                }

                Spacer()

                // Eraser toggle
                Button {
                    isEraserActive.toggle()
                } label: {
                    Image(systemName: "eraser")
                        .font(.title3)
                        .foregroundStyle(isEraserActive ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(isEraserActive ? Color.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // Line width and actions
            HStack(spacing: 12) {
                Image(systemName: "line.diagonal")
                    .font(.caption)

                Slider(value: $lineWidth, in: 1...20, step: 1)

                Text("\(Int(lineWidth))pt")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 36)

                Spacer()

                Button {
                    if let last = strokes.popLast() {
                        undoneStrokes.append(last)
                    }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(strokes.isEmpty)

                Button {
                    if let last = undoneStrokes.popLast() {
                        strokes.append(last)
                    }
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(undoneStrokes.isEmpty)

                Button("Clear", role: .destructive) {
                    strokes.removeAll()
                    undoneStrokes.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(strokes.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        FreehandDrawingView()
            .navigationTitle("Freehand Drawing")
    }
}
