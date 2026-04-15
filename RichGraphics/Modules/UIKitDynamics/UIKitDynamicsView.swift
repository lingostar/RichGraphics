import SwiftUI
import UIKit

struct UIKitDynamicsView: View {
    @State private var gravityEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            DynamicsContainerView(gravityEnabled: gravityEnabled)
                .ignoresSafeArea(edges: .bottom)

            HStack {
                Toggle("Gravity", isOn: $gravityEnabled)
                    .font(.subheadline)
                    .frame(width: 150)

                Spacer()

                Text("Tap to add squares")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct DynamicsContainerView: UIViewRepresentable {
    let gravityEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.clipsToBounds = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.animator == nil {
            coordinator.setupDynamics(in: uiView)
        }

        if gravityEnabled {
            coordinator.gravity?.gravityDirection = CGVector(dx: 0, dy: 1.0)
        } else {
            coordinator.gravity?.gravityDirection = CGVector(dx: 0, dy: 0)
        }
    }

    @MainActor
    class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var gravity: UIGravityBehavior?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        weak var containerView: UIView?

        let squareColors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemTeal, .systemPink, .systemYellow
        ]

        func setupDynamics(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let gravityBehavior = UIGravityBehavior()
            gravityBehavior.gravityDirection = CGVector(dx: 0, dy: 1.0)
            animator?.addBehavior(gravityBehavior)
            gravity = gravityBehavior

            let collisionBehavior = UICollisionBehavior()
            collisionBehavior.translatesReferenceBoundsIntoBoundary = true
            animator?.addBehavior(collisionBehavior)
            collision = collisionBehavior

            let dynamicItemBehavior = UIDynamicItemBehavior()
            dynamicItemBehavior.elasticity = 0.6
            dynamicItemBehavior.friction = 0.2
            dynamicItemBehavior.resistance = 0.1
            animator?.addBehavior(dynamicItemBehavior)
            itemBehavior = dynamicItemBehavior

            // Add some initial squares
            for _ in 0..<5 {
                let x = CGFloat.random(in: 40...(view.bounds.width > 80 ? view.bounds.width - 40 : 80))
                let y = CGFloat.random(in: 40...200)
                addSquare(at: CGPoint(x: x, y: y))
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: containerView)
            addSquare(at: location)
        }

        func addSquare(at point: CGPoint) {
            guard let view = containerView else { return }
            let size = CGFloat.random(in: 30...60)
            let square = UIView(frame: CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size))
            square.backgroundColor = squareColors.randomElement()
            square.layer.cornerRadius = size * 0.15
            view.addSubview(square)

            gravity?.addItem(square)
            collision?.addItem(square)
            itemBehavior?.addItem(square)

            // Limit total squares to 30
            if let container = containerView, container.subviews.count > 30 {
                let oldest = container.subviews[0]
                gravity?.removeItem(oldest)
                collision?.removeItem(oldest)
                itemBehavior?.removeItem(oldest)
                oldest.removeFromSuperview()
            }
        }
    }
}

#Preview {
    NavigationStack {
        UIKitDynamicsView()
            .navigationTitle("UIKit Dynamics")
    }
}
