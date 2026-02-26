import SwiftUI

public struct MDPreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var document = MarkdownDocument()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            ContentView(document: document)
                .onAppear {
                    openFromCommandLineArgs()
                }
                .onReceive(NotificationCenter.default.publisher(for: .didRequestOpenFile)) { notification in
                    if let url = notification.object as? URL {
                        document.open(url: url)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    document.showOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        .defaultSize(width: 800, height: 700)
    }

    private func openFromCommandLineArgs() {
        let args = CommandLine.arguments
        guard args.count > 1 else { return }
        let path = args[1]
        // Skip Xcode-injected arguments
        guard !path.hasPrefix("-") else { return }
        document.open(path: path)
    }
}
