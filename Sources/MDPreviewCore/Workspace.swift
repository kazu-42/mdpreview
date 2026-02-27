import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct TabItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL

    public var name: String { url.lastPathComponent }
    public var directoryURL: URL { url.deletingLastPathComponent() }

    public static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

public final class Workspace: ObservableObject {
    // MARK: - Configuration

    /// When true, this workspace saves and restores session state (open files/directories).
    /// Only the first window's workspace should have this set to true.
    public var persistsState = false

    // MARK: - Published State

    @Published public var tabs: [TabItem] = []
    @Published public var selectedTabID: UUID?
    @Published public var directoryURL: URL?
    @Published public var fileTreeNodes: [FileTreeNode] = []
    @Published public var markdownContent: String = "" {
        didSet {
            tocItems = extractTOC(from: markdownContent)
        }
    }
    @Published public var tocItems: [TOCItem] = []
    @Published public var errorMessage: String?

    // Persisted state
    @AppStorage("sidebarWidth") public var sidebarWidth: Double = 200
    @AppStorage("lastOpenedFiles") private var lastOpenedFilesData: Data = Data()
    @AppStorage("lastDirectory") private var lastDirectoryPath: String = ""
    @AppStorage("showHiddenFiles") private var storedShowHiddenFiles: Bool = true
    @AppStorage("customCSSPath") private var storedCustomCSSPath: String = ""

    /// Whether to show hidden files in the file tree
    @Published public var showHiddenFiles: Bool = true {
        didSet { refreshFileTree() }
    }

    /// Custom CSS content loaded from customCSSPath
    @Published public var customCSS: String = ""

    /// Path to the current custom CSS file (read-only; use setCustomCSSPath to change)
    public var customCSSPath: String { storedCustomCSSPath }

    private let cssWatcher = FileWatcher()

    /// Computed property for showing error alerts
    public var showError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    /// Current file's directory for resolving relative image paths
    public var currentFileDirectory: URL? {
        selectedTab?.directoryURL ?? directoryURL
    }

    private let fileWatcher = FileWatcher()

    public init() {
        showHiddenFiles = storedShowHiddenFiles
        if !storedCustomCSSPath.isEmpty {
            loadCustomCSSFromPath(storedCustomCSSPath)
        }
    }

    // MARK: - Computed Properties

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

        // Check if file is readable
        guard FileManager.default.isReadableFile(atPath: standardized.path) else {
            errorMessage = "Cannot read file: \(standardized.lastPathComponent)"
            return
        }

