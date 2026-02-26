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
        // Find template.html - check app bundle locations first to avoid triggering
        // Bundle.module's resource_bundle_accessor which crashes in packaged apps
        let possibleURLs: [URL?] = [
            // App bundle: MDPreview_MDPreviewCore.bundle/Resources/template.html
            Bundle.main.url(forResource: "MDPreview_MDPreviewCore", withExtension: "bundle")?
                .appendingPathComponent("Resources/template.html"),
            // Direct in Resources folder
            Bundle.main.resourceURL?.appendingPathComponent("MDPreview_MDPreviewCore.bundle/Resources/template.html"),
            // Fallback: try root Resources
            Bundle.main.url(forResource: "template", withExtension: "html"),
            // Last resort: Bundle.module (only works in SPM builds/tests)
            safeModuleURL(forResource: "template", withExtension: "html", subdirectory: "Resources")
        ]

        guard let resourceURL = possibleURLs.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
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

    /// Safely access Bundle.module without crashing in packaged apps
    private func safeModuleURL(forResource name: String, withExtension ext: String?, subdirectory: String?) -> URL? {
        // Only use Bundle.module if we're not in a packaged app
        // Check if Bundle.main has an Info.plist (indicates packaged app)
        guard Bundle.main.infoDictionary != nil,
              Bundle.main.bundleIdentifier != nil else {
            // Not a packaged app, safe to use Bundle.module
            return Bundle.module.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        }

        // In packaged app, try to find the module bundle manually
        let moduleName = "MDPreview_MDPreviewCore"
        if let bundleURL = Bundle.main.url(forResource: moduleName, withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
            }
        }
        return nil
    }

    private func evaluateRender(webView: WKWebView, content: String, baseURL: URL? = nil) {
        var processedContent = content

        // Convert relative image paths to absolute file URLs
        if let base = baseURL {
            processedContent = Self.rewriteRelativePaths(in: content, baseURL: base)
        }

        let escaped = MarkdownWebView.escapeForJavaScript(processedContent)
        let basePath = baseURL?.path ?? ""
        webView.evaluateJavaScript("render(`\(escaped)`, `\(basePath)`)")
    }

    /// Rewrite relative image and link paths to absolute file URLs
    private static func rewriteRelativePaths(in markdown: String, baseURL: URL) -> String {
        let baseDirectory = baseURL.path

        // Pattern to match markdown images and links with relative paths
        // Matches: ![](./image.png), ![](screenshots/img.png), [](./file.md)
        // Does NOT match: ![](http://...), ![](https://...), ![](#anchor)
        let relativePattern = #"(!?\[[^\]]*\]\()(\.\/[^)]+|[^)#:\s][^)]*[^\)#:\s])(\))"#

        var result = markdown

        // Use NSDataDetector-like approach with regex
        if let regex = try? NSRegularExpression(pattern: relativePattern, options: []) {
            let range = NSRange(markdown.startIndex..., in: markdown)
            let matches = regex.matches(in: markdown, options: [], range: range)

            // Process matches in reverse order to maintain correct indices
            for match in matches.reversed() {
                guard match.numberOfRanges >= 3,
                      let prefixRange = Range(match.range(at: 1), in: markdown),
                      let pathRange = Range(match.range(at: 2), in: markdown) else {
                    continue
                }

                let prefix = String(markdown[prefixRange])  // ![]( or [](
                var relativePath = String(markdown[pathRange])  // ./image.png or screenshots/img.png

                // Skip if already an absolute URL or anchor
                if relativePath.hasPrefix("http://") ||
                   relativePath.hasPrefix("https://") ||
                   relativePath.hasPrefix("file://") ||
                   relativePath.hasPrefix("#") ||
                   relativePath.hasPrefix("/") ||
                   relativePath.hasPrefix("data:") {
                    continue
                }

                // Remove leading ./
                if relativePath.hasPrefix("./") {
                    relativePath = String(relativePath.dropFirst(2))
                }

                // Construct absolute file URL
                let absolutePath = "file://\(baseDirectory)/\(relativePath)"

                // Replace in result
                if let fullMatchRange = Range(match.range, in: result) {
                    let replacement = "\(prefix)\(absolutePath))"
                    result.replaceSubrange(fullMatchRange, with: replacement)
                }
            }
        }

        return result
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
        private var scrollObserver: NSObjectProtocol?

        override init() {
            super.init()
            // Listen for scroll to anchor notifications
            scrollObserver = NotificationCenter.default.addObserver(
                forName: .scrollToAnchor,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let anchor = notification.object as? String else { return }
                self?.scrollToAnchor(anchor)
            }
        }

        deinit {
            if let observer = scrollObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func scrollToAnchor(_ anchor: String) {
            guard let webView = webView else { return }
            let escapedAnchor = anchor.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? anchor
            webView.evaluateJavaScript("scrollToAnchor('\(escapedAnchor)')")
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let content = pendingContent {
                pendingContent = nil
                // Convert relative paths to absolute file URLs
                var processedContent = content
                if let base = baseURL {
                    processedContent = MarkdownWebView.rewriteRelativePaths(in: content, baseURL: base)
                }
                let escaped = MarkdownWebView.escapeForJavaScript(processedContent)
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
