import SwiftUI

// MARK: - Morphable Shape

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

// Make CGPoint conform to VectorArithmetic for animatableData
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
    public mutating func scale(by rhs: Double) {
        x *= rhs
        y *= rhs
    }
    public var magnitudeSquared: Double {
        x * x + y * y
    }
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
            let l = i < lhs.count ? lhs[i] : .zero
            let r = i < rhs.count ? rhs[i] : .zero
            return CGPoint(x: l.x + r.x, y: l.y + r.y)
        }
    }
    public static func - (lhs: [CGPoint], rhs: [CGPoint]) -> [CGPoint] {
        let count = Swift.max(lhs.count, rhs.count)
        return (0..<count).map { i in
            let l = i < lhs.count ? lhs[i] : .zero
            let r = i < rhs.count ? rhs[i] : .zero
            return CGPoint(x: l.x - r.x, y: l.y - r.y)
        }
    }
    public static var zero: [CGPoint] { [] }
}

// MARK: - Shape Data

private let pointCount = 64

private enum ShapePair: String, CaseIterable, Identifiable {
    case circleToStar = "Circle → Star"
    case squareToTriangle = "Square → Triangle"
    case heartToDiamond = "Heart → Diamond"

    var id: String { rawValue }
}

private func circlePoints(n: Int = pointCount) -> [CGPoint] {
    (0..<n).map { i in
        let angle = Double(i) * (2 * .pi / Double(n)) - .pi / 2
        return CGPoint(x: 0.5 + 0.4 * cos(angle), y: 0.5 + 0.4 * sin(angle))
    }
}

private func starPoints(n: Int = pointCount) -> [CGPoint] {
    // 5-pointed star: every point alternates between outer and inner radius
    (0..<n).map { i in
        let angle = Double(i) * (2 * .pi / Double(n)) - .pi / 2
        // 10 segments: 5 outer peaks, 5 inner valleys
        let segment = Double(i) / Double(n) * 10.0
        let segFrac = segment - floor(segment) // 0..1 within segment
        let isRising = Int(segment) % 2 == 0
        let outerR = 0.4
        let innerR = 0.18
        let r: Double
        if isRising {
            r = innerR + (outerR - innerR) * segFrac
        } else {
            r = outerR - (outerR - innerR) * segFrac
        }
        return CGPoint(x: 0.5 + r * cos(angle), y: 0.5 + r * sin(angle))
    }
}

private func squarePoints(n: Int = pointCount) -> [CGPoint] {
    let perSide = n / 4
    var pts: [CGPoint] = []
    let minV = 0.1, maxV = 0.9
    for i in 0..<perSide { pts.append(CGPoint(x: minV + (maxV - minV) * Double(i) / Double(perSide), y: minV)) }
    for i in 0..<perSide { pts.append(CGPoint(x: maxV, y: minV + (maxV - minV) * Double(i) / Double(perSide))) }
    for i in 0..<perSide { pts.append(CGPoint(x: maxV - (maxV - minV) * Double(i) / Double(perSide), y: maxV)) }
    let remaining = n - 3 * perSide
    for i in 0..<remaining { pts.append(CGPoint(x: minV, y: maxV - (maxV - minV) * Double(i) / Double(remaining))) }
    return pts
}

private func trianglePoints(n: Int = pointCount) -> [CGPoint] {
    let perSide = n / 3
    var pts: [CGPoint] = []
    let top = CGPoint(x: 0.5, y: 0.08)
    let bl = CGPoint(x: 0.08, y: 0.88)
    let br = CGPoint(x: 0.92, y: 0.88)
    for i in 0..<perSide { pts.append(lerp(top, bl, t: Double(i) / Double(perSide))) }
    for i in 0..<perSide { pts.append(lerp(bl, br, t: Double(i) / Double(perSide))) }
    let remaining = n - 2 * perSide
    for i in 0..<remaining { pts.append(lerp(br, top, t: Double(i) / Double(remaining))) }
    return pts
}

private func heartPoints(n: Int = pointCount) -> [CGPoint] {
    (0..<n).map { i in
        let t = Double(i) * (2 * .pi / Double(n))
        let x = 16 * pow(sin(t), 3)
        let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
        return CGPoint(x: 0.5 + x / 42.0, y: 0.48 + y / 42.0)
    }
}

private func diamondPoints(n: Int = pointCount) -> [CGPoint] {
    let perSide = n / 4
    var pts: [CGPoint] = []
    let top = CGPoint(x: 0.5, y: 0.05)
    let right = CGPoint(x: 0.95, y: 0.5)
    let bottom = CGPoint(x: 0.5, y: 0.95)
    let left = CGPoint(x: 0.05, y: 0.5)
    for i in 0..<perSide { pts.append(lerp(top, right, t: Double(i) / Double(perSide))) }
    for i in 0..<perSide { pts.append(lerp(right, bottom, t: Double(i) / Double(perSide))) }
    for i in 0..<perSide { pts.append(lerp(bottom, left, t: Double(i) / Double(perSide))) }
    let remaining = n - 3 * perSide
    for i in 0..<remaining { pts.append(lerp(left, top, t: Double(i) / Double(remaining))) }
    return pts
}

private func lerp(_ a: CGPoint, _ b: CGPoint, t: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
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
                .frame(width: 250, height: 250)
                .animation(.easeInOut(duration: 1.0), value: morphed)
                .animation(.easeInOut(duration: 0.5), value: selectedPair)

            Spacer()

            VStack(spacing: 16) {
                Picker("Shape Pair", selection: $selectedPair) {
                    ForEach(ShapePair.allCases) { pair in
                        Text(pair.rawValue).tag(pair)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

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
