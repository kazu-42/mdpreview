import SwiftUI

// MARK: - Model

public struct FileTreeNode: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileTreeNode]?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FileTreeNode, rhs: FileTreeNode) -> Bool {
        lhs.id == rhs.id
    }

    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

    /// Maps file extensions to highlight.js language identifiers.
    static let codeExtensionMap: [String: String] = [
        "swift": "swift", "m": "objectivec", "mm": "objectivec",
        "py": "python", "pyw": "python",
        "js": "javascript", "mjs": "javascript", "cjs": "javascript",
        "ts": "typescript",
        "jsx": "javascript", "tsx": "typescript",
        "go": "go",
        "rs": "rust",
        "java": "java", "kt": "kotlin", "kts": "kotlin",
        "rb": "ruby",
        "php": "php",
        "cs": "csharp",
        "cpp": "cpp", "cc": "cpp", "cxx": "cpp",
        "c": "c", "h": "c", "hpp": "cpp",
        "sh": "bash", "bash": "bash", "zsh": "bash", "fish": "bash",
        "json": "json", "jsonc": "json",
        "yaml": "yaml", "yml": "yaml",
        "toml": "ini",
        "xml": "xml", "svg": "xml",
        "html": "html", "htm": "html",
        "css": "css", "scss": "scss", "less": "less",
        "sql": "sql",
        "dockerfile": "dockerfile",
        "tf": "hcl", "hcl": "hcl",
        "graphql": "graphql", "gql": "graphql",
        "vue": "xml", "svelte": "xml",
        "r": "r",
        "lua": "lua",
        "pl": "perl", "pm": "perl",
        "ex": "elixir", "exs": "elixir",
        "erl": "erlang",
        "hs": "haskell",
        "clj": "clojure", "cljs": "clojure",
        "scala": "scala",
        "dart": "dart",
        "txt": "plaintext", "log": "plaintext",
        "conf": "apache", "ini": "ini", "env": "bash",
        "keys": "bash",
        "makefile": "makefile", "mk": "makefile",
        "proto": "protobuf",
        "pem": "plaintext", "crt": "plaintext", "cert": "plaintext",
        "pub": "plaintext",
    ]

    /// Maps extensionless filenames to highlight.js language identifiers.
    static let codeFilenameMap: [String: String] = [
        "makefile": "makefile", "dockerfile": "dockerfile",
        "vagrantfile": "ruby", "gemfile": "ruby", "rakefile": "ruby", "brewfile": "ruby",
        "podfile": "ruby",
        "procfile": "yaml",
        "justfile": "makefile",
        ".env": "bash", ".env.local": "bash", ".env.example": "bash", ".envrc": "bash",
        ".gitignore": "plaintext", ".gitattributes": "plaintext", ".gitmodules": "ini",
        ".dockerignore": "plaintext",
        ".editorconfig": "ini",
        ".htaccess": "apache",
        ".npmrc": "ini", ".yarnrc": "yaml", ".nvmrc": "plaintext",
        ".ruby-version": "plaintext", ".node-version": "plaintext", ".python-version": "plaintext",
        ".tool-versions": "plaintext",
        "license": "plaintext", "licence": "plaintext",
        "readme": "plaintext", "changelog": "plaintext", "authors": "plaintext",
        "contributors": "plaintext", "notice": "plaintext", "copying": "plaintext",
        "todo": "plaintext", "notes": "plaintext",
    ]

    /// Returns the highlight.js language for the given URL, or "markdown" for markdown files.
    public static func language(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        let name = url.lastPathComponent.lowercased()
        if markdownExtensions.contains(ext) { return "markdown" }
        if let lang = codeFilenameMap[name] { return lang }
        if let lang = codeExtensionMap[ext] { return lang }
        return "plaintext"
    }

    /// Returns true if the file can be opened as text in MDPreview.
    /// Returns true if the file can be opened as text in MDPreview.
    /// Algorithm mirrors `content_inspector` (sharkdp/bat):
    ///   1. Extension / filename map  → O(1) fast path
    ///   2. BOM detection             → UTF-16/32 files are text even though they contain NUL
    ///   3. Magic bytes fast-reject   → common binaries (PNG, JPEG, PDF, Mach-O, ELF, ZIP…) skip NUL scan
    ///   4. NUL byte scan             → first 1024 bytes; any 0x00 = binary
    public static func isTextFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        let name = url.lastPathComponent.lowercased()
        if markdownExtensions.contains(ext) { return true }
        if codeExtensionMap[ext] != nil { return true }
        if codeFilenameMap[name] != nil { return true }

        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: 1024)
        guard !data.isEmpty else { return true }

        // Stage 1: BOM — these are text encodings that legitimately contain NUL bytes.
        let boms: [[UInt8]] = [
            [0xEF, 0xBB, 0xBF],             // UTF-8 BOM
            [0x00, 0x00, 0xFE, 0xFF],       // UTF-32 BE  (check before UTF-16 to avoid prefix collision)
            [0xFF, 0xFE, 0x00, 0x00],       // UTF-32 LE
            [0xFE, 0xFF],                   // UTF-16 BE
            [0xFF, 0xFE],                   // UTF-16 LE
        ]
        for bom in boms where data.hasPrefix(bom) { return true }

        // Stage 2: Known binary magic bytes — fast-reject without full NUL scan.
        let magicBinary: [[UInt8]] = [
            [0x89, 0x50, 0x4E, 0x47],       // PNG
            [0xFF, 0xD8, 0xFF],             // JPEG
            [0x47, 0x49, 0x46, 0x38],       // GIF
            [0x25, 0x50, 0x44, 0x46],       // PDF
            [0x50, 0x4B, 0x03, 0x04],       // ZIP (JAR, DOCX, XLSX, …)
            [0x1F, 0x8B],                   // gzip
            [0xFD, 0x37, 0x7A, 0x58],       // xz
            [0x42, 0x5A, 0x68],             // bzip2
            [0x7F, 0x45, 0x4C, 0x46],       // ELF
            [0xCA, 0xFE, 0xBA, 0xBE],       // Mach-O FAT / Java class
            [0xCE, 0xFA, 0xED, 0xFE],       // Mach-O 32-bit LE
            [0xCF, 0xFA, 0xED, 0xFE],       // Mach-O 64-bit LE
            [0xFE, 0xED, 0xFA, 0xCE],       // Mach-O 32-bit BE
            [0xFE, 0xED, 0xFA, 0xCF],       // Mach-O 64-bit BE
            [0x4D, 0x5A],                   // Windows PE (MZ)
            [0x52, 0x61, 0x72, 0x21],       // RAR
            [0x37, 0x7A, 0xBC, 0xAF],       // 7-Zip
            [0x89, 0x48, 0x44, 0x46],       // HDF5
            [0x53, 0x51, 0x4C, 0x69],       // SQLite
        ]
        for magic in magicBinary where data.hasPrefix(magic) { return false }

        // Stage 3: NUL byte scan — the core heuristic (same as git, ripgrep, file command).
        return !data.contains(0)
    }

    // Note: Hidden files/directories (starting with .) are now shown
    // Only skip common large/generated directories
    private static let skippedDirectories: Set<String> = [
        "node_modules", "build", ".build",
        "DerivedData", "Pods", ".next", "dist", "target", "__pycache__",
        ".venv", "venv", ".tox", ".cache",
    ]

    public static func buildTree(from url: URL, showHidden: Bool = true) -> [FileTreeNode] {
        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: options
        ) else { return [] }

        var nodes: [FileTreeNode] = []
        for item in contents {
            let name = item.lastPathComponent
            let values = try? item.resourceValues(forKeys: [.isDirectoryKey])
            let isDir = values?.isDirectory ?? false

            if isDir {
                guard !skippedDirectories.contains(name) else { continue }
                let children = buildTree(from: item, showHidden: showHidden)
                guard !children.isEmpty else { continue }
                nodes.append(FileTreeNode(
                    id: item.path, url: item, name: name,
                    isDirectory: true, children: children
                ))
            } else {
                nodes.append(FileTreeNode(
                    id: item.path, url: item, name: name,
                    isDirectory: false, children: nil
                ))
            }
        }

        return nodes.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
}

