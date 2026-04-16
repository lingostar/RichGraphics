import SwiftUI
import UIKit

struct PendulumView: View {
    var body: some View {
        PendulumContainer()
            .ignoresSafeArea(edges: .bottom)
            .background(Color.black)
    }
}

// MARK: - UIViewRepresentable

struct PendulumContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.animator == nil {
            coordinator.setupCradle(in: uiView)
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var animator: UIDynamicAnimator?
        var gravity: UIGravityBehavior?
        var collision: UICollisionBehavior?
        var itemBehavior: UIDynamicItemBehavior?
        weak var containerView: UIView?
        var ballViews: [UIView] = []
        var stringLayers: [CAShapeLayer] = []
        var attachmentAnchors: [CGPoint] = []
        var displayLink: CADisplayLink?

        private let ballCount = 5
        private let ballDiameter: CGFloat = 40
        private let stringLength: CGFloat = 200

        func setupCradle(in view: UIView) {
            containerView = view
            animator = UIDynamicAnimator(referenceView: view)

            let g = UIGravityBehavior()
            animator?.addBehavior(g)
            gravity = g

            let c = UICollisionBehavior()
            animator?.addBehavior(c)
            collision = c

            let ib = UIDynamicItemBehavior()
            ib.elasticity = 1.0
            ib.friction = 0.0
            ib.resistance = 0.0
            ib.angularResistance = CGFloat.greatestFiniteMagnitude
            ib.allowsRotation = false
            animator?.addBehavior(ib)
            itemBehavior = ib

            // Top bar
            let barWidth = CGFloat(ballCount) * ballDiameter + CGFloat(ballCount - 1) * 2 + 40
            let barX = view.bounds.midX - barWidth / 2
            let barY: CGFloat = 80

            let bar = UIView(frame: CGRect(x: barX, y: barY, width: barWidth, height: 6))
            bar.backgroundColor = UIColor(white: 0.35, alpha: 1.0)
            bar.layer.cornerRadius = 3
            view.addSubview(bar)

            // Create balls
            let totalBallsWidth = CGFloat(ballCount) * ballDiameter + CGFloat(ballCount - 1) * 2
            let startX = view.bounds.midX - totalBallsWidth / 2 + ballDiameter / 2

            for i in 0..<ballCount {
                let anchorX = startX + CGFloat(i) * (ballDiameter + 2)
                let anchorY = barY + 3
                let anchorPoint = CGPoint(x: anchorX, y: anchorY)
                attachmentAnchors.append(anchorPoint)

                let ballCenter = CGPoint(x: anchorX, y: anchorY + stringLength)
                let ball = createBall(at: ballCenter)
                view.addSubview(ball)
                ballViews.append(ball)

                gravity?.addItem(ball)
                collision?.addItem(ball)
                itemBehavior?.addItem(ball)

                // Attachment (string)
                let attachment = UIAttachmentBehavior(item: ball, attachedToAnchor: anchorPoint)
                attachment.length = stringLength
                attachment.damping = 0.0
                attachment.frequency = 0.0
                animator?.addBehavior(attachment)

                // String visual
                let stringLayer = CAShapeLayer()
                stringLayer.strokeColor = UIColor(white: 0.5, alpha: 1.0).cgColor
                stringLayer.lineWidth = 1.5
                stringLayer.fillColor = nil
                view.layer.addSublayer(stringLayer)
                stringLayers.append(stringLayer)

                // Pan gesture on end balls
                if i == 0 || i == ballCount - 1 {
                    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                    ball.addGestureRecognizer(pan)
                    ball.isUserInteractionEnabled = true
                }
            }

            // Display link for string drawing
            displayLink = CADisplayLink(target: self, selector: #selector(updateStrings))
            displayLink?.add(to: .main, forMode: .common)

            // Instruction label
            let instructionLabel = UILabel()
            instructionLabel.text = "Drag an end ball to start"
            instructionLabel.font = .systemFont(ofSize: 14, weight: .medium)
            instructionLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
            instructionLabel.textAlignment = .center
            instructionLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(instructionLabel)
            NSLayoutConstraint.activate([
                instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                instructionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            ])
        }

        func createBall(at center: CGPoint) -> UIView {
            let ball = UIView(frame: CGRect(
                x: center.x - ballDiameter / 2,
                y: center.y - ballDiameter / 2,
                width: ballDiameter,
                height: ballDiameter
            ))
            ball.layer.cornerRadius = ballDiameter / 2

            // Metallic gradient
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

            // Highlight
            let highlight = CAGradientLayer()
            highlight.frame = CGRect(x: ballDiameter * 0.2, y: ballDiameter * 0.1,
                                     width: ballDiameter * 0.35, height: ballDiameter * 0.35)
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

            return ball
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let ball = gesture.view, let view = containerView else { return }
            let location = gesture.location(in: view)

            guard let index = ballViews.firstIndex(of: ball) else { return }
            let anchor = attachmentAnchors[index]

            switch gesture.state {
            case .began, .changed:
                // Constrain to string length radius
                let dx = location.x - anchor.x
                let dy = location.y - anchor.y
                let distance = hypot(dx, dy)
                if distance > stringLength {
                    let ratio = stringLength / distance
                    ball.center = CGPoint(x: anchor.x + dx * ratio, y: anchor.y + dy * ratio)
                } else {
                    ball.center = location
                }
                animator?.updateItem(usingCurrentState: ball)
            case .ended, .cancelled:
                animator?.updateItem(usingCurrentState: ball)
            default:
                break
            }
        }

        @objc func updateStrings() {
            for (i, ball) in ballViews.enumerated() where i < stringLayers.count {
                let path = UIBezierPath()
                path.move(to: attachmentAnchors[i])
                path.addLine(to: ball.center)
                stringLayers[i].path = path.cgPath
            }
        }

        func cleanup() {
            displayLink?.invalidate()
            displayLink = nil
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
        PendulumView()
            .navigationTitle("Pendulum")
    }
}
