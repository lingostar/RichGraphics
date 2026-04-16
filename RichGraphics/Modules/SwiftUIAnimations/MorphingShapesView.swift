import SwiftUI

// MARK: - Shape Morphing (Educational Pattern)
//
// The correct way to morph shapes in SwiftUI:
// 1. Use a single Double (progress) as animatableData
// 2. Store both source and target point arrays
// 3. Lerp between them inside path(in:)
//
// This avoids the fragile Array<CGPoint>+VectorArithmetic hack.

private let pointCount = 120

// MARK: - MorphShape

/// A shape that interpolates between two sets of points based on `progress`.
///
/// - `progress = 0` → draws shapeA
/// - `progress = 1` → draws shapeB
/// - values between → smooth linear interpolation
private struct MorphShape: Shape {
    let shapeA: [CGPoint]
    let shapeB: [CGPoint]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard shapeA.count == shapeB.count, shapeA.count >= 3 else { return Path() }
        let t = progress
        var path = Path()
        let first = lerpPoint(shapeA[0], shapeB[0], t: t, in: rect)
        path.move(to: first)
        for i in 1..<shapeA.count {
            path.addLine(to: lerpPoint(shapeA[i], shapeB[i], t: t, in: rect))
        }
        path.closeSubpath()
        return path
    }

    private func lerpPoint(_ a: CGPoint, _ b: CGPoint, t: Double, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: (a.x + (b.x - a.x) * t) * rect.width,
            y: (a.y + (b.y - a.y) * t) * rect.height
        )
    }
}

// MARK: - Shape Generators
// All shapes: center (0.5, 0.5), start at top (12 o'clock), go clockwise.
// All return exactly `pointCount` points in normalized 0..1 coordinates.

private func circlePoints() -> [CGPoint] {
    (0..<pointCount).map { i in
        let angle = -Double.pi / 2 + Double(i) * (2 * .pi / Double(pointCount))
        return CGPoint(x: 0.5 + 0.38 * cos(angle), y: 0.5 + 0.38 * sin(angle))
    }
}

private func starPoints() -> [CGPoint] {
    var keyPts: [CGPoint] = []
    for i in 0..<10 {
        let angle = -Double.pi / 2 + Double(i) * (2 * .pi / 10.0)
        let r: Double = i % 2 == 0 ? 0.38 : 0.16
        keyPts.append(CGPoint(x: 0.5 + r * cos(angle), y: 0.5 + r * sin(angle)))
    }
    return evenlyDistribute(keyPts, count: pointCount)
}

private func squarePoints() -> [CGPoint] {
    evenlyDistribute([
        CGPoint(x: 0.5, y: 0.12),
        CGPoint(x: 0.88, y: 0.12),
        CGPoint(x: 0.88, y: 0.88),
        CGPoint(x: 0.12, y: 0.88),
        CGPoint(x: 0.12, y: 0.12),
    ], count: pointCount)
}

private func trianglePoints() -> [CGPoint] {
    evenlyDistribute([
        CGPoint(x: 0.5, y: 0.08),
        CGPoint(x: 0.92, y: 0.88),
        CGPoint(x: 0.08, y: 0.88),
    ], count: pointCount)
}

private func heartPoints() -> [CGPoint] {
    // Parametric heart: generate raw, then rotate to start at top
    let raw: [CGPoint] = (0..<pointCount).map { i in
        let t = Double(i) * (2 * .pi / Double(pointCount))
        let x = 16 * pow(sin(t), 3)
        let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
        return CGPoint(x: 0.5 + x / 42.0, y: 0.48 + y / 42.0)
    }
    // Find topmost point (smallest y) and rotate array to start there
    guard let topIdx = raw.enumerated().min(by: { $0.element.y < $1.element.y })?.offset else { return raw }
    return Array(raw[topIdx...]) + Array(raw[..<topIdx])
}

private func diamondPoints() -> [CGPoint] {
    evenlyDistribute([
        CGPoint(x: 0.5, y: 0.05),
        CGPoint(x: 0.92, y: 0.5),
        CGPoint(x: 0.5, y: 0.95),
        CGPoint(x: 0.08, y: 0.5),
    ], count: pointCount)
}

/// Distribute `count` points evenly along the perimeter of a closed polygon.
private func evenlyDistribute(_ vertices: [CGPoint], count: Int) -> [CGPoint] {
    let n = vertices.count
    var edgeLengths: [Double] = []
    var totalLength: Double = 0
    for i in 0..<n {
        let a = vertices[i], b = vertices[(i + 1) % n]
        let len = hypot(b.x - a.x, b.y - a.y)
        edgeLengths.append(len)
        totalLength += len
    }
    var result: [CGPoint] = []
    var edgeIdx = 0
    var distOnEdge: Double = 0
    let step = totalLength / Double(count)
    for _ in 0..<count {
        let a = vertices[edgeIdx], b = vertices[(edgeIdx + 1) % n]
        let t = edgeLengths[edgeIdx] > 0 ? distOnEdge / edgeLengths[edgeIdx] : 0
        result.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        distOnEdge += step
        while edgeIdx < n && distOnEdge > edgeLengths[edgeIdx] + 1e-9 {
            distOnEdge -= edgeLengths[edgeIdx]
            edgeIdx = (edgeIdx + 1) % n
        }
    }
    return result
}

// MARK: - Shape Pair

private enum ShapePair: String, CaseIterable, Identifiable {
    case circleToStar = "Circle → Star"
    case squareToTriangle = "Square → Triangle"
    case heartToDiamond = "Heart → Diamond"
    var id: String { rawValue }

    var shapes: (from: [CGPoint], to: [CGPoint]) {
        switch self {
        case .circleToStar: (circlePoints(), starPoints())
        case .squareToTriangle: (squarePoints(), trianglePoints())
        case .heartToDiamond: (heartPoints(), diamondPoints())
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .circleToStar:
            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .squareToTriangle:
            LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .heartToDiamond:
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - View

struct MorphingShapesView: View {
    @State private var selectedPair: ShapePair = .circleToStar
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            let shapes = selectedPair.shapes
            MorphShape(shapeA: shapes.from, shapeB: shapes.to, progress: progress)
                .fill(selectedPair.gradient)
                .shadow(color: .purple.opacity(0.3), radius: 16, y: 8)
                .frame(width: 260, height: 260)

            Spacer()

            VStack(spacing: 16) {
                // Progress slider for fine control
                VStack(spacing: 4) {
                    Text("Progress: \(progress, specifier: "%.0f%%")")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                    Slider(value: $progress, in: 0...1)
                        .padding(.horizontal, 20)
                }

                Picker("Shape Pair", selection: $selectedPair) {
                    ForEach(ShapePair.allCases) { pair in
                        Text(pair.rawValue).tag(pair)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: selectedPair) { _, _ in
                    progress = 0
                }

                Button {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        progress = progress < 0.5 ? 1 : 0
                    }
                } label: {
                    Text(progress > 0.5 ? "Revert" : "Morph")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.orange.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NavigationStack {
        MorphingShapesView()
            .navigationTitle("Morphing Shapes")
    }
}
