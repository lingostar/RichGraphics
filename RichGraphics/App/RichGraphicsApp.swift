import SwiftUI
import UIKit

@main
struct RichGraphicsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
// Needed for `application(_:supportedInterfaceOrientationsFor:)` callback,
// which is the authoritative hook iOS uses to decide allowed orientations.

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // If a view has locked the orientation, honor it; otherwise allow all.
        MainActor.assumeIsolated {
            OrientationManager.shared.lockedMask ?? .all
        }
    }
}
