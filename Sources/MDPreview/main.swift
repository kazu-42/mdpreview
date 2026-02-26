import AppKit
import MDPreviewCore

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

MDPreviewApp.main()
