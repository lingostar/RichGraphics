import SwiftUI
@preconcurrency import WebKit

// MARK: - DocsLoader
//
// We DO NOT reuse a single WKWebView across sheet presentations — moving
// the same WKWebView between view hierarchies causes intermittent UIKit
// crashes (*** insertObject:atIndex: object cannot be nil) and constraint
// conflicts. Instead, we share a WKProcessPool + the default
// WKWebsiteDataStore: each sheet gets a fresh WKWebView, but the disk
// cache populated by the background preload is shared, so the page renders
// almost instantly on subsequent opens.

@MainActor
final class DocsLoader {
    static let shared = DocsLoader()
    static let docsURL = URL(string: "https://lingostar.github.io/RichGraphics/")!

    // Shared across every WKWebView constructed via configuration().
    private let processPool = WKProcessPool()

    // Hidden web view used only to warm the cache. Retained so the request
    // doesn't get cancelled when this method returns.
    private var preloadView: WKWebView?
    private var hasPreloaded = false

    private init() {}

    /// A WKWebViewConfiguration that points at our shared process pool and
    /// the default website data store, so multiple WKWebView instances all
    /// share a hot cache.
    func configuration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.processPool = processPool
        config.websiteDataStore = .default()
        return config
    }

    /// Fire one fetch of the docs URL through a hidden WKWebView so the
    /// resources are in disk cache by the time the user taps 정리노트.
    /// Idempotent — first call kicks off the load, later calls are no-ops.
    func preload() {
        guard !hasPreloaded else { return }
        hasPreloaded = true

        let view = WKWebView(frame: .zero, configuration: configuration())
        view.load(URLRequest(url: Self.docsURL))
        preloadView = view
    }
}

// MARK: - Per-presentation WKWebView wrapper

struct PreloadedDocsView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        // Fresh instance every time the sheet is shown. Disk cache populated
        // by DocsLoader.preload() makes this nearly instant on subsequent
        // opens (no full network round-trip).
        let webView = WKWebView(frame: .zero, configuration: DocsLoader.shared.configuration())
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.load(URLRequest(url: DocsLoader.docsURL))
        // Make sure preload has fired in case the user opened the sheet
        // before the .task scheduled it.
        DocsLoader.shared.preload()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Docs sheet container

struct DocsWebSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PreloadedDocsView()
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("정리노트")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}
