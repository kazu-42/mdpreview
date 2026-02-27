import SwiftUI
import WebKit

public struct MarkdownWebView: NSViewRepresentable {
    public let markdownContent: String
    public let baseURL: URL?
    public let contentID: UUID?
    public let customCSS: String

    public init(markdownContent: String, baseURL: URL? = nil, contentID: UUID? = nil, customCSS: String = "") {
        self.markdownContent = markdownContent
        self.baseURL = baseURL
        self.contentID = contentID
        self.customCSS = customCSS
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
        context.coordinator.pendingCSS = customCSS
        context.coordinator.baseURL = baseURL
        loadTemplate(into: webView, baseURL: baseURL)

        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        let tabChanged = context.coordinator.currentContentID != contentID
        context.coordinator.currentContentID = contentID

        // If base URL changed, reload template
        if context.coordinator.baseURL != baseURL {
            context.coordinator.baseURL = baseURL
            context.coordinator.isLoaded = false
            context.coordinator.pendingContent = markdownContent
            context.coordinator.pendingPreserveScroll = false
            context.coordinator.pendingCSS = customCSS
            loadTemplate(into: webView, baseURL: baseURL)
            return
        }

        if context.coordinator.isLoaded {
            evaluateRender(webView: webView, content: markdownContent, baseURL: baseURL, preserveScroll: !tabChanged)
            if context.coordinator.currentCustomCSS != customCSS {
                context.coordinator.currentCustomCSS = customCSS
                evaluateApplyCustomCSS(webView: webView, css: customCSS)
            }
        } else {
            context.coordinator.pendingContent = markdownContent
            context.coordinator.pendingPreserveScroll = !tabChanged
            context.coordinator.pendingCSS = customCSS
        }
    }

    private func loadTemplate(into webView: WKWebView, baseURL: URL?) {
        AppLogger.shared.log("loadTemplate called, baseURL: \(baseURL?.path ?? "nil")")

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

        // Log all possible paths for debugging
        for (index, url) in possibleURLs.enumerated() {
            guard let url = url else {
                AppLogger.shared.log("Path \(index): nil")
                continue
            }
            let exists = FileManager.default.fileExists(atPath: url.path)
            AppLogger.shared.log("Path \(index): \(url.path), exists: \(exists)")
        }

        guard let resourceURL = possibleURLs.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            AppLogger.shared.log("ERROR: No template.html found!")
            return
        }

        AppLogger.shared.log("Using template: \(resourceURL.path)")

        // Grant WKWebView read access to both the bundle resources (CSS/JS) and
        // the markdown file's directory (for relative image paths).
        // Use root filesystem as the access scope since we need both locations.
        let readAccessURL = URL(fileURLWithPath: "/")

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

