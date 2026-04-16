import SwiftUI
import UIKit

struct CollisionBubblesView: View {
    @State private var gravityOn = false
    @State private var shouldAddBubble = false

    var body: some View {
        VStack(spacing: 0) {
            BubblesContainer(
                gravityOn: gravityOn,
                shouldAddBubble: $shouldAddBubble
            )
            .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 16) {
                Button {
                    shouldAddBubble = true
                } label: {
                    Label("Add Bubble", systemImage: "plus.circle")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Spacer()

                Toggle("Gravity", isOn: $gravityOn)
                    .font(.subheadline)
                    .frame(width: 140)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - UIViewRepresentable

struct BubblesContainer: UIViewRepresentable {
    let gravityOn: Bool
    @Binding var shouldAddBubble: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.clipsToBounds = true

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.animator == nil {
            coordinator.setupDynamics(in: uiView)
            coordinator.addInitialBubbles()
        }

        coordinator.setGravity(enabled: gravityOn)

        if shouldAddBubble {
            DispatchQueue.main.async {
                coordinator.addBubble()
                shouldAddBubble = false
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var gravity: UIGravityBehavior?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        var pushTimer: Timer?
        weak var containerView: UIView?

        private let tags = [
            "SwiftUI", "UIKit", "Metal", "Core ML", "ARKit",
            "SceneKit", "SpriteKit", "Combine", "Async", "Vapor",
            "Swift", "iOS", "macOS", "Xcode", "TestFlight",
            "CloudKit", "MapKit", "GameKit"
        ]

        private let bubbleColors: [(UIColor, UIColor)] = [
            (.systemBlue, .systemCyan),
            (.systemPurple, .systemPink),
            (.systemOrange, .systemYellow),
            (.systemGreen, .systemMint),
            (.systemRed, .systemOrange),
            (.systemIndigo, .systemPurple),
            (.systemTeal, .systemGreen),
            (.systemPink, .systemRed),
        ]

        func setupDynamics(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let g = UIGravityBehavior()
            g.gravityDirection = CGVector(dx: 0, dy: 0)
            animator?.addBehavior(g)
            gravity = g

            let c = UICollisionBehavior()
            c.translatesReferenceBoundsIntoBoundary = true
            animator?.addBehavior(c)
            collision = c

            let ib = UIDynamicItemBehavior()
            ib.elasticity = 0.7
            ib.friction = 0.05
            ib.resistance = 0.3
            ib.angularResistance = 0.5
            animator?.addBehavior(ib)
            itemBehavior = ib

            pushTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.applyRandomPushes()
                }
            }
        }

        func addInitialBubbles() {
            for _ in 0..<10 {
                addBubble()
            }
        }

        func addBubble() {
            guard let view = containerView else { return }
            let tagIndex = view.subviews.count % tags.count
            let label = tags[tagIndex]
            let size = CGFloat(label.count) * 8 + 40
            let diameter = max(size, 50)

            let maxX = max(diameter, view.bounds.width - diameter)
            let maxY = max(diameter, view.bounds.height - diameter)
            let x = CGFloat.random(in: diameter...maxX)
            let y = CGFloat.random(in: diameter...maxY)

            let bubble = BubbleView(frame: CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter))
            let colorPair = bubbleColors[tagIndex % bubbleColors.count]
            bubble.configure(text: label, color1: colorPair.0, color2: colorPair.1)

            view.addSubview(bubble)
            gravity?.addItem(bubble)
            collision?.addItem(bubble)
            itemBehavior?.addItem(bubble)

            // Small initial push
            let push = UIPushBehavior(items: [bubble], mode: .instantaneous)
            push.pushDirection = CGVector(
                dx: CGFloat.random(in: -0.3...0.3),
                dy: CGFloat.random(in: -0.3...0.3)
            )
            push.magnitude = 0.2
            animator?.addBehavior(push)

            if view.subviews.count > 20 {
                removeOldestBubble()
            }
        }

        func removeOldestBubble() {
            guard let view = containerView, let oldest = view.subviews.first else { return }
            gravity?.removeItem(oldest)
            collision?.removeItem(oldest)
            itemBehavior?.removeItem(oldest)
            oldest.removeFromSuperview()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = containerView else { return }
            let location = gesture.location(in: view)

            for sub in view.subviews {
                if sub.frame.contains(location) {
                    let push = UIPushBehavior(items: [sub], mode: .instantaneous)
                    push.pushDirection = CGVector(
                        dx: CGFloat.random(in: -1.0...1.0),
                        dy: CGFloat.random(in: -1.0...1.0)
                    )
                    push.magnitude = 0.8
                    animator?.addBehavior(push)
                    break
                }
            }
        }

        func setGravity(enabled: Bool) {
            gravity?.gravityDirection = enabled
                ? CGVector(dx: 0, dy: 1.0)
                : CGVector(dx: 0, dy: 0)
        }

        func applyRandomPushes() {
            guard let view = containerView else { return }
            for sub in view.subviews.shuffled().prefix(3) {
                let push = UIPushBehavior(items: [sub], mode: .instantaneous)
                push.pushDirection = CGVector(
                    dx: CGFloat.random(in: -0.2...0.2),
                    dy: CGFloat.random(in: -0.2...0.2)
                )
                push.magnitude = 0.15
                animator?.addBehavior(push)
            }
        }

        func cleanup() {
            pushTimer?.invalidate()
            pushTimer = nil
        }

        deinit {
            MainActor.assumeIsolated {
                cleanup()
            }
        }
    }
}

// MARK: - Bubble UIView

@MainActor
private final class BubbleView: UIView {
    private let label = UILabel()

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { .ellipse }

    func configure(text: String, color1: UIColor, color2: UIColor) {
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = bounds
        layer.insertSublayer(gradient, at: 0)

        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
}

#Preview {
    NavigationStack {
        CollisionBubblesView()
            .navigationTitle("Collision Bubbles")
    }
}
