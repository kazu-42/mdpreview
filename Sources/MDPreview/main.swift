import AppKit
import MDPreviewCore

// Required for SPM-built SwiftUI apps to show windows and appear in dock
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

MDPreviewApp.main()
