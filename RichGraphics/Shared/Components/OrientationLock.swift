import SwiftUI
import UIKit

// MARK: - Orientation Manager
//
// The lock is applied through two cooperating mechanisms:
//
// 1. `AppDelegate.orientationLock` — the mask iOS reads on every rotation check.
// 2. `UIDevice.orientationDidChangeNotification` — a belt-and-suspenders
//    observer that re-issues requestGeometryUpdate the moment the physical
//    device rotates, so even if iOS's internal caching misses the AppDelegate
//    callback, we snap the UI back to the locked orientation.

@MainActor
final class OrientationManager: ObservableObject {
    static let shared = OrientationManager()

    @Published private(set) var lockedMask: UIInterfaceOrientationMask?

    private var motionObserver: NSObjectProtocol?

    private init() {}

    func lock(to mask: UIInterfaceOrientationMask) {
        lockedMask = mask
        AppDelegate.orientationLock = mask
        applyRotation(mask: mask)
        startObservingDeviceOrientation()
    }

    func unlock() {
        lockedMask = nil
        AppDelegate.orientationLock = .all
        stopObservingDeviceOrientation()
        applyRotation(mask: .all)
    }

    // MARK: Private

    private func applyRotation(mask: UIInterfaceOrientationMask) {
        // 1) Invalidate cached supportedInterfaceOrientations on every VC
        //    before requesting the geometry change.
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.rootViewController?.forceOrientationUpdate()
            }
        }

        // 2) Request the rotation on the foreground scene.
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        scene.requestGeometryUpdate(prefs) { _ in }
    }

    private func startObservingDeviceOrientation() {
        stopObservingDeviceOrientation()

        if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }

        motionObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let mask = self.lockedMask else { return }
                // Re-issue the geometry request; iOS will rotate back to the
                // locked orientation if the physical device drifted away from it.
                self.applyRotation(mask: mask)
            }
        }
    }

    private func stopObservingDeviceOrientation() {
        if let observer = motionObserver {
            NotificationCenter.default.removeObserver(observer)
            motionObserver = nil
        }
    }
}

private extension UIViewController {
    /// Recursively flags children and presented VCs as needing an orientation refresh.
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
