import Foundation

/// Application-wide logger for debugging
public final class AppLogger {
    public static let shared = AppLogger()

    private let logFileURL: URL
    private let queue = DispatchQueue(label: "com.mdpreview.logger")
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Path to the log file for display in UI
    public var logPath: String { logFileURL.path }

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let logsDir = cachesDir.appendingPathComponent("MDPreview/Logs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        logFileURL = logsDir.appendingPathComponent("mdpreview.log")

        // Log session start
        log("=== MDPreview Session Started ===")
        log("Log file: \(logFileURL.path)")
        log("Bundle path: \(Bundle.main.bundlePath)")
        log("Bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
    }

    /// Log a message with timestamp
    public func log(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)\n"

        queue.async {
            guard let data = entry.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: self.logFileURL)
            }
        }

        // Also print to console for debugging in Xcode
        print("[MDPreview] \(message)")
    }

    /// Get all logs as a string
    public func getLogs() -> String {
        (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? ""
    }

    /// Export logs to a user-specified location
    public func exportLogs(to url: URL) throws {
        try FileManager.default.copyItem(at: logFileURL, to: url)
    }

    /// Clear the log file
    public func clearLogs() {
        queue.async {
            try? FileManager.default.removeItem(at: self.logFileURL)
        }
        log("Logs cleared")
    }
}
