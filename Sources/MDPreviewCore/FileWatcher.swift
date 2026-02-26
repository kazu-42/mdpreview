import Foundation

public final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceTimer: DispatchSourceTimer?
    public let debounceInterval: TimeInterval

    public init(debounceInterval: TimeInterval = 0.15) {
        self.debounceInterval = debounceInterval
    }

    public func watch(url: URL, onChange: @escaping () -> Void) {
        stop()

        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                // File was replaced (editors often write-then-rename)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.watch(url: url, onChange: onChange)
                    self.debouncedOnChange(onChange)
                }
                return
            }
            self.debouncedOnChange(onChange)
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        self.source = source
        source.resume()
    }

    public var isWatching: Bool {
        source != nil
    }

    public func stop() {
        debounceTimer?.cancel()
        debounceTimer = nil
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    private func debouncedOnChange(_ onChange: @escaping () -> Void) {
        debounceTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + debounceInterval)
        timer.setEventHandler {
            onChange()
        }
        debounceTimer = timer
        timer.resume()
    }

    deinit {
        stop()
    }
}
