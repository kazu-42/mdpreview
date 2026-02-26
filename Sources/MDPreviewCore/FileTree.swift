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

    // Note: Hidden files/directories (starting with .) are now shown
    // Only skip common large/generated directories
    private static let skippedDirectories: Set<String> = [
        "node_modules", "build", ".build",
        "DerivedData", "Pods", ".next", "dist", "target", "__pycache__",
        ".venv", "venv", ".tox", ".cache",
    ]

    public static func buildTree(from url: URL) -> [FileTreeNode] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []  // Show hidden files too
        ) else { return [] }

        var nodes: [FileTreeNode] = []
        for item in contents {
            let name = item.lastPathComponent
            let values = try? item.resourceValues(forKeys: [.isDirectoryKey])
            let isDir = values?.isDirectory ?? false

            if isDir {
                guard !skippedDirectories.contains(name) else { continue }
                let children = buildTree(from: item)
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !node.isDirectory else { return }
                                let ext = node.url.pathExtension.lowercased()
                                guard FileTreeNode.markdownExtensions.contains(ext) else { return }
                                workspace.openFile(node.url)
                            }
                            .contextMenu {
                                if !node.isDirectory {
                                    Button {
                                        let ext = node.url.pathExtension.lowercased()
                                        if FileTreeNode.markdownExtensions.contains(ext) {
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

    private var isMarkdown: Bool {
        FileTreeNode.markdownExtensions.contains(node.url.pathExtension.lowercased())
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: node.isDirectory ? "folder.fill" : (isMarkdown ? "doc.text" : "doc"))
                .foregroundColor(node.isDirectory ? .accentColor : .secondary)
                .font(.system(size: 13))
            Text(node.name)
                .font(.system(size: 13))
                .foregroundColor(node.isDirectory || isMarkdown ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 1)
        .opacity(node.isDirectory || isMarkdown ? 1.0 : 0.6)
    }
}
