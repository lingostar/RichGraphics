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
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
