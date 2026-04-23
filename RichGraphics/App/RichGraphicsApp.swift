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
//
// iOS queries this callback on every rotation check. It must return the
// currently desired orientation mask synchronously, on the main thread.

class AppDelegate: UIResponder, UIApplicationDelegate {
    nonisolated(unsafe) static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}
