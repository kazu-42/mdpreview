import SwiftUI

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
                }
                .onReceive(NotificationCenter.default.publisher(for: .didRequestOpenFile)) { notification in
                    if let url = notification.object as? URL {
                        workspace.openURL(url)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    workspace.showOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .appSettings) {
                Button("Install Command Line Tool...") {
                    CLIInstaller.install()
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
}
