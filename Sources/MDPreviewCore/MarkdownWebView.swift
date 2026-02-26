import SwiftUI
import WebKit

public struct MarkdownWebView: NSViewRepresentable {
    public let markdownContent: String
    public let baseURL: URL?

    public init(markdownContent: String, baseURL: URL? = nil) {
        self.markdownContent = markdownContent
        self.baseURL = baseURL
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
        context.coordinator.baseURL = baseURL
        loadTemplate(into: webView, baseURL: baseURL)

        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        // Update base URL if changed
        if context.coordinator.baseURL != baseURL {
            context.coordinator.baseURL = baseURL
            loadTemplate(into: webView, baseURL: baseURL)
        }

        if context.coordinator.isLoaded {
            evaluateRender(webView: webView, content: markdownContent, baseURL: baseURL)
        } else {
            context.coordinator.pendingContent = markdownContent
        }
    }

    private func loadTemplate(into webView: WKWebView, baseURL: URL?) {
        guard let resourceURL = Bundle.module.url(
            forResource: "template",
            withExtension: "html",
            subdirectory: "Resources"
        ) else {
            return
        }

        // Use the markdown file's directory as base URL for resolving relative paths
        let readAccessURL: URL
        if let base = baseURL {
            readAccessURL = base
        } else {
            readAccessURL = resourceURL.deletingLastPathComponent()
        }

        webView.loadFileURL(resourceURL, allowingReadAccessTo: readAccessURL)
    }

    private func evaluateRender(webView: WKWebView, content: String, baseURL: URL? = nil) {
        let escaped = MarkdownWebView.escapeForJavaScript(content)
        let basePath = baseURL?.path ?? ""
        webView.evaluateJavaScript("render(`\(escaped)`, `\(basePath)`)")
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
        public var baseURL: URL?

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let content = pendingContent {
                pendingContent = nil
                let escaped = MarkdownWebView.escapeForJavaScript(content)
                let basePath = baseURL?.path ?? ""
                webView.evaluateJavaScript("render(`\(escaped)`, `\(basePath)`)")
            }
        }

        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Handle link clicks
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {

                // Markdown files: open in app (new tab)
                if url.isFileURL && isMarkdownFile(url) {
                    NotificationCenter.default.post(name: .didRequestOpenFile, object: url)
                    decisionHandler(.cancel)
                    return
                }

                // Other local file URLs (images, etc.): allow in webview
                if url.isFileURL {
                    decisionHandler(.allow)
                    return
                }

                // External links: open in default browser
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        private func isMarkdownFile(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return ext == "md" || ext == "markdown" || ext == "mdown" || ext == "mkd"
        }
    }
}
