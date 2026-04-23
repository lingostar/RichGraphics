import SwiftUI
@preconcurrency import WebKit

// MARK: - In-app Web View

struct InAppWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Docs sheet container

struct DocsWebSheet: View {
    @Environment(\.dismiss) private var dismiss
    static let docsURL = URL(string: "https://lingostar.github.io/RichGraphics/")!

    var body: some View {
        NavigationStack {
            InAppWebView(url: Self.docsURL)
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
