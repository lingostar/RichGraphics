import SwiftUI
import UIKit

struct SnapGridView: View {
    @State private var damping: CGFloat = 0.5
    @State private var shouldAddItem = false
    @State private var shouldClear = false

    var body: some View {
        VStack(spacing: 0) {
            SnapGridContainer(
                damping: damping,
                shouldAddItem: $shouldAddItem,
                shouldClear: $shouldClear
            )
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 10) {
                HStack {
                    Text("Damping")
                        .font(.caption.weight(.medium))
                    Slider(value: $damping, in: 0.0...1.0)
                    Text(String(format: "%.2f", damping))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }

                HStack(spacing: 16) {
                    Button {
                        shouldAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus.circle")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button {
                        shouldClear = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - UIViewRepresentable

struct SnapGridContainer: UIViewRepresentable {
    let damping: CGFloat
    @Binding var shouldAddItem: Bool
    @Binding var shouldClear: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.animator == nil {
            coordinator.setupDynamics(in: uiView)
        }

        coordinator.currentDamping = damping

        if shouldAddItem {
            DispatchQueue.main.async {
                coordinator.addDraggableItem()
                shouldAddItem = false
            }
        }

        if shouldClear {
            DispatchQueue.main.async {
                coordinator.clearItems()
                shouldClear = false
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        weak var containerView: UIView?
        var gridPoints: [CGPoint] = []
        var snapBehaviors: [UIView: UISnapBehavior] = [:]
        var currentDamping: CGFloat = 0.5
        var dotLayers: [CAShapeLayer] = []

        private let gridColumns = 5
        private let gridRows = 5
        private let itemColors: [UIColor] = [
            .systemPurple, .systemBlue, .systemTeal, .systemGreen,
            .systemOrange, .systemRed, .systemPink, .systemIndigo
        ]

        func setupDynamics(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let c = UICollisionBehavior()
            c.translatesReferenceBoundsIntoBoundary = true
            animator?.addBehavior(c)
            collision = c

            let ib = UIDynamicItemBehavior()
            ib.allowsRotation = false
            ib.resistance = 10
            animator?.addBehavior(ib)
            itemBehavior = ib

            calculateGridPoints(in: view)
            drawGridDots(in: view)

            for _ in 0..<3 {
                addDraggableItem()
            }
        }

        func calculateGridPoints(in view: UIView) {
            gridPoints.removeAll()
            let width = view.bounds.width
            let height = view.bounds.height
            let spacingX = width / CGFloat(gridColumns + 1)
            let spacingY = height / CGFloat(gridRows + 1)

            for row in 1...gridRows {
                for col in 1...gridColumns {
                    gridPoints.append(CGPoint(x: spacingX * CGFloat(col), y: spacingY * CGFloat(row)))
                }
            }
        }

        func drawGridDots(in view: UIView) {
            dotLayers.forEach { $0.removeFromSuperlayer() }
            dotLayers.removeAll()

            for point in gridPoints {
                let dot = CAShapeLayer()
                dot.path = UIBezierPath(ovalIn: CGRect(x: -4, y: -4, width: 8, height: 8)).cgPath
                dot.fillColor = UIColor.tertiaryLabel.cgColor
                dot.position = point
                view.layer.addSublayer(dot)
                dotLayers.append(dot)
            }
        }

        func addDraggableItem() {
            guard let view = containerView else { return }
            let size: CGFloat = CGFloat.random(in: 36...48)
            let isCircle = Bool.random()
            let color = itemColors.randomElement() ?? .systemPurple

            let startPoint = gridPoints.randomElement() ?? CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            let item = UIView(frame: CGRect(x: startPoint.x - size / 2, y: startPoint.y - size / 2, width: size, height: size))
            item.backgroundColor = color
            item.layer.cornerRadius = isCircle ? size / 2 : 8
            item.layer.shadowColor = UIColor.black.cgColor
            item.layer.shadowOpacity = 0.2
            item.layer.shadowOffset = CGSize(width: 0, height: 2)
            item.layer.shadowRadius = 4

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            item.addGestureRecognizer(pan)
            item.isUserInteractionEnabled = true

            view.addSubview(item)

            collision?.addItem(item)
            itemBehavior?.addItem(item)

            let snap = UISnapBehavior(item: item, snapTo: startPoint)
            snap.damping = currentDamping
            animator?.addBehavior(snap)
            snapBehaviors[item] = snap
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let item = gesture.view else { return }
            let location = gesture.location(in: containerView)

            switch gesture.state {
            case .began:
                if let existingSnap = snapBehaviors[item] {
                    animator?.removeBehavior(existingSnap)
                    snapBehaviors[item] = nil
                }
                UIView.animate(withDuration: 0.15) {
                    item.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                    item.layer.shadowOpacity = 0.4
                }
            case .changed:
                item.center = location
                animator?.updateItem(usingCurrentState: item)
            case .ended, .cancelled:
                let nearest = nearestGridPoint(to: location)
                let snap = UISnapBehavior(item: item, snapTo: nearest)
                snap.damping = currentDamping
                animator?.addBehavior(snap)
                snapBehaviors[item] = snap

                UIView.animate(withDuration: 0.15) {
                    item.transform = .identity
                    item.layer.shadowOpacity = 0.2
                }
            default:
                break
            }
        }

        func nearestGridPoint(to point: CGPoint) -> CGPoint {
            gridPoints.min(by: {
                hypot($0.x - point.x, $0.y - point.y) < hypot($1.x - point.x, $1.y - point.y)
            }) ?? point
        }

        func clearItems() {
            guard let view = containerView else { return }
            for sub in view.subviews {
                if let snap = snapBehaviors[sub] {
                    animator?.removeBehavior(snap)
                }
                collision?.removeItem(sub)
                itemBehavior?.removeItem(sub)
                sub.removeFromSuperview()
            }
            snapBehaviors.removeAll()
        }
    }
}

#Preview {
    NavigationStack {
        SnapGridView()
            .navigationTitle("Snap Grid")
    }
}
