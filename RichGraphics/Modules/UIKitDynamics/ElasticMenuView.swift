import SwiftUI
import UIKit

struct ElasticMenuView: View {
    var body: some View {
        ElasticMenuContainer()
            .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - UIViewRepresentable

struct ElasticMenuContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemGroupedBackground
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.animator == nil {
            coordinator.setupMenu(in: uiView)
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        weak var containerView: UIView?
        var menuItems: [UIView] = []
        var attachments: [UIAttachmentBehavior] = []
        var idealPositions: [CGPoint] = []
        var draggedItem: UIView?

        private let menuData: [(icon: String, label: String, color: UIColor)] = [
            ("house.fill", "Home", .systemBlue),
            ("magnifyingglass", "Search", .systemPurple),
            ("bell.fill", "Notifications", .systemOrange),
            ("message.fill", "Messages", .systemGreen),
            ("person.fill", "Profile", .systemPink),
            ("gearshape.fill", "Settings", .systemGray),
        ]

        private let itemHeight: CGFloat = 64
        private let itemSpacing: CGFloat = 8
        private let horizontalPadding: CGFloat = 20

        func setupMenu(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let c = UICollisionBehavior()
            c.translatesReferenceBoundsIntoBoundary = true
            animator?.addBehavior(c)
            collision = c

            let ib = UIDynamicItemBehavior()
            ib.allowsRotation = false
            ib.resistance = 8.0
            ib.friction = 0.5
            animator?.addBehavior(ib)
            itemBehavior = ib

            let totalHeight = CGFloat(menuData.count) * itemHeight + CGFloat(menuData.count - 1) * itemSpacing
            let startY = (view.bounds.height - totalHeight) / 2

            for (index, data) in menuData.enumerated() {
                let itemWidth = view.bounds.width - horizontalPadding * 2
                let y = startY + CGFloat(index) * (itemHeight + itemSpacing)
                let center = CGPoint(x: view.bounds.midX, y: y + itemHeight / 2)
                idealPositions.append(center)

                let item = createMenuItem(
                    frame: CGRect(x: horizontalPadding, y: y, width: itemWidth, height: itemHeight),
                    icon: data.icon,
                    label: data.label,
                    color: data.color
                )
                view.addSubview(item)
                menuItems.append(item)

                collision?.addItem(item)
                itemBehavior?.addItem(item)

                // Spring attachment to ideal position
                let attachment = UIAttachmentBehavior(item: item, attachedToAnchor: center)
                attachment.length = 0
                attachment.damping = 0.5
                attachment.frequency = 2.5
                animator?.addBehavior(attachment)
                attachments.append(attachment)

                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                item.addGestureRecognizer(pan)
                item.isUserInteractionEnabled = true
            }

            // Chain items together with weaker springs
            for i in 0..<(menuItems.count - 1) {
                let chain = UIAttachmentBehavior(item: menuItems[i], attachedTo: menuItems[i + 1])
                chain.length = itemHeight + itemSpacing
                chain.damping = 0.4
                chain.frequency = 1.5
                animator?.addBehavior(chain)
            }
        }

        func createMenuItem(frame: CGRect, icon: String, label: String, color: UIColor) -> UIView {
            let item = UIView(frame: frame)
            item.backgroundColor = .secondarySystemGroupedBackground
            item.layer.cornerRadius = 14
            item.layer.shadowColor = UIColor.black.cgColor
            item.layer.shadowOpacity = 0.08
            item.layer.shadowOffset = CGSize(width: 0, height: 2)
            item.layer.shadowRadius = 6

            let iconBg = UIView()
            iconBg.backgroundColor = color.withAlphaComponent(0.15)
            iconBg.layer.cornerRadius = 10
            iconBg.translatesAutoresizingMaskIntoConstraints = false
            item.addSubview(iconBg)

            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
            iconView.tintColor = color
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconBg.addSubview(iconView)

            let titleLabel = UILabel()
            titleLabel.text = label
            titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textColor = .label
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            item.addSubview(titleLabel)

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)))
            chevron.tintColor = .tertiaryLabel
            chevron.translatesAutoresizingMaskIntoConstraints = false
            item.addSubview(chevron)

            NSLayoutConstraint.activate([
                iconBg.leadingAnchor.constraint(equalTo: item.leadingAnchor, constant: 14),
                iconBg.centerYAnchor.constraint(equalTo: item.centerYAnchor),
                iconBg.widthAnchor.constraint(equalToConstant: 40),
                iconBg.heightAnchor.constraint(equalToConstant: 40),

                iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),

                titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 14),
                titleLabel.centerYAnchor.constraint(equalTo: item.centerYAnchor),

                chevron.trailingAnchor.constraint(equalTo: item.trailingAnchor, constant: -16),
                chevron.centerYAnchor.constraint(equalTo: item.centerYAnchor),
            ])

            return item
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let item = gesture.view, let view = containerView else { return }
            let location = gesture.location(in: view)

            switch gesture.state {
            case .began:
                draggedItem = item
                UIView.animate(withDuration: 0.15) {
                    item.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                    item.layer.shadowOpacity = 0.15
                }
            case .changed:
                // Only move vertically
                item.center = CGPoint(x: item.center.x, y: location.y)
                animator?.updateItem(usingCurrentState: item)
            case .ended, .cancelled:
                draggedItem = nil
                UIView.animate(withDuration: 0.15) {
                    item.transform = .identity
                    item.layer.shadowOpacity = 0.08
                }
                animator?.updateItem(usingCurrentState: item)
            default:
                break
            }
        }
    }
}

#Preview {
    NavigationStack {
        ElasticMenuView()
            .navigationTitle("Elastic Menu")
    }
}