        if let existing = tabs.first(where: { $0.url.standardizedFileURL == standardized }) {
            selectTab(existing.id)
            return
        }
        let tab = TabItem(url: standardized)
        tabs.append(tab)
        selectTab(tab.id)
        saveState()
    }

    public func openDirectory(_ url: URL) {
        directoryURL = url.standardizedFileURL
        fileTreeNodes = FileTreeNode.buildTree(from: url, showHidden: showHiddenFiles)
        lastDirectoryPath = url.path
    }

    public func openURL(_ url: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            errorMessage = "File not found: \(url.lastPathComponent)"
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

    public func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        selectTab(tabs[index].id)
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
        saveState()
    }

    public func closeCurrentTab() {
        guard let id = selectedTabID else {
            // No tabs, close window
            NSApp.keyWindow?.close()
            return
        }
        closeTab(id)
        if tabs.isEmpty && directoryURL == nil {
            NSApp.keyWindow?.close()
        }
    }

    public func closeAllTabs() {
        tabs.removeAll()
        selectedTabID = nil
        markdownContent = ""
        fileWatcher.stop()
        saveState()
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

    public func toggleSidebar() {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    public func toggleHiddenFiles() {
        showHiddenFiles.toggle()
        storedShowHiddenFiles = showHiddenFiles
    }

    /// Set a new custom CSS file path and reload the CSS content.
    /// Pass empty string to remove the custom stylesheet.
    public func setCustomCSSPath(_ path: String) {
        storedCustomCSSPath = path
        cssWatcher.stop()
        if path.isEmpty {
            customCSS = ""
            return
        }
        loadCustomCSSFromPath(path)
    }

    public func refreshFileTree() {
        guard let dir = directoryURL else { return }
        fileTreeNodes = FileTreeNode.buildTree(from: dir, showHidden: showHiddenFiles)
    }

    // MARK: - State Persistence

    public func saveState() {
        guard persistsState else { return }
        // Save open file paths
        let paths = tabs.map { $0.url.path }
        if let data = try? JSONEncoder().encode(paths) {
            lastOpenedFilesData = data
        }
    }

    public func restoreState() {
        guard persistsState else { return }
        // Restore last directory
        if !lastDirectoryPath.isEmpty {
            let url = URL(fileURLWithPath: lastDirectoryPath)
            if FileManager.default.fileExists(atPath: url.path) {
                openDirectory(url)
            }
        }

        // Restore open files
        if let paths = try? JSONDecoder().decode([String].self, from: lastOpenedFilesData) {
            for path in paths {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    openFile(url)
                }
            }
        }
    }

    // MARK: - Open Panel

    public func showOpenPanel() {
        let panel = NSOpenPanel()
        let mdTypes: [UTType] = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown")
        ].compactMap { $0 }

        panel.allowedContentTypes = mdTypes.isEmpty ? [.plainText] : mdTypes + [.plainText]
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
        // Check file size for async loading
        let fileSize: Int64
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: tab.url.path)
            fileSize = (attributes[.size] as? Int64) ?? 0
        } catch {
            fileSize = 0
        }

        // Load large files asynchronously
        if fileSize > 1_000_000 { // > 1MB
            let expectedTabID = tab.id
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let content = try String(contentsOf: tab.url, encoding: .utf8)
                    DispatchQueue.main.async {
                        // Only update if still on the same tab (avoid race condition)
                        guard self?.selectedTabID == expectedTabID else { return }
                        self?.markdownContent = content
                        self?.errorMessage = nil
                    }
                } catch {
                    DispatchQueue.main.async {
                        guard self?.selectedTabID == expectedTabID else { return }
                        self?.errorMessage = "Failed to load \(tab.name): \(error.localizedDescription)"
                    }
                }
            }
        } else {
            do {
                let content = try String(contentsOf: tab.url, encoding: .utf8)
                self.markdownContent = content
                self.errorMessage = nil
            } catch {
                self.errorMessage = "Failed to load \(tab.name): \(error.localizedDescription)"
            }
        }

        fileWatcher.watch(url: tab.url) { [weak self] in
            self?.reloadCurrentTab()
        }
    }

    private func loadCustomCSSFromPath(_ path: String) {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.isReadableFile(atPath: url.path),
              let css = try? String(contentsOf: url, encoding: .utf8) else { return }
        customCSS = css
        cssWatcher.watch(url: url) { [weak self] in
            self?.reloadCustomCSS()
        }
    }

    private func reloadCustomCSS() {
        guard !storedCustomCSSPath.isEmpty else { return }
        let url = URL(fileURLWithPath: storedCustomCSSPath)
        guard let css = try? String(contentsOf: url, encoding: .utf8) else { return }
        DispatchQueue.main.async { self.customCSS = css }
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
                self.errorMessage = "Failed to reload: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - TOC Extraction

    private func extractTOC(from markdown: String) -> [TOCItem] {
        var items: [TOCItem] = []
        let lines = markdown.components(separatedBy: .newlines)
        var inCodeBlock = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track fenced code blocks
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock = !inCodeBlock
                continue
            }

            guard !inCodeBlock else { continue }

            // Match headings: # ## ### etc.
            if trimmed.hasPrefix("#") {
                let hashCount = trimmed.prefix(while: { $0 == "#" }).count
                if hashCount >= 1 && hashCount <= 6 {
                    let title = trimmed
                        .dropFirst(hashCount)
                        .trimmingCharacters(in: .whitespaces)

                    guard !title.isEmpty else { continue }

                    // Create anchor (simple slug)
                    let anchor = title
                        .lowercased()
                        .replacingOccurrences(of: "[^a-z0-9\\-\\s]", with: "", options: .regularExpression)
                        .replacingOccurrences(of: " ", with: "-")

                    items.append(TOCItem(level: hashCount, title: title, anchor: anchor))
                }
            }
        }

        return items
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let toggleSidebar = Notification.Name("com.mdpreview.toggleSidebar")
    public static let toggleTOC = Notification.Name("com.mdpreview.toggleTOC")
}
