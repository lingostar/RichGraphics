import SwiftUI
import UIKit

// MARK: - Disable interactive pop gesture (swipe-back)
// This is needed because many demo views have full-screen touch interactions
// (drawing, SpriteKit, particles, etc.) that conflict with the edge swipe gesture.

extension View {
    /// Disables the navigation swipe-back gesture on this view.
    func disableSwipeBack() -> some View {
        self.background(SwipeBackDisablerView())
    }
}

/// Uses a UIView (not UIViewController) to find and disable the pop gesture recognizer
/// by walking up the responder chain and also scanning gesture recognizers on the
/// hosting UINavigationController's view.
private struct SwipeBackDisablerView: UIViewRepresentable {
    func makeUIView(context: Context) -> DisablerUIView {
        let view = DisablerUIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: DisablerUIView, context: Context) {}

    final class DisablerUIView: UIView {
        private var gestureBlocker: GestureBlocker?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                DispatchQueue.main.async { [weak self] in
                    self?.disableSwipeBack()
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            disableSwipeBack()
        }

        private func disableSwipeBack() {
            // Strategy 1: Find UINavigationController via responder chain
            if let navController = findNavigationController() {
                if let recognizer = navController.interactivePopGestureRecognizer {
                    recognizer.isEnabled = false
                    if gestureBlocker == nil {
                        gestureBlocker = GestureBlocker()
                    }
                    recognizer.delegate = gestureBlocker
                    return
                }
            }

            // Strategy 2: Walk up the view hierarchy and disable any
            // UIScreenEdgePanGestureRecognizer (which powers the swipe-back)
            var current: UIView? = self.superview
            while let view = current {
                for recognizer in view.gestureRecognizers ?? [] {
                    if recognizer is UIScreenEdgePanGestureRecognizer {
                        recognizer.isEnabled = false
                        if gestureBlocker == nil {
                            gestureBlocker = GestureBlocker()
                        }
                        recognizer.delegate = gestureBlocker
                    }
                }
                current = view.superview
            }
        }

        private func findNavigationController() -> UINavigationController? {
            var responder: UIResponder? = self
            while let current = responder {
                if let navController = current as? UINavigationController {
                    return navController
                }
                responder = current.next
            }
            return nil
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            if newWindow == nil {
                restoreSwipeBack()
            }
        }

        private func restoreSwipeBack() {
            if let navController = findNavigationController() {
                navController.interactivePopGestureRecognizer?.isEnabled = true
                navController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }

    final class GestureBlocker: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
    }
}
