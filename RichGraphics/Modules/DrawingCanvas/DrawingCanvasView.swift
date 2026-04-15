import SwiftUI

struct DrawingCanvasView: View {
    @State private var lines: [DrawingLine] = []
    @State private var currentLine: DrawingLine?
    @State private var selectedColor: Color = .black
    @State private var lineWidth: Double = 4.0

    private let colors: [Color] = [.black, .red, .blue, .green, .orange, .purple]

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                for line in lines {
                    drawLine(line, in: &context)
                }
                if let current = currentLine {
                    drawLine(current, in: &context)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        if currentLine == nil {
                            currentLine = DrawingLine(
                                points: [point],
                                color: selectedColor,
                                lineWidth: lineWidth
                            )
                        } else {
                            currentLine?.points.append(point)
                        }
                    }
                    .onEnded { _ in
                        if let line = currentLine {
                            lines.append(line)
                        }
                        currentLine = nil
                    }
            )
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 0))

            Divider()

            HStack(spacing: 16) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if color == selectedColor {
                                Circle()
                                    .stroke(.primary, lineWidth: 3)
                                    .padding(-3)
                            }
                        }
                        .onTapGesture {
                            selectedColor = color
                        }
                }

                Spacer()

                Slider(value: $lineWidth, in: 1...20, step: 1)
                    .frame(width: 100)

                Button("Clear") {
                    lines.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func drawLine(_ line: DrawingLine, in context: inout GraphicsContext) {
        guard line.points.count > 1 else { return }
        var path = Path()
        path.move(to: line.points[0])
        for point in line.points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(line.color),
            style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}

private struct DrawingLine {
    var points: [CGPoint]
    var color: Color
    var lineWidth: Double
}

#Preview {
    NavigationStack {
        DrawingCanvasView()
            .navigationTitle("Drawing Canvas")
    }
}
