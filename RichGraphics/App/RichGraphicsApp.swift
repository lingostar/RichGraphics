import SwiftUI
import UIKit

@main
struct RichGraphicsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    init() {
        // Kick off background preload of the 정리노트 web page so that
        // when the sheet is opened later, the content is already cached.
        DocsLoader.shared.preload()
    }

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
