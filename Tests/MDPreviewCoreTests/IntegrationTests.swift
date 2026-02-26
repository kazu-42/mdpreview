import XCTest
import Combine
@testable import MDPreviewCore

final class IntegrationTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - End-to-end: create, open, verify content

    func testCreateOpenAndVerifyContent() {
        let fileURL = tempDir.appendingPathComponent("e2e.md")
        let markdownContent = """
        # Integration Test

        This is a **bold** statement.

        - Item 1
        - Item 2
        - Item 3

        ```swift
        let x = 42
        ```
        """
        try! markdownContent.write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let loaded = expectation(description: "content loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.fileURL, fileURL)
        XCTAssertEqual(doc.markdownContent, markdownContent)
        XCTAssertNil(doc.errorMessage)
        XCTAssertEqual(doc.displayName, "e2e.md")
    }

    // MARK: - End-to-end: modify file and verify update via file watcher

    func testModifyFileAndVerifyUpdate() {
        let fileURL = tempDir.appendingPathComponent("live-update.md")
        try! "# Version 1".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        // Wait for initial load
        let initialLoad = expectation(description: "initial load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            initialLoad.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(doc.markdownContent, "# Version 1")

        // Now modify the file and wait for the watcher to pick it up
        let updated = expectation(description: "content updated via watcher")
        var cancellable: AnyCancellable?
        cancellable = doc.$markdownContent.dropFirst().sink { newValue in
            if newValue == "# Version 2" {
                updated.fulfill()
                cancellable?.cancel()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try! "# Version 2".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(doc.markdownContent, "# Version 2")
    }

    // MARK: - End-to-end: open via path string

    func testOpenViaPathString() {
        let fileURL = tempDir.appendingPathComponent("path-string.md")
        try! "path test".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(path: fileURL.path)

        let loaded = expectation(description: "loaded via path string")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "path test")
        XCTAssertEqual(doc.displayName, "path-string.md")
    }

    // MARK: - End-to-end: multiple sequential opens

    func testMultipleSequentialOpens() {
        let file1 = tempDir.appendingPathComponent("first.md")
        let file2 = tempDir.appendingPathComponent("second.md")
        try! "first file".write(to: file1, atomically: true, encoding: .utf8)
        try! "second file".write(to: file2, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()

        // Open first file
        doc.open(url: file1)
        let loadFirst = expectation(description: "first file loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadFirst.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(doc.markdownContent, "first file")
        XCTAssertEqual(doc.displayName, "first.md")

        // Open second file (replaces first)
        doc.open(url: file2)
        let loadSecond = expectation(description: "second file loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadSecond.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(doc.markdownContent, "second file")
        XCTAssertEqual(doc.displayName, "second.md")
    }

    // MARK: - End-to-end: Unicode content

    func testUnicodeContent() {
        let fileURL = tempDir.appendingPathComponent("unicode.md")
        let content = """
        # Unicode Test

        Japanese: Swift is great.
        Emoji: Rocket, Star, Heart
        CJK: Zhongwen, Nihongo, Hangugeo
        Math: E = mc^2
        """
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let loaded = expectation(description: "unicode content loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, content)
    }

    // MARK: - End-to-end: empty file

    func testEmptyFile() {
        let fileURL = tempDir.appendingPathComponent("empty.md")
        try! "".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let loaded = expectation(description: "empty file loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "")
        XCTAssertNil(doc.errorMessage)
    }

    // MARK: - End-to-end: large file

    func testLargeFile() {
        let fileURL = tempDir.appendingPathComponent("large.md")
        let lines = (1...1000).map { "Line \($0): Some markdown content here." }
        let content = lines.joined(separator: "\n")
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let loaded = expectation(description: "large file loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 3.0)

        XCTAssertEqual(doc.markdownContent, content)
        XCTAssertEqual(doc.markdownContent.components(separatedBy: "\n").count, 1000)
    }

    // MARK: - Notification-driven open flow

    func testNotificationDrivenOpenFlow() {
        let fileURL = tempDir.appendingPathComponent("notification.md")
        try! "notification content".write(to: fileURL, atomically: true, encoding: .utf8)

        // Simulate what MDPreviewApp does when receiving a notification
        let doc = MarkdownDocument()

        // Post the notification (as AppDelegate would)
        NotificationCenter.default.post(name: .didRequestOpenFile, object: fileURL)

        // In the real app, the notification handler calls doc.open(url:)
        // Here we simulate it directly
        doc.open(url: fileURL)

        let loaded = expectation(description: "notification flow loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "notification content")
    }
}
