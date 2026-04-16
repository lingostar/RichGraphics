import SwiftUI
import UIKit

struct PendulumView: View {
    var body: some View {
        PendulumContainerFinal()
            .ignoresSafeArea(edges: .bottom)
            .background(Color.black)
    }
}

// MARK: - Newton's Cradle with UIAttachmentBehavior + UISnapBehavior
//
// Key UIKit Dynamics concepts demonstrated:
// - UIAttachmentBehavior: pendulum "strings" connecting balls to anchor points
// - UISnapBehavior: natural touch interaction (pull ball, release to swing)
// - UIGravityBehavior + UICollisionBehavior: momentum transfer between balls
// - KVO on UIView.center + CoreGraphics draw(_:): real-time string rendering

struct PendulumContainerFinal: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> CradleView {
        let view = CradleView()
        view.coordinator = context.coordinator
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.isMultipleTouchEnabled = false
        return view
    }

    func updateUIView(_ uiView: CradleView, context: Context) {
        // Setup is deferred to CradleView.layoutSubviews so bounds are finalized
    }

    // The custom UIView that draws strings
    @MainActor
    final class CradleView: UIView {
        weak var coordinator: Coordinator?
        private var didSetup = false

        override func layoutSubviews() {
            super.layoutSubviews()
            if !didSetup, bounds.width > 0, let coordinator {
                didSetup = true
                coordinator.setupCradle(in: self)
            }
        }

        override func draw(_ rect: CGRect) {
            guard let ctx = UIGraphicsGetCurrentContext(),
                  let coordinator else { return }
            ctx.saveGState()

            for ball in coordinator.ballViews {
                guard let attachment = coordinator.attachmentBehaviors[ball] else { continue }
                let anchor = attachment.anchorPoint

                // String line
                ctx.move(to: anchor)
                ctx.addLine(to: ball.center)
                ctx.setStrokeColor(UIColor(white: 0.5, alpha: 1.0).cgColor)
                ctx.setLineWidth(1.5)
                ctx.strokePath()

                // Anchor dot
                let dotSize: CGFloat = 8
                let dotRect = CGRect(
                    x: anchor.x - dotSize / 2,
                    y: anchor.y - dotSize / 2,
                    width: dotSize, height: dotSize
                )
                ctx.setFillColor(UIColor(white: 0.4, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: dotRect)
            }

            ctx.restoreGState()
        }

        // — Touch handling using UISnapBehavior for natural feel —

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, let coordinator else { return }
            let location = touch.location(in: self)

            for ball in coordinator.ballViews {
                if ball.frame.contains(location) {
                    let snap = UISnapBehavior(item: ball, snapTo: location)
                    snap.damping = 0.5
                    coordinator.animator?.addBehavior(snap)
                    coordinator.snapBehavior = snap
                    break
                }
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, let coordinator else { return }
            let location = touch.location(in: self)
            coordinator.snapBehavior?.snapPoint = location
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let coordinator else { return }
            if let snap = coordinator.snapBehavior {
                coordinator.animator?.removeBehavior(snap)
            }
            coordinator.snapBehavior = nil
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesEnded(touches, with: event)
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var gravity: UIGravityBehavior?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        var snapBehavior: UISnapBehavior?
        weak var containerView: CradleView?
        var ballViews: [UIView] = []
        var attachmentBehaviors: [UIView: UIAttachmentBehavior] = [:]

        private let ballCount = 5
        private let ballDiameter: CGFloat = 44
        private let ballPadding: CGFloat = 1.0

        func setupCradle(in view: CradleView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            // — Gravity —
            let g = UIGravityBehavior()
            g.magnitude = 1.0
            animator?.addBehavior(g)
            gravity = g

            // — Collision —
            let c = UICollisionBehavior()
            animator?.addBehavior(c)
            collision = c

            // — Item Behavior —
            let ib = UIDynamicItemBehavior()
            ib.elasticity = 1.0
            ib.friction = 0.0
            ib.resistance = 0.15
            ib.allowsRotation = false
            animator?.addBehavior(ib)
            itemBehavior = ib

            // — Layout —
            let anchorY = view.bounds.midY - 80
            let ballY = view.bounds.midY + 40
            let stringLength = ballY - anchorY
            let totalWidth = CGFloat(ballCount) * (ballDiameter + ballPadding) - ballPadding
            let startX = view.bounds.midX - totalWidth / 2 + ballDiameter / 2

            // — Top bar —
            let barWidth = totalWidth + 40
            let bar = UIView(frame: CGRect(
                x: view.bounds.midX - barWidth / 2,
                y: anchorY - 4,
                width: barWidth, height: 6
            ))
            bar.backgroundColor = UIColor(white: 0.35, alpha: 1.0)
            bar.layer.cornerRadius = 3
            bar.isUserInteractionEnabled = false
            view.addSubview(bar)

            // — Create balls —
            for i in 0..<ballCount {
                let centerX = startX + CGFloat(i) * (ballDiameter + ballPadding)
                let anchorPoint = CGPoint(x: centerX, y: anchorY)
                let ballCenter = CGPoint(x: centerX, y: ballY)

                let ball = createBall(at: ballCenter)
                view.addSubview(ball)

                // KVO to trigger setNeedsDisplay on the CradleView
                ball.addObserver(self, forKeyPath: "center",
                                 options: NSKeyValueObservingOptions(rawValue: 0),
                                 context: nil)
                ballViews.append(ball)

                // — UIAttachmentBehavior (the pendulum "string") —
                let attachment = UIAttachmentBehavior(item: ball, attachedToAnchor: anchorPoint)
                attachment.length = stringLength
                attachment.damping = 0.0
                attachment.frequency = 0.0
                attachmentBehaviors[ball] = attachment
                animator?.addBehavior(attachment)

                gravity?.addItem(ball)
                collision?.addItem(ball)
                itemBehavior?.addItem(ball)
            }

            // — Instruction label —
            let label = UILabel()
            label.text = "Drag any ball to start"
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = UIColor(white: 0.5, alpha: 1.0)
            label.textAlignment = .center
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            ])
        }

        func createBall(at center: CGPoint) -> UIView {
            let ball = UIView(frame: CGRect(
                x: center.x - ballDiameter / 2,
                y: center.y - ballDiameter / 2,
                width: ballDiameter, height: ballDiameter
            ))
            ball.layer.cornerRadius = ballDiameter / 2

            let gradient = CAGradientLayer()
            gradient.frame = ball.bounds
            gradient.cornerRadius = ballDiameter / 2
            gradient.colors = [
                UIColor(white: 0.85, alpha: 1.0).cgColor,
                UIColor(white: 0.55, alpha: 1.0).cgColor,
                UIColor(white: 0.35, alpha: 1.0).cgColor,
            ]
            gradient.startPoint = CGPoint(x: 0.3, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.7, y: 1.0)
            ball.layer.addSublayer(gradient)

            let highlight = CAGradientLayer()
            highlight.frame = CGRect(
                x: ballDiameter * 0.2, y: ballDiameter * 0.1,
                width: ballDiameter * 0.35, height: ballDiameter * 0.35
            )
            highlight.cornerRadius = highlight.frame.width / 2
            highlight.colors = [
                UIColor(white: 1.0, alpha: 0.6).cgColor,
                UIColor(white: 1.0, alpha: 0.0).cgColor,
            ]
            ball.layer.addSublayer(highlight)

            ball.layer.shadowColor = UIColor.white.cgColor
            ball.layer.shadowOpacity = 0.15
            ball.layer.shadowOffset = CGSize(width: 0, height: 2)
            ball.layer.shadowRadius = 6

            // user interaction is handled by CradleView's touch methods
            ball.isUserInteractionEnabled = false
            return ball
        }

        // MARK: - KVO

        override func observeValue(forKeyPath keyPath: String?,
                                   of object: Any?,
                                   change: [NSKeyValueChangeKey: Any]?,
                                   context: UnsafeMutableRawPointer?) {
            if keyPath == "center" {
                containerView?.setNeedsDisplay()
            }
        }

        deinit {
            MainActor.assumeIsolated {
                for ball in ballViews {
                    ball.removeObserver(self, forKeyPath: "center")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PendulumView()
            .navigationTitle("Pendulum")
    }
}
