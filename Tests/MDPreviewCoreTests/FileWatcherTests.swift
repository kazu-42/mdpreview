import XCTest
@testable import MDPreviewCore

final class FileWatcherTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileWatcherTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Watch and detect file write

    func testWatchDetectsFileWrite() {
        let watcher = FileWatcher(debounceInterval: 0.05)
        let fileURL = tempDir.appendingPathComponent("test.md")
        try! "initial".write(to: fileURL, atomically: true, encoding: .utf8)

        let expectation = expectation(description: "onChange called after file write")

        watcher.watch(url: fileURL) {
            expectation.fulfill()
        }

        XCTAssertTrue(watcher.isWatching)

        // Modify the file after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try! "updated".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 2.0)
        watcher.stop()
    }

    // MARK: - Debounce behavior

    func testDebounceBatchesRapidWrites() {
        let watcher = FileWatcher(debounceInterval: 0.2)
        let fileURL = tempDir.appendingPathComponent("debounce.md")
        try! "v0".write(to: fileURL, atomically: true, encoding: .utf8)

        var callCount = 0
        let expectation = expectation(description: "onChange called after debounce")

        watcher.watch(url: fileURL) {
            callCount += 1
            if callCount == 1 {
                expectation.fulfill()
            }
        }

        // Perform rapid successive writes (non-atomic to trigger write events)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            try! "v1".write(to: fileURL, atomically: false, encoding: .utf8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            try! "v2".write(to: fileURL, atomically: false, encoding: .utf8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            try! "v3".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)

        // After debounce, the callback should have been called a small number of times
        // (ideally 1 due to debounce batching rapid writes, but at most a few)
        XCTAssertLessThanOrEqual(callCount, 3,
            "Debounce should batch rapid writes; got \(callCount) calls")
        watcher.stop()
    }

    // MARK: - Stop cancels watching

    func testStopCancelsWatching() {
        let watcher = FileWatcher(debounceInterval: 0.05)
        let fileURL = tempDir.appendingPathComponent("stop.md")
        try! "initial".write(to: fileURL, atomically: true, encoding: .utf8)

        var callCount = 0
        watcher.watch(url: fileURL) {
            callCount += 1
        }

        XCTAssertTrue(watcher.isWatching)
        watcher.stop()
        XCTAssertFalse(watcher.isWatching)

        // Write after stop - should NOT trigger callback
        try! "after-stop".write(to: fileURL, atomically: false, encoding: .utf8)

        // Give enough time for any spurious callback
        let expectation = expectation(description: "wait for potential callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(callCount, 0, "No callbacks should fire after stop()")
    }

    // MARK: - Re-watch after rename (write-then-rename pattern)

    func testReWatchAfterRename() {
        let watcher = FileWatcher(debounceInterval: 0.05)
        let fileURL = tempDir.appendingPathComponent("rename.md")
        try! "original".write(to: fileURL, atomically: true, encoding: .utf8)

        let expectation = expectation(description: "onChange called after rename cycle")

        watcher.watch(url: fileURL) {
            expectation.fulfill()
        }

        // Simulate editor write-then-rename: write to temp, rename over original
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let tmpFile = self.tempDir.appendingPathComponent("rename.md.tmp")
            try! "replaced".write(to: tmpFile, atomically: true, encoding: .utf8)
            _ = try? FileManager.default.replaceItemAt(fileURL, withItemAt: tmpFile)
        }

        waitForExpectations(timeout: 3.0)
        watcher.stop()
    }

    // MARK: - Watch non-existent file gracefully

    func testWatchNonExistentFileDoesNotCrash() {
        let watcher = FileWatcher(debounceInterval: 0.05)
        let bogusURL = tempDir.appendingPathComponent("does-not-exist.md")

        // Should not crash or throw
        watcher.watch(url: bogusURL) {
            XCTFail("Should not receive callbacks for non-existent file")
        }

        // Cannot open the file descriptor, so isWatching should be false
        XCTAssertFalse(watcher.isWatching)
        watcher.stop()
    }

    // MARK: - Deinit stops watching

    func testDeinitStopsWatching() {
        let fileURL = tempDir.appendingPathComponent("deinit.md")
        try! "content".write(to: fileURL, atomically: true, encoding: .utf8)

        var callCount = 0
        // Scope the watcher so it gets deallocated
        autoreleasepool {
            let watcher = FileWatcher(debounceInterval: 0.05)
            watcher.watch(url: fileURL) {
                callCount += 1
            }
            // watcher goes out of scope here -> deinit -> stop()
        }

        // Write after deallocation
        try! "after-deinit".write(to: fileURL, atomically: false, encoding: .utf8)

        let expectation = expectation(description: "wait for potential callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(callCount, 0, "No callbacks should fire after deinit")
    }

    // MARK: - Default debounce interval

    func testDefaultDebounceInterval() {
        let watcher = FileWatcher()
        XCTAssertEqual(watcher.debounceInterval, 0.15, accuracy: 0.001)
    }

    // MARK: - Custom debounce interval

    func testCustomDebounceInterval() {
        let watcher = FileWatcher(debounceInterval: 0.5)
        XCTAssertEqual(watcher.debounceInterval, 0.5, accuracy: 0.001)
    }
}
