import SwiftUI

// MARK: - Morphable Shape using animatableData

/// All shapes use exactly `pointCount` points, sampled uniformly around the perimeter.
/// Every shape starts at the TOP-CENTER (12 o'clock) and goes CLOCKWISE.
/// This ensures 1:1 point correspondence during morphing with no crossing.

private let pointCount = 120

private struct MorphableShape: Shape {
    var points: [CGPoint]
    var animatableData: [CGPoint] {
        get { points }
        set { points = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard points.count >= 3 else { return Path() }
        var path = Path()
        let scaled = points.map { CGPoint(x: $0.x * rect.width, y: $0.y * rect.height) }
        path.move(to: scaled[0])
        for i in 1..<scaled.count {
            path.addLine(to: scaled[i])
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - VectorArithmetic conformance for [CGPoint]

extension CGPoint: @retroactive AdditiveArithmetic {
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    public static var zero: CGPoint { CGPoint(x: 0, y: 0) }
}

extension CGPoint: @retroactive VectorArithmetic {
    public mutating func scale(by rhs: Double) { x *= rhs; y *= rhs }
    public var magnitudeSquared: Double { x * x + y * y }
}

extension Array: @retroactive AdditiveArithmetic where Element == CGPoint {}

extension Array: @retroactive VectorArithmetic where Element == CGPoint {
    public mutating func scale(by rhs: Double) {
        for i in indices { self[i].scale(by: rhs) }
    }
    public var magnitudeSquared: Double {
        reduce(0) { $0 + $1.magnitudeSquared }
    }
    public static func + (lhs: [CGPoint], rhs: [CGPoint]) -> [CGPoint] {
        let count = Swift.max(lhs.count, rhs.count)
        return (0..<count).map { i in
            let l = i < lhs.count ? lhs[i] : (lhs.last ?? .zero)
            let r = i < rhs.count ? rhs[i] : (rhs.last ?? .zero)
            return CGPoint(x: l.x + r.x, y: l.y + r.y)
        }
    }
    public static func - (lhs: [CGPoint], rhs: [CGPoint]) -> [CGPoint] {
        let count = Swift.max(lhs.count, rhs.count)
        return (0..<count).map { i in
            let l = i < lhs.count ? lhs[i] : (lhs.last ?? .zero)
            let r = i < rhs.count ? rhs[i] : (rhs.last ?? .zero)
            return CGPoint(x: l.x - r.x, y: l.y - r.y)
        }
    }
    public static var zero: [CGPoint] { [] }
}

// MARK: - Shape Generators
// ALL shapes: center (0.5, 0.5), start at top-center, go clockwise.

/// Circle: starts at top (0.5, 0.1), clockwise
private func circlePoints() -> [CGPoint] {
    let cx = 0.5, cy = 0.5, r = 0.38
    return (0..<pointCount).map { i in
        let angle = -Double.pi / 2 + Double(i) * (2 * .pi / Double(pointCount))
        return CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
    }
}

/// Star (5-pointed): starts at top peak, clockwise
private func starPoints() -> [CGPoint] {
    let cx = 0.5, cy = 0.5
    let outerR = 0.38, innerR = 0.16
    // Pre-compute 10 key points (5 outer + 5 inner), then interpolate
    var keyPoints: [CGPoint] = []
    for i in 0..<10 {
        let angle = -Double.pi / 2 + Double(i) * (2 * .pi / 10.0)
        let r = i % 2 == 0 ? outerR : innerR
        keyPoints.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
    }
    return interpolateAlongPolygon(keyPoints, count: pointCount)
}

/// Square: starts at top-center of top edge, clockwise
private func squarePoints() -> [CGPoint] {
    let keyPoints: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.12),  // top center
        CGPoint(x: 0.88, y: 0.12), // top right
        CGPoint(x: 0.88, y: 0.88), // bottom right
        CGPoint(x: 0.12, y: 0.88), // bottom left
        CGPoint(x: 0.12, y: 0.12), // top left
    ]
    return interpolateAlongPolygon(keyPoints, count: pointCount)
}

/// Triangle: starts at top vertex, clockwise
private func trianglePoints() -> [CGPoint] {
    let keyPoints: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.08),  // top
        CGPoint(x: 0.92, y: 0.88), // bottom right
        CGPoint(x: 0.08, y: 0.88), // bottom left
    ]
    return interpolateAlongPolygon(keyPoints, count: pointCount)
}

