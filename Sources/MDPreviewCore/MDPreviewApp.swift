import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - First Window Initialization State

private final class AppInitState {
    static let shared = AppInitState()
    private(set) var firstWindowInitialized = false

    func markFirstWindowInitialized() {
        firstWindowInitialized = true
    }
}

// MARK: - App Entry Point

public struct MDPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    public init() {}

    public var body: some Scene {
        WindowGroup(id: "main") {
            WindowRoot()
        }
        .commands {
            AppCommands()
        }
        .defaultSize(width: 900, height: 700)
    }
}

// MARK: - Per-Window Root View

private struct WindowRoot: View {
    @StateObject private var workspace = Workspace()
    @State private var hostWindow: NSWindow?

    var body: some View {
        MainView(workspace: workspace)
            .frame(minWidth: 500, minHeight: 400)
            .background(Color(nsColor: .textBackgroundColor))
            .background(WindowAccessor(window: $hostWindow))
            .focusedObject(workspace)
            .onAppear {
                initializeIfFirstWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didRequestOpenFile)) { notification in
                guard hostWindow?.isKeyWindow == true,
                      let url = notification.object as? URL else { return }
                workspace.openURL(url)
            }
    }

    private func initializeIfFirstWindow() {
        guard !AppInitState.shared.firstWindowInitialized else { return }
        AppInitState.shared.markFirstWindowInitialized()
        workspace.persistsState = true
        openFromCommandLineArgs()
        restoreStateIfNeeded()
    }

    private func openFromCommandLineArgs() {
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            guard !arg.hasPrefix("-") else { continue }
            workspace.openFromPath(arg)
        }
    }

    private func restoreStateIfNeeded() {
        if workspace.tabs.isEmpty {
            workspace.restoreState()
        }
    }
}

// MARK: - NSWindow Accessor

private struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if window == nil {
            DispatchQueue.main.async {
                self.window = nsView.window
            }
        }
    }
}

// MARK: - Commands

private struct AppCommands: Commands {
    @FocusedObject private var workspace: Workspace?
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // MARK: File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: .command)

            Divider()

            Button("Open...") {
                workspace?.showOpenPanel()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Button("Export Logs...") {
                exportLogs()
            }
        }

        CommandGroup(after: .appSettings) {
            Button("Install Command Line Tool...") {
                CLIInstaller.install()
            }
        }

        // MARK: View Menu
        CommandGroup(after: .toolbar) {
            Button("Toggle Sidebar") {
                workspace?.toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])

            Button("Toggle Table of Contents") {
                NotificationCenter.default.post(name: .toggleTOC, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .control])

            Divider()

            Toggle("Show Hidden Files", isOn: Binding(
                get: { workspace?.showHiddenFiles ?? true },
                set: { workspace?.showHiddenFiles = $0 }
            ))
            .keyboardShortcut(".", modifiers: [.command, .shift])
        }

        // MARK: Window Menu
        CommandGroup(replacing: .windowArrangement) {
            Button("Close Tab") {
                if let ws = workspace, !ws.tabs.isEmpty {
                    ws.closeCurrentTab()
                } else {
                    NSApp.keyWindow?.close()
                }
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Close All Tabs") {
                workspace?.closeAllTabs()
            }
            .keyboardShortcut("w", modifiers: [.command, .option])

            Divider()

            Button("Next Tab") {
                workspace?.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button("Previous Tab") {
                workspace?.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])

            Divider()

            ForEach(1...9, id: \.self) { index in
                Button("Tab \(index)") {
                    workspace?.selectTab(at: index - 1)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
            }
        }

        // MARK: Help Menu
        CommandGroup(replacing: .help) {
            Button("MDPreview Website") {
                if let url = URL(string: "https://github.com/kazu-42/mdpreview") {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Report an Issue") {
                if let url = URL(string: "https://github.com/kazu-42/mdpreview/issues") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func exportLogs() {
        let panel = NSSavePanel()
        panel.title = "Export Logs"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        panel.nameFieldStringValue = "mdpreview-\(formatter.string(from: Date())).log"
        panel.allowedContentTypes = [UTType(filenameExtension: "log") ?? .plainText]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try AppLogger.shared.exportLogs(to: url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to export logs"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}
