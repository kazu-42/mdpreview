import AppKit

public enum CLIInstaller {
    public static let destination = "/usr/local/bin/mdpreview"

    public static var bundledCLIPath: String? {
        Bundle.main.path(forResource: "mdpreview", ofType: nil)
    }

    public static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: destination)
    }

    public static func install() {
        guard let source = bundledCLIPath else {
            showAlert(
                title: "Error",
                message: "CLI tool not found in app bundle. Please reinstall MDPreview."
            )
            return
        }

        let script = """
        do shell script "mkdir -p /usr/local/bin && ln -sf '\(source)' '\(destination)'" \
        with administrator privileges
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        if error != nil {
            return  // User cancelled the auth dialog
        }

        showAlert(
            title: "Command Line Tool Installed",
            message: "You can now use 'mdpreview' from the terminal.\n\nUsage:\n  mdpreview file.md\n  mdpreview ~/projects/"
        )
    }

    private static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
