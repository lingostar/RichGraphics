import SwiftUI
import UIKit
@preconcurrency import CoreMotion

struct GravityCardsView: View {
    @State private var cardCount = 0
    @State private var shouldReset = false
    @State private var shouldAddCard = false

    var body: some View {
        VStack(spacing: 0) {
            GravityCardsContainer(
                shouldAddCard: $shouldAddCard,
                shouldReset: $shouldReset,
                cardCount: $cardCount
            )
            .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 16) {
                Button {
                    shouldAddCard = true
                } label: {
                    Label("Add Card", systemImage: "plus.rectangle")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    shouldReset = true
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(cardCount) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - UIViewRepresentable

struct GravityCardsContainer: UIViewRepresentable {
    @Binding var shouldAddCard: Bool
    @Binding var shouldReset: Bool
    @Binding var cardCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(cardCount: $cardCount)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.animator == nil {
            coordinator.setupDynamics(in: uiView)
            for _ in 0..<4 {
                coordinator.addCard()
            }
        }

        if shouldAddCard {
            DispatchQueue.main.async {
                coordinator.addCard()
                shouldAddCard = false
            }
        }

        if shouldReset {
            DispatchQueue.main.async {
                coordinator.resetCards()
                shouldReset = false
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var gravity: UIGravityBehavior?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        weak var containerView: UIView?
        let motionManager = CMMotionManager()
        @Binding var cardCount: Int

        private let cardIcons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill",
                                 "leaf.fill", "drop.fill", "moon.fill", "sun.max.fill"]
        private let cardColors: [UIColor] = [
            .systemOrange, .systemRed, .systemBlue, .systemGreen,
            .systemPurple, .systemPink, .systemTeal, .systemYellow
        ]

        init(cardCount: Binding<Int>) {
            _cardCount = cardCount
        }

        func setupDynamics(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let g = UIGravityBehavior()
            g.gravityDirection = CGVector(dx: 0, dy: 1.0)
            animator?.addBehavior(g)
            gravity = g

            let c = UICollisionBehavior()
            c.translatesReferenceBoundsIntoBoundary = true
            animator?.addBehavior(c)
            collision = c

            let ib = UIDynamicItemBehavior()
            ib.elasticity = 0.4
            ib.friction = 0.3
            ib.resistance = 0.1
            ib.angularResistance = 0.3
            animator?.addBehavior(ib)
            itemBehavior = ib

            startMotionUpdates()
        }

        func startMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let motion, let self else { return }
                let g = motion.gravity
                self.gravity?.gravityDirection = CGVector(dx: g.x * 2.0, dy: -g.y * 2.0)
            }
        }

        func addCard() {
            guard let view = containerView else { return }
            let width: CGFloat = CGFloat.random(in: 70...110)
            let height: CGFloat = width * 1.3
            let maxX = max(width + 10, view.bounds.width - width - 10)
            let x = CGFloat.random(in: (width + 10)...maxX)
            let y = CGFloat.random(in: 20...100)

            let card = UIView(frame: CGRect(x: x - width / 2, y: y, width: width, height: height))
            let color = cardColors.randomElement() ?? .systemBlue
            card.backgroundColor = color
            card.layer.cornerRadius = 12
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.25
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.layer.shadowRadius = 8

            let iconName = cardIcons.randomElement() ?? "star.fill"
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            let image = UIImage(systemName: iconName, withConfiguration: config)
            let iconView = UIImageView(image: image)
            iconView.tintColor = .white.withAlphaComponent(0.9)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -8),
            ])

            let label = UILabel()
            label.text = iconName.replacingOccurrences(of: ".fill", with: "").capitalized
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .white.withAlphaComponent(0.8)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            ])

            view.addSubview(card)

            gravity?.addItem(card)
            collision?.addItem(card)
            itemBehavior?.addItem(card)

            cardCount = view.subviews.count

            if view.subviews.count > 25 {
                removeOldestCard()
            }
        }

        func removeOldestCard() {
            guard let view = containerView, let oldest = view.subviews.first else { return }
            gravity?.removeItem(oldest)
            collision?.removeItem(oldest)
            itemBehavior?.removeItem(oldest)
            oldest.removeFromSuperview()
            cardCount = view.subviews.count
        }

        func resetCards() {
            guard let view = containerView else { return }
            for sub in view.subviews {
                gravity?.removeItem(sub)
                collision?.removeItem(sub)
                itemBehavior?.removeItem(sub)
                sub.removeFromSuperview()
            }
            cardCount = 0
            for _ in 0..<4 {
                addCard()
            }
        }

        func cleanup() {
            motionManager.stopDeviceMotionUpdates()
        }

        deinit {
            MainActor.assumeIsolated {
                cleanup()
            }
        }
    }
}

#Preview {
    NavigationStack {
        GravityCardsView()
            .navigationTitle("Gravity Cards")
    }
}
