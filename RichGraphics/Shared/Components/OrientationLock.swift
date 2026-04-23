import SwiftUI
import UIKit

// MARK: - Orientation Manager
//
// Views that rely on device motion (gravity, tilt) need a stable orientation
// so the physics feel correct relative to the user's frame of reference.
// This manager lets any view request an orientation lock on appear and
// release it on disappear. The AppDelegate consults this manager to decide
// which orientations to report via supportedInterfaceOrientationsFor.

@MainActor
final class OrientationManager: ObservableObject {
    static let shared = OrientationManager()

    /// nil = no lock (all supported orientations allowed)
    /// non-nil = only this mask is allowed, and UI will rotate to match
    @Published private(set) var lockedMask: UIInterfaceOrientationMask?

    private init() {}

    func lock(to mask: UIInterfaceOrientationMask) {
        lockedMask = mask
        forceUpdate(mask: mask)
    }

    func unlock() {
        lockedMask = nil
        // Reset back to the full mask so the system picks whatever is appropriate
        forceUpdate(mask: .all)
    }

    private func forceUpdate(mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        scene.requestGeometryUpdate(prefs) { _ in
            // errors are non-fatal; the next rotation attempt will reconcile
        }
        // Ask every view controller in the window to re-query supported orientations
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

// MARK: - View Modifier

extension View {
    /// Locks the device orientation to the given mask while this view is on screen.
    /// An indicator badge appears in the top-trailing corner to inform the user.
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
        case .landscapeLeft: "Landscape"
        case .landscapeRight: "Landscape"
        case .landscape: "Landscape"
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