    private func evaluateRender(webView: WKWebView, content: String, baseURL: URL? = nil, preserveScroll: Bool = true) {
        var processedContent = content

        // Convert relative image paths to absolute file URLs
        if let base = baseURL {
            processedContent = Self.rewriteRelativePaths(in: content, baseURL: base)
        }

        let escaped = MarkdownWebView.escapeForJavaScript(processedContent)
        let basePath = baseURL?.path ?? ""
        webView.evaluateJavaScript("render(`\(escaped)`, `\(basePath)`, \(preserveScroll))")

        // Mark broken links using the original (non-rewritten) content
        if let base = baseURL {
            let brokenPaths = MarkdownWebView.extractLocalLinks(in: content, baseURL: base)
            let brokenAbsoluteURLs = brokenPaths.map { "file://\(base.path)/\($0)" }
            if let jsonData = try? JSONEncoder().encode(brokenAbsoluteURLs),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                webView.evaluateJavaScript("markBrokenLinks(\(jsonString))")
            }
        }
    }

    private func evaluateApplyCustomCSS(webView: WKWebView, css: String) {
        let escaped = css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
        webView.evaluateJavaScript("applyCustomCSS(`\(escaped)`)")
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

    /// Extract local file links from markdown and return paths to files that don't exist.
    /// Uses original (non-rewritten) markdown content.
    public static func extractLocalLinks(in markdown: String, baseURL: URL) -> [String] {
        // Match [text](path) links, excluding images (preceded by !)
        let pattern = #"(?<!!)\[[^\]]*\]\(([^)#:\s][^)]*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(markdown.startIndex..., in: markdown)
        var brokenPaths: [String] = []

        for match in regex.matches(in: markdown, range: range) {
            guard match.numberOfRanges >= 2,
                  let pathRange = Range(match.range(at: 1), in: markdown) else { continue }
            var path = String(markdown[pathRange])

            // Skip external URLs
            if path.hasPrefix("http://") || path.hasPrefix("https://") ||
               path.hasPrefix("file://") || path.hasPrefix("//") { continue }
            // Skip absolute paths
            if path.hasPrefix("/") { continue }
            // Skip data URIs
            if path.hasPrefix("data:") { continue }

            // Strip fragment if present
            if let hashIdx = path.firstIndex(of: "#") {
                path = String(path[..<hashIdx])
            }
            if path.isEmpty { continue }

            // Remove leading ./
            if path.hasPrefix("./") { path = String(path.dropFirst(2)) }

            // Check if file exists relative to base URL
            let fullURL = baseURL.appendingPathComponent(path)
            if !FileManager.default.fileExists(atPath: fullURL.path) {
                brokenPaths.append(path)
            }
        }

        return brokenPaths
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        public var webView: WKWebView?
        public var isLoaded = false
        public var pendingContent: String?
        public var pendingPreserveScroll = true
        public var pendingCSS: String = ""
        public var currentCustomCSS: String = ""
        public var baseURL: URL?
        public var currentContentID: UUID?
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
            // Escape for JS single-quoted string (don't percent-encode; IDs use slugified text)
            let escapedAnchor = anchor
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            webView.evaluateJavaScript("scrollToAnchor('\(escapedAnchor)')")
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            AppLogger.shared.log("WebView finished loading")
            isLoaded = true
            if let content = pendingContent {
                let preserveScroll = pendingPreserveScroll
                let css = pendingCSS
                pendingContent = nil
                pendingPreserveScroll = true

                // Convert relative paths to absolute file URLs
                var processedContent = content
                if let base = baseURL {
                    processedContent = MarkdownWebView.rewriteRelativePaths(in: content, baseURL: base)
                }
                let escaped = MarkdownWebView.escapeForJavaScript(processedContent)
                let basePath = baseURL?.path ?? ""
                webView.evaluateJavaScript("render(`\(escaped)`, `\(basePath)`, \(preserveScroll))")

                // Apply custom CSS
                currentCustomCSS = css
                let escapedCSS = css
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                webView.evaluateJavaScript("applyCustomCSS(`\(escapedCSS)`)")

                // Mark broken links using original (non-rewritten) content
                if let base = baseURL {
                    let brokenPaths = MarkdownWebView.extractLocalLinks(in: content, baseURL: base)
                    let brokenAbsoluteURLs = brokenPaths.map { "file://\(base.path)/\($0)" }
                    if let jsonData = try? JSONEncoder().encode(brokenAbsoluteURLs),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        webView.evaluateJavaScript("markBrokenLinks(\(jsonString))")
                    }
                }
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            AppLogger.shared.log("WebView navigation failed: \(error.localizedDescription)")
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            AppLogger.shared.log("WebView provisional navigation failed: \(error.localizedDescription)")
        }

        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Handle link clicks
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {

                // Markdown files: open in app (new tab), passing fragment if present
                if url.isFileURL && isMarkdownFile(url) {
                    let fragment = url.fragment
                    // Create file URL without the fragment
                    let fileURL = URL(fileURLWithPath: url.path)
                    var userInfo: [AnyHashable: Any]? = nil
                    if let fragment = fragment {
                        userInfo = ["fragment": fragment]
                    }
                    NotificationCenter.default.post(name: .didRequestOpenFile, object: fileURL, userInfo: userInfo)
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
