import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var workspace: Workspace
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var isDragOver = false
    @State private var eventMonitor: Any?

    public init(workspace: Workspace) {
        self.workspace = workspace
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTreeView(nodes: workspace.fileTreeNodes, workspace: workspace)
                .frame(minWidth: 180)
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
        .onAppear { setupKeyboardShortcuts() }
        .onDisappear { teardownKeyboardShortcuts() }
    }

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

    // MARK: - Keyboard Shortcuts

    private func setupKeyboardShortcuts() {
        let ws = workspace
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Cmd+W: Close current tab, then close window if nothing left
            if flags == .command, event.charactersIgnoringModifiers == "w" {
                if let id = ws.selectedTabID {
                    ws.closeTab(id)
                    if ws.tabs.isEmpty && ws.directoryURL == nil {
                        NSApp.keyWindow?.close()
                    }
                    return nil
                }
                // No tabs open - close the window
                NSApp.keyWindow?.close()
                return nil
            }

            // Cmd+Shift+] or Ctrl+Tab: Next tab
            if (flags == [.command, .shift] && event.charactersIgnoringModifiers == "]") ||
               (flags == .control && event.keyCode == 48) {
                ws.selectNextTab()
                return nil
            }

            // Cmd+Shift+[ or Ctrl+Shift+Tab: Previous tab
            if (flags == [.command, .shift] && event.charactersIgnoringModifiers == "[") ||
               (flags == [.control, .shift] && event.keyCode == 48) {
                ws.selectPreviousTab()
                return nil
            }

            return event
        }
    }

    private func teardownKeyboardShortcuts() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
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
            .padding(.horizontal, 4)
        }
        .frame(height: 30)
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
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(tab.name)
                .font(.system(size: 11))
                .lineLimit(1)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovering ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}
