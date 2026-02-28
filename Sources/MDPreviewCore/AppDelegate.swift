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
        installMenuShortcutFixer()
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

    // SwiftUI cannot show ⌘W on "Close Tab" because the system Close item
    // already occupies that shortcut. We patch the NSMenuItems directly and
    // reapply whenever the menu changes (SwiftUI rebuilds on workspace state changes).
    private func installMenuShortcutFixer() {
        DispatchQueue.main.async { self.applyCloseTabShortcutHints() }
        NotificationCenter.default.addObserver(
            forName: NSMenu.didChangeItemNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyCloseTabShortcutHints()
        }
    }

    private var isApplyingShortcutHints = false

    private func applyCloseTabShortcutHints() {
        guard !isApplyingShortcutHints else { return }
        isApplyingShortcutHints = true
        defer { isApplyingShortcutHints = false }

        guard let windowMenu = NSApp.mainMenu?.item(withTitle: "Window")?.submenu else { return }
        for item in windowMenu.items {
            switch item.title {
            case "Close Tab":
                if item.keyEquivalent != "w" {
                    item.keyEquivalent = "w"
                    item.keyEquivalentModifierMask = .command
                }
            case "Close All Tabs":
                if item.keyEquivalent != "w" {
                    item.keyEquivalent = "w"
                    item.keyEquivalentModifierMask = [.command, .option]
                }
            default:
                break
            }
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