/// Heart: parametric heart curve, re-indexed to start at top-center dip, clockwise
private func heartPoints() -> [CGPoint] {
    // Generate raw heart points starting from the parametric t=0
    let raw: [CGPoint] = (0..<pointCount).map { i in
        let t = Double(i) * (2 * .pi / Double(pointCount))
        let x = 16 * pow(sin(t), 3)
        let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
        return CGPoint(x: 0.5 + x / 42.0, y: 0.48 + y / 42.0)
    }
    // The parametric heart at t=0 is actually at the bottom cusp.
    // Find the topmost point (lowest y = top of screen) to re-index
    let topIndex = raw.enumerated().min(by: { $0.element.y < $1.element.y })?.offset ?? 0
    // Rotate array so it starts from the top
    return Array(raw[topIndex...] + raw[..<topIndex])
}

/// Diamond: starts at top vertex, clockwise
private func diamondPoints() -> [CGPoint] {
    let keyPoints: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.05),  // top
        CGPoint(x: 0.92, y: 0.5),  // right
        CGPoint(x: 0.5, y: 0.95),  // bottom
        CGPoint(x: 0.08, y: 0.5),  // left
    ]
    return interpolateAlongPolygon(keyPoints, count: pointCount)
}

/// Distribute `count` points evenly along the perimeter of a polygon defined by `vertices`.
private func interpolateAlongPolygon(_ vertices: [CGPoint], count: Int) -> [CGPoint] {
    let n = vertices.count
    // Calculate total perimeter
    var edgeLengths: [Double] = []
    var totalLength: Double = 0
    for i in 0..<n {
        let a = vertices[i]
        let b = vertices[(i + 1) % n]
        let len = hypot(b.x - a.x, b.y - a.y)
        edgeLengths.append(len)
        totalLength += len
    }

    var result: [CGPoint] = []
    var edgeIndex = 0
    var distOnEdge: Double = 0
    let step = totalLength / Double(count)

    for _ in 0..<count {
        let a = vertices[edgeIndex]
        let b = vertices[(edgeIndex + 1) % n]
        let t = distOnEdge / edgeLengths[edgeIndex]
        result.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))

        distOnEdge += step
        while edgeIndex < n && distOnEdge > edgeLengths[edgeIndex] + 1e-9 {
            distOnEdge -= edgeLengths[edgeIndex]
            edgeIndex = (edgeIndex + 1) % n
        }
    }
    return result
}

// MARK: - Shape Pair Enum

private enum ShapePair: String, CaseIterable, Identifiable {
    case circleToStar = "Circle → Star"
    case squareToTriangle = "Square → Triangle"
    case heartToDiamond = "Heart → Diamond"

    var id: String { rawValue }
}

// MARK: - View

struct MorphingShapesView: View {
    @State private var selectedPair: ShapePair = .circleToStar
    @State private var morphed = false

    private var currentPoints: [CGPoint] {
        let pair = shapeData(for: selectedPair)
        return morphed ? pair.1 : pair.0
    }

    private var gradient: LinearGradient {
        switch selectedPair {
        case .circleToStar:
            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .squareToTriangle:
            LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .heartToDiamond:
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func shapeData(for pair: ShapePair) -> ([CGPoint], [CGPoint]) {
        switch pair {
        case .circleToStar: (circlePoints(), starPoints())
        case .squareToTriangle: (squarePoints(), trianglePoints())
        case .heartToDiamond: (heartPoints(), diamondPoints())
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            MorphableShape(points: currentPoints)
                .fill(gradient)
                .shadow(color: .purple.opacity(0.3), radius: 16, y: 8)
                .frame(width: 260, height: 260)
                .animation(.easeInOut(duration: 1.2), value: morphed)

            Spacer()

            VStack(spacing: 16) {
                Picker("Shape Pair", selection: $selectedPair) {
                    ForEach(ShapePair.allCases) { pair in
                        Text(pair.rawValue).tag(pair)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: selectedPair) { _, _ in
                    morphed = false
                }

                Button {
                    morphed.toggle()
                } label: {
                    Text(morphed ? "Revert" : "Morph")
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
