import SwiftUI
import AppKit

public struct TabItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL

    public var name: String { url.lastPathComponent }

    public static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

public final class Workspace: ObservableObject {
    @Published public var tabs: [TabItem] = []
    @Published public var selectedTabID: UUID?
    @Published public var directoryURL: URL?
    @Published public var fileTreeNodes: [FileTreeNode] = []
    @Published public var markdownContent: String = ""
    @Published public var errorMessage: String?

    private let fileWatcher = FileWatcher()

    public init() {}

    public var selectedTab: TabItem? {
        guard let id = selectedTabID else { return nil }
        return tabs.first { $0.id == id }
    }

    public var displayName: String {
        if let tab = selectedTab {
            if let dir = directoryURL {
                return "\(tab.name) — \(dir.lastPathComponent)"
            }
            return tab.name
        }
        if let dir = directoryURL {
            return dir.lastPathComponent
        }
        return "MDPreview"
    }

    // MARK: - Opening

    public func openFile(_ url: URL) {
        let standardized = url.standardizedFileURL
        if let existing = tabs.first(where: { $0.url.standardizedFileURL == standardized }) {
            selectTab(existing.id)
            return
        }
        let tab = TabItem(url: standardized)
        tabs.append(tab)
        selectTab(tab.id)
    }

    public func openDirectory(_ url: URL) {
        directoryURL = url.standardizedFileURL
        fileTreeNodes = FileTreeNode.buildTree(from: url)
    }

    public func openURL(_ url: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            errorMessage = "File not found: \(url.path)"
            return
        }
        if isDir.boolValue {
            openDirectory(url)
        } else {
            openFile(url)
        }
    }

    public func openFromPath(_ path: String) {
        let url: URL
        if path.hasPrefix("/") || path.hasPrefix("~") {
            url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            url = URL(fileURLWithPath: cwd).appendingPathComponent(path)
        }
        openURL(url)
    }

    // MARK: - Tabs

    public func selectTab(_ id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        selectedTabID = tab.id
        loadContent(for: tab)
    }

    public func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = selectedTabID == id
        tabs.remove(at: index)

        if wasSelected {
            if tabs.isEmpty {
                selectedTabID = nil
                markdownContent = ""
                fileWatcher.stop()
            } else {
                let newIndex = min(index, tabs.count - 1)
                selectTab(tabs[newIndex].id)
            }
        }
    }

    public func selectNextTab() {
        guard let currentID = selectedTabID,
              let index = tabs.firstIndex(where: { $0.id == currentID }),
              tabs.count > 1 else { return }
        let next = (index + 1) % tabs.count
        selectTab(tabs[next].id)
    }

    public func selectPreviousTab() {
        guard let currentID = selectedTabID,
              let index = tabs.firstIndex(where: { $0.id == currentID }),
              tabs.count > 1 else { return }
        let prev = (index - 1 + tabs.count) % tabs.count
        selectTab(tabs[prev].id)
    }

    // MARK: - Open Panel

    public func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.message = "Select Markdown files or a directory"

        if panel.runModal() == .OK {
            for url in panel.urls {
                openURL(url)
            }
        }
    }

    // MARK: - Private

    private func loadContent(for tab: TabItem) {
        do {
            let content = try String(contentsOf: tab.url, encoding: .utf8)
            self.markdownContent = content
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }

        fileWatcher.watch(url: tab.url) { [weak self] in
            self?.reloadCurrentTab()
        }
    }

    private func reloadCurrentTab() {
        guard let tab = selectedTab else { return }
        do {
            let content = try String(contentsOf: tab.url, encoding: .utf8)
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
}
