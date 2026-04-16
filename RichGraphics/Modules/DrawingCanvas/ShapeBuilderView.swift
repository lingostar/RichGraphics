import SwiftUI

private enum ShapeType: String, CaseIterable {
    case line = "Line"
    case rectangle = "Rectangle"
    case circle = "Circle"
    case triangle = "Triangle"
}

private struct DrawnShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    let startPoint: CGPoint
    let endPoint: CGPoint
    let strokeColor: Color
    let fillColor: Color
    let lineWidth: Double
}

struct ShapeBuilderView: View {
    @State private var shapes: [DrawnShape] = []
    @State private var selectedShapeType: ShapeType = .rectangle
    @State private var strokeColor: Color = .blue
    @State private var fillColor: Color = .blue.opacity(0.2)
    @State private var lineWidth: Double = 3.0
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?

    private let strokeColors: [Color] = [.blue, .red, .green, .orange, .purple, .black]
    private let fillColors: [Color] = [
        .blue.opacity(0.2), .red.opacity(0.2), .green.opacity(0.2),
        .orange.opacity(0.2), .purple.opacity(0.2), .clear,
    ]

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            Divider()
            controlsPanel
        }
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        Canvas { context, _ in
            for shape in shapes {
                drawShape(shape, in: &context)
            }
            // Preview shape
            if let start = dragStart, let current = dragCurrent {
                let preview = DrawnShape(
                    type: selectedShapeType,
                    startPoint: start,
                    endPoint: current,
                    strokeColor: strokeColor.opacity(0.6),
                    fillColor: fillColor.opacity(0.3),
                    lineWidth: lineWidth
                )
                drawShape(preview, in: &context)
            }
        }
        .gesture(shapeGesture)
        .background(.white)
    }

    private var shapeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                }
                dragCurrent = value.location
            }
            .onEnded { value in
                if let start = dragStart {
                    let shape = DrawnShape(
                        type: selectedShapeType,
                        startPoint: start,
                        endPoint: value.location,
                        strokeColor: strokeColor,
                        fillColor: fillColor,
                        lineWidth: lineWidth
                    )
                    shapes.append(shape)
                }
                dragStart = nil
                dragCurrent = nil
            }
    }

    private func drawShape(_ shape: DrawnShape, in context: inout GraphicsContext) {
        let path = shapePath(for: shape)
        let style = StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round, lineJoin: .round)

        switch shape.type {
        case .line:
            context.stroke(path, with: .color(shape.strokeColor), style: style)
        case .rectangle, .circle, .triangle:
            context.fill(path, with: .color(shape.fillColor))
            context.stroke(path, with: .color(shape.strokeColor), style: style)
        }
    }

    private func shapePath(for shape: DrawnShape) -> Path {
        let start = shape.startPoint
        let end = shape.endPoint
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        var path = Path()
        switch shape.type {
        case .line:
            path.move(to: start)
            path.addLine(to: end)
        case .rectangle:
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        case .circle:
            path.addEllipse(in: rect)
        case .triangle:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }

    // MARK: - Controls

    private var controlsPanel: some View {
        VStack(spacing: 10) {
            Picker("Shape", selection: $selectedShapeType) {
                ForEach(ShapeType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                // Stroke colors
                Text("Stroke")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(strokeColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if color == strokeColor {
                                Circle().stroke(.primary, lineWidth: 2).padding(-3)
                            }
                        }
                        .onTapGesture { strokeColor = color }
                }

                Spacer()

                // Fill toggle
                Text("Fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(fillColors.prefix(4)), id: \.self) { color in
                    Circle()
                        .fill(color == .clear ? Color(.systemGray5) : color)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if color == fillColor {
                                Circle().stroke(.primary, lineWidth: 2).padding(-3)
                            }
                            if color == .clear {
                                Image(systemName: "nosign")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onTapGesture { fillColor = color }
                }
            }

            HStack {
                Text("\(shapes.count) shape\(shapes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if !shapes.isEmpty {
                        shapes.removeLast()
                    }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(shapes.isEmpty)

                Button("Clear All", role: .destructive) {
                    shapes.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(shapes.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        ShapeBuilderView()
            .navigationTitle("Shape Builder")
    }
}
