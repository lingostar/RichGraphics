import SwiftUI
import UIKit

@main
struct RichGraphicsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Defer the WKWebView preload until AFTER the first frame
                    // is on screen. WKWebView spins up three helper processes
                    // (GPU / WebContent / Networking), and doing it during
                    // App.init() blocks the launch path by 10+ seconds.
                    // This way the UI is interactive immediately and the
                    // docs page loads quietly in the background.
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
                    DocsLoader.shared.preload()
                }
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
