import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var workspace: Workspace
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var isDragOver = false

    public init(workspace: Workspace) {
        self.workspace = workspace
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTreeView(nodes: workspace.fileTreeNodes, workspace: workspace)
                .frame(minWidth: sidebarWidth)
        } detail: {
            contentArea
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
    }

    // MARK: - Constants

    private let sidebarWidth: CGFloat = 200

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        VStack(spacing: 0) {
            if workspace.tabs.count > 1 {
                TabBarView(workspace: workspace)
            }

            if workspace.selectedTab != nil {
                MarkdownWebView(markdownContent: workspace.markdownContent)
            } else {
                EmptyStateView()
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
        VStack(spacing: emptyStateSpacing) {
            Image(systemName: "doc.text")
                .font(.system(size: emptyStateIconSize, weight: .thin))
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

    private let emptyStateSpacing: CGFloat = 16
    private let emptyStateIconSize: CGFloat = 48
}

// MARK: - Tab Bar

struct TabBarView: View {
    @ObservedObject var workspace: Workspace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(workspace.tabs) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: tab.id == workspace.selectedTabID,
                        onSelect: { workspace.selectTab(tab.id) },
                        onClose: { workspace.closeTab(tab.id) }
                    )
                }
            }
            .padding(.horizontal, tabBarPadding)
        }
        .frame(height: tabBarHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private let tabBarHeight: CGFloat = 30
    private let tabBarPadding: CGFloat = 4
}

struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: tabBarItemSpacing) {
            Image(systemName: "doc.text")
                .font(.system(size: tabIconSize))
                .foregroundColor(.secondary)
            Text(tab.name)
                .font(.system(size: tabTextSize))
                .lineLimit(1)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: tabCloseIconSize, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovering ? 1 : 0)
        }
        .padding(.horizontal, tabBarItemPaddingH)
        .padding(.vertical, tabBarItemPaddingV)
        .background(
            RoundedRectangle(cornerRadius: tabBarItemCornerRadius)
                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }

    private let tabBarItemSpacing: CGFloat = 4
    private let tabIconSize: CGFloat = 10
    private let tabTextSize: CGFloat = 11
    private let tabCloseIconSize: CGFloat = 8
    private let tabBarItemPaddingH: CGFloat = 10
    private let tabBarItemPaddingV: CGFloat = 5
    private let tabBarItemCornerRadius: CGFloat = 6
}
