import SwiftUI
import UIKit

// MARK: - Disable interactive pop gesture (swipe-back)
// This is needed because many demo views have full-screen touch interactions
// (drawing, SpriteKit, particles, etc.) that conflict with the edge swipe gesture.

extension View {
    /// Disables the navigation swipe-back gesture on this view.
    func disableSwipeBack() -> some View {
        self.background(SwipeBackDisablerRepresentable())
    }
}

private struct SwipeBackDisablerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DisablerViewController {
        DisablerViewController()
    }

    func updateUIViewController(_ uiViewController: DisablerViewController, context: Context) {}

    final class DisablerViewController: UIViewController {
        private var gestureDelegate: GestureBlocker?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            disablePopGesture()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            // Belt-and-suspenders: also try here in case viewDidAppear was too early
            disablePopGesture()
        }

        private func disablePopGesture() {
            guard let recognizer = navigationController?.interactivePopGestureRecognizer else { return }
            recognizer.isEnabled = false
            // Also override the delegate to block the gesture entirely
            if gestureDelegate == nil {
                gestureDelegate = GestureBlocker()
            }
            recognizer.delegate = gestureDelegate
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            guard let recognizer = navigationController?.interactivePopGestureRecognizer else { return }
            recognizer.isEnabled = true
            recognizer.delegate = nil
        }
    }

    // Gesture delegate that always returns false → gesture never begins
    final class GestureBlocker: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }
    }
}