// MARK: - Views

public struct FileTreeView: View {
    public let nodes: [FileTreeNode]
    @ObservedObject public var workspace: Workspace

    public init(nodes: [FileTreeNode], workspace: Workspace) {
        self.nodes = nodes
        self.workspace = workspace
    }

    public var body: some View {
        List {
            if let dirURL = workspace.directoryURL {
                Section(dirURL.lastPathComponent) {
                    OutlineGroup(nodes, children: \.children) { node in
                        FileTreeRow(node: node, isSelected: isSelected(node))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .highPriorityGesture(TapGesture().onEnded {
                                guard !node.isDirectory else { return }
                                guard FileTreeNode.isTextFile(node.url) else { return }
                                workspace.openFile(node.url)
                            })
                            .contextMenu {
                                if !node.isDirectory {
                                    Button {
                                        if FileTreeNode.isTextFile(node.url) {
                                            workspace.openFile(node.url)
                                        }
                                    } label: {
                                        Label("Open", systemImage: "arrow.right.circle")
                                    }

                                    Divider()
                                }

                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([node.url])
                                } label: {
                                    Label("Reveal in Finder", systemImage: "folder")
                                }

                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(node.url.path, forType: .string)
                                } label: {
                                    Label("Copy Path", systemImage: "doc.on.doc")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func isSelected(_ node: FileTreeNode) -> Bool {
        guard let selected = workspace.selectedTab else { return false }
        return selected.url.standardizedFileURL == node.url.standardizedFileURL
    }
}

struct FileTreeRow: View {
    let node: FileTreeNode
    let isSelected: Bool

    private var isText: Bool {
        FileTreeNode.isTextFile(node.url)
    }

    private var icon: String {
        node.isDirectory ? "folder.fill" : (isText ? "doc.text" : "doc")
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(isSelected || node.isDirectory ? Color.accentColor : Color.secondary)
                .font(.system(size: 14))
                .frame(width: 16, alignment: .center)
            Text(node.name)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected
                ? RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.08))
                : nil
        )
        .opacity(node.isDirectory || isText ? 1.0 : 0.5)
    }
}

// MARK: - Data helpers

private extension Data {
    func hasPrefix(_ bytes: [UInt8]) -> Bool {
        guard count >= bytes.count else { return false }
        return withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            bytes.enumerated().allSatisfy { i, byte in ptr[i] == byte }
        }
    }
}
