import SwiftUI
@preconcurrency import WebKit

// MARK: - DocsLoader
//
// A single WKWebView instance held for the lifetime of the app, so the
// 정리노트 docs page can be pre-fetched at launch and rendered instantly
// when the sheet is presented.

@MainActor
final class DocsLoader: ObservableObject {
    static let shared = DocsLoader()
    static let docsURL = URL(string: "https://lingostar.github.io/RichGraphics/")!

    let webView: WKWebView
    private var hasStartedLoading = false

    private init() {
        let config = WKWebViewConfiguration()
        let pool = WKProcessPool()
        config.processPool = pool
        // Cache pages aggressively so subsequent presentations are immediate.
        config.websiteDataStore = .default()

        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        // Force-instantiate the renderer so the network request can begin
        // before the view is ever attached to a window.
        view.isOpaque = false
        self.webView = view
    }

    /// Begin loading the docs URL. Safe to call multiple times — only the
    /// first call kicks off the request.
    func preload() {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        webView.load(URLRequest(url: Self.docsURL))
    }
}

// MARK: - Wrapper that reuses the shared WKWebView

struct PreloadedDocsView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = DocsLoader.shared.webView
        // Ensure loading has started in case preload() wasn't called yet.
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
