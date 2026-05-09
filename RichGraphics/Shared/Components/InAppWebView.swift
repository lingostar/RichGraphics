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
//
// Two language variants of the docs site live at separate URLs:
//   ko → https://lingostar.github.io/RichGraphics/
//   en → https://lingostar.github.io/RichGraphics/en/
// The app picks one based on the user's @AppStorage("docsLanguage")
// preference: "auto" follows the device locale, "ko"/"en" override.

enum DocsLanguage: String, CaseIterable, Identifiable {
    case auto, ko, en

    var id: String { rawValue }
}

@MainActor
final class DocsLoader {
    static let shared = DocsLoader()

    static let docsURL_ko = URL(string: "https://lingostar.github.io/RichGraphics/")!
    static let docsURL_en = URL(string: "https://lingostar.github.io/RichGraphics/en/")!

    /// Resolve the stored preference into a concrete two-letter code.
    /// "auto" follows `Locale.current` ("ko" only when device language is
    /// Korean; everything else falls back to English).
    static func resolved(_ preference: DocsLanguage) -> String {
        switch preference {
        case .auto:
            let lang = Locale.current.language.languageCode?.identifier ?? "en"
            return lang == "ko" ? "ko" : "en"
        case .ko:
            return "ko"
        case .en:
            return "en"
        }
    }

    static func url(forResolvedLanguage code: String) -> URL {
        code == "ko" ? docsURL_ko : docsURL_en
    }

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

    /// Fire one fetch through a hidden WKWebView so the resources are in
    /// disk cache by the time the user taps Study Notes. We preload the
    /// language that matches the device locale (the most likely first
    /// open). Idempotent — first call kicks off the load, later calls
    /// are no-ops.
    func preload() {
        guard !hasPreloaded else { return }
        hasPreloaded = true

        let code = Self.resolved(.auto)
        let view = WKWebView(frame: .zero, configuration: configuration())
        view.load(URLRequest(url: Self.url(forResolvedLanguage: code)))
        preloadView = view
    }
}

// MARK: - Per-presentation WKWebView wrapper

struct PreloadedDocsView: UIViewRepresentable {
    let resolvedLanguage: String

    func makeUIView(context: Context) -> WKWebView {
        // Fresh instance every time the sheet is shown. Disk cache populated
        // by DocsLoader.preload() makes this nearly instant on subsequent
        // opens (no full network round-trip).
        let webView = WKWebView(frame: .zero, configuration: DocsLoader.shared.configuration())
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.load(URLRequest(url: DocsLoader.url(forResolvedLanguage: resolvedLanguage)))
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
    @AppStorage("docsLanguage") private var docsLanguageRaw: String = DocsLanguage.auto.rawValue

    private var preference: DocsLanguage {
        DocsLanguage(rawValue: docsLanguageRaw) ?? .auto
    }

    private var resolvedLanguage: String {
        DocsLoader.resolved(preference)
    }

    var body: some View {
        NavigationStack {
            // .id forces SwiftUI to recreate (and reload) the WKWebView
            // when the user toggles language mid-session.
            PreloadedDocsView(resolvedLanguage: resolvedLanguage)
                .id(resolvedLanguage)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Study Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        languageMenu
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }

    private var languageMenu: some View {
        Menu {
            Picker(selection: $docsLanguageRaw) {
                Text("Auto (\(autoLabel))").tag(DocsLanguage.auto.rawValue)
                Text("한국어").tag(DocsLanguage.ko.rawValue)
                Text("English").tag(DocsLanguage.en.rawValue)
            } label: {
                Text("Language")
            }
        } label: {
            Image(systemName: "globe")
        }
    }

    /// Show what "Auto" currently resolves to so the user understands
    /// the fallback without having to actually pick.
    private var autoLabel: String {
        DocsLoader.resolved(.auto) == "ko" ? "한국어" : "English"
    }
}
