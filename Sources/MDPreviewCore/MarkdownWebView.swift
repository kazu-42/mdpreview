import SwiftUI
import WebKit

public struct MarkdownWebView: NSViewRepresentable {
    public let markdownContent: String

    public init(markdownContent: String) {
        self.markdownContent = markdownContent
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator

        context.coordinator.webView = webView
        context.coordinator.pendingContent = markdownContent
        loadTemplate(into: webView)

        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.isLoaded {
            evaluateRender(webView: webView, content: markdownContent)
        } else {
            context.coordinator.pendingContent = markdownContent
        }
    }

    private func loadTemplate(into webView: WKWebView) {
        guard let resourceURL = Bundle.module.url(
            forResource: "template",
            withExtension: "html",
            subdirectory: "Resources"
        ) else {
            return
        }
        webView.loadFileURL(
            resourceURL,
            allowingReadAccessTo: resourceURL.deletingLastPathComponent()
        )
    }

    private func evaluateRender(webView: WKWebView, content: String) {
        let escaped = MarkdownWebView.escapeForJavaScript(content)
        webView.evaluateJavaScript("render(`\(escaped)`)")
    }

    /// Escape a string for safe embedding in a JavaScript template literal.
    /// Exposed as static for testing.
    public static func escapeForJavaScript(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        public var webView: WKWebView?
        public var isLoaded = false
        public var pendingContent: String?

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let content = pendingContent {
                pendingContent = nil
                let escaped = MarkdownWebView.escapeForJavaScript(content)
                webView.evaluateJavaScript("render(`\(escaped)`)")
            }
        }

        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Open external links in the default browser
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
