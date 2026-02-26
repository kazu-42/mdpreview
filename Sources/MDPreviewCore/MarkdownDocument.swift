import SwiftUI
import AppKit

public final class MarkdownDocument: ObservableObject {
    @Published public var markdownContent: String = ""
    @Published public var fileURL: URL?
    @Published public var errorMessage: String?

    private let fileWatcher = FileWatcher()

    public init() {}

    public var displayName: String {
        fileURL?.lastPathComponent ?? "MDPreview"
    }

    public func open(path: String) {
        let url: URL
        if path.hasPrefix("/") || path.hasPrefix("~") {
            url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        } else {
            // Resolve relative path from the working directory
            let cwd = FileManager.default.currentDirectoryPath
            url = URL(fileURLWithPath: cwd).appendingPathComponent(path)
        }
        open(url: url)
    }

    public func open(url: URL) {
        fileURL = url
        errorMessage = nil
        reload()
        fileWatcher.watch(url: url) { [weak self] in
            self?.reload()
        }
    }

    public func reload() {
        guard let url = fileURL else { return }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            DispatchQueue.main.async {
                self.markdownContent = content
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a Markdown file"

        if panel.runModal() == .OK, let url = panel.url {
            open(url: url)
        }
    }
}
