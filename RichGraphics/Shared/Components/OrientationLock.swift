import SwiftUI
import UIKit

// MARK: - Orientation Manager
//
// App starts with no lock (.all). Specific views may call lock(to:) on
// appear and unlock() on disappear. The lock mask is stored both on this
// manager (for UI observation) AND on AppDelegate.orientationLock (which
// is what iOS actually reads on every rotation check).

@MainActor
final class OrientationManager: ObservableObject {
    static let shared = OrientationManager()

    /// nil = no lock (all supported orientations allowed)
    @Published private(set) var lockedMask: UIInterfaceOrientationMask?

    private init() {}

    func lock(to mask: UIInterfaceOrientationMask) {
        lockedMask = mask
        AppDelegate.orientationLock = mask
        applyRotation(mask: mask)
    }

    func unlock() {
        lockedMask = nil
        AppDelegate.orientationLock = .all
        applyRotation(mask: .all)
    }

    private func applyRotation(mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        // 1) Force immediate rotation to match the new mask.
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }

        // 2) Invalidate cached supported orientations on every VC so the
        //    next rotation check re-queries AppDelegate.
        for window in scene.windows {
            window.rootViewController?.forceOrientationUpdate()
        }
    }
}

private extension UIViewController {
    /// Recursively marks the VC tree as needing an orientation refresh.
    func forceOrientationUpdate() {
        setNeedsUpdateOfSupportedInterfaceOrientations()
        for child in children {
            child.forceOrientationUpdate()
        }
        presentedViewController?.forceOrientationUpdate()
    }
}

// MARK: - View Modifier

extension View {
    /// Locks the device orientation to the given mask while this view is on screen.
    /// A small badge appears in the top-trailing corner to inform the user.
    func lockOrientation(_ mask: UIInterfaceOrientationMask) -> some View {
        modifier(OrientationLockModifier(mask: mask))
    }
}

private struct OrientationLockModifier: ViewModifier {
    let mask: UIInterfaceOrientationMask
    @StateObject private var manager = OrientationManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if manager.lockedMask != nil {
                    OrientationLockBadge(label: label(for: mask))
                        .padding(.top, 8)
                        .padding(.trailing, 12)
                        .transition(.opacity.combined(with: .scale))
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                manager.lock(to: mask)
            }
            .onDisappear {
                manager.unlock()
            }
    }

    private func label(for mask: UIInterfaceOrientationMask) -> String {
        switch mask {
        case .portrait: "Portrait"
        case .portraitUpsideDown: "Upside Down"
        case .landscapeLeft, .landscapeRight, .landscape: "Landscape"
        default: "Locked"
        }
    }
}

// MARK: - Badge

private struct OrientationLockBadge: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.rotation")
                .font(.caption.weight(.semibold))
            Text("\(label) Locked")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.6), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}
