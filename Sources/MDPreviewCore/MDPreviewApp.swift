import SwiftUI
import UniformTypeIdentifiers

public struct MDPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workspace = Workspace()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainView(workspace: workspace)
                .frame(minWidth: 500, minHeight: 400)
                .background(Color(nsColor: .textBackgroundColor))
                .onAppear {
                    openFromCommandLineArgs()
                    restoreStateIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: .didRequestOpenFile)) { notification in
                    if let url = notification.object as? URL {
                        workspace.openURL(url)
                    }
                }
        }
        .commands {
            // MARK: - File Menu
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    workspace.showOpenPanel()
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

            // MARK: - View Menu (extend default View menu)
            CommandGroup(after: .toolbar) {
                Button("Toggle Sidebar") {
                    workspace.toggleSidebar()
                }
                .keyboardShortcut("s", modifiers: [.command, .control])

                Button("Toggle Table of Contents") {
                    NotificationCenter.default.post(name: .toggleTOC, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .control])

                Divider()

                Toggle("Show Hidden Files", isOn: $workspace.showHiddenFiles)
                    .keyboardShortcut(".", modifiers: [.command, .shift])
            }

            // MARK: - Window Menu
            CommandGroup(replacing: .windowArrangement) {
                Button("Close Tab") {
                    workspace.closeCurrentTab()
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Close All Tabs") {
                    workspace.closeAllTabs()
                }
                .keyboardShortcut("w", modifiers: [.command, .option])

                Divider()

                Button("Next Tab") {
                    workspace.selectNextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Previous Tab") {
                    workspace.selectPreviousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Divider()

                // Cmd+1 through Cmd+9 for tab access
                ForEach(1...9, id: \.self) { index in
                    Button("Tab \(index)") {
                        workspace.selectTab(at: index - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
                }
            }

            // MARK: - Help Menu
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
        .defaultSize(width: 900, height: 700)
    }

    private func openFromCommandLineArgs() {
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            guard !arg.hasPrefix("-") else { continue }
            workspace.openFromPath(arg)
        }
    }

    private func restoreStateIfNeeded() {
        // Only restore if no files were opened via CLI
        if workspace.tabs.isEmpty {
            workspace.restoreState()
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
                workspace.errorMessage = "Failed to export logs: \(error.localizedDescription)"
            }
        }
    }
}
