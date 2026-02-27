import AppKit

public extension Notification.Name {
    static let didRequestOpenFile = Notification.Name("didRequestOpenFile")
    static let closeCurrentTab = Notification.Name("closeCurrentTab")
    static let closeAllTabs = Notification.Name("closeAllTabs")
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        installCloseTabKeyHandler()
    }

    // Intercept Cmd+W and Cmd+Opt+W before the menu system sees them.
    // SwiftUI drops our "Close Tab" shortcut because WindowGroup auto-registers
    // a competing system Close (⌘W), leaving Close Tab with no effective shortcut.
    private func installCloseTabKeyHandler() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard event.charactersIgnoringModifiers == "w" else { return event }
            if flags == [.command, .option] {
                NotificationCenter.default.post(name: .closeAllTabs, object: nil)
                return nil
            }
            if flags == .command {
                NotificationCenter.default.post(name: .closeCurrentTab, object: nil)
                return nil
            }
            return event
        }
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            NotificationCenter.default.post(name: .didRequestOpenFile, object: url)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            return true
        }
        NSApp.activate(ignoringOtherApps: true)
        return false
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
