import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var workspace: Workspace
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var isDragOver = false
    @State private var showTOC = true

    public init(workspace: Workspace) {
        self.workspace = workspace
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTreeView(nodes: workspace.fileTreeNodes, workspace: workspace)
                .frame(minWidth: 180, idealWidth: workspace.sidebarWidth)
                .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
                    withAnimation {
                        if columnVisibility == .all {
                            columnVisibility = .detailOnly
                        } else {
                            columnVisibility = .all
                        }
                    }
                }
        } detail: {
            HStack(spacing: 0) {
                // Main content
                VStack(spacing: 0) {
                    if workspace.tabs.count > 1 {
                        TabBarView(workspace: workspace)
                    }

                    if workspace.selectedTab != nil {
                        MarkdownWebView(
                            markdownContent: workspace.markdownContent,
                            baseURL: workspace.currentFileDirectory
                        )
                    } else {
                        EmptyStateView()
                    }
                }

                // Table of Contents sidebar
                if showTOC && !workspace.tocItems.isEmpty {
                    TOCSidebarView(items: workspace.tocItems)
                        .frame(width: 250)
                        .background(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
        .navigationTitle(workspace.displayName)
        .onChange(of: workspace.directoryURL) { newValue in
            withAnimation {
                columnVisibility = newValue != nil ? .all : .detailOnly
            }
        }
        .overlay(dragOverlay)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: $workspace.showError) {
            Button("OK") {
                workspace.errorMessage = nil
            }
        } message: {
            Text(workspace.errorMessage ?? "An unknown error occurred")
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation {
                        showTOC.toggle()
                    }
                } label: {
                    Image(systemName: showTOC ? "list.bullet.rectangle" : "list.bullet.rectangle")
                }
                .help("Toggle Table of Contents")
            }
        }
    }

    // MARK: - Drag and Drop

    @ViewBuilder
    private var dragOverlay: some View {
        if isDragOver {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                .background(Color.accentColor.opacity(0.08))
                .padding(8)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    workspace.openURL(url)
                }
            }
        }
        return true
    }
}

// MARK: - Empty State

public struct EmptyStateView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.secondary)
            Text("Drop a Markdown file here")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("or press Cmd+O to open")
                .font(.callout)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Bar

struct TabBarView: View {
    @ObservedObject var workspace: Workspace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(workspace.tabs) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: tab.id == workspace.selectedTabID,
                        onSelect: { workspace.selectTab(tab.id) },
                        onClose: { workspace.closeTab(tab.id) }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: 32)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .accentColor : .secondary)

            Text(tab.name)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovering ? 1 : 0.4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovering ? Color(nsColor: .controlBackgroundColor) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Table of Contents

public struct TOCItem: Identifiable {
    public let id = UUID()
    public let level: Int
    public let title: String
    public let anchor: String

    public init(level: Int, title: String, anchor: String) {
        self.level = level
        self.title = title
        self.anchor = anchor
    }
}

struct TOCSidebarView: View {
    let items: [TOCItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Table of Contents")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(items) { item in
                        TOCItemView(item: item)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct TOCItemView: View {
    let item: TOCItem
    @State private var isHovering = false

    var body: some View {
        Button {
            // Scroll to anchor - would need to communicate with WebView
            NotificationCenter.default.post(
                name: .scrollToAnchor,
                object: item.anchor
            )
        } label: {
            HStack(spacing: 0) {
                // Indentation based on level
                ForEach(0..<item.level, id: \.self) { _ in
                    Text("  ")
                }

                Text(item.title)
                    .font(.system(size: 11))
                    .foregroundColor(isHovering ? .accentColor : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let scrollToAnchor = Notification.Name("com.mdpreview.scrollToAnchor")
}
