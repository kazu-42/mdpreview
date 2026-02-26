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

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if workspace.tabs.isEmpty {
            EmptyStateView()
        } else if workspace.tabs.count == 1 {
            // Single tab - no tab bar needed
            MarkdownWebView(
                markdownContent: workspace.markdownContent,
                baseURL: workspace.currentFileDirectory
            )
        } else {
            // Multiple tabs - use native TabView
            TabView(selection: $workspace.selectedTabID) {
                ForEach(workspace.tabs) { tab in
                    MarkdownWebView(
                        markdownContent: workspace.markdownContent,
                        baseURL: workspace.currentFileDirectory
                    )
                    .tabItem {
                        Label(tab.name, systemImage: "doc.text")
                    }
                    .tag(tab.id)
                }
            }
            .onChange(of: workspace.selectedTabID) { newID in
                if let id = newID {
                    workspace.selectTab(id)
                }
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
