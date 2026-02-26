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

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertNotNil(ws.selectedTab)
        XCTAssertEqual(ws.markdownContent, markdownContent)
        XCTAssertNil(ws.errorMessage)
        XCTAssertTrue(ws.displayName.contains("e2e.md"))
    }

    // MARK: - End-to-end: modify file and verify update via file watcher

    func testModifyFileAndVerifyUpdate() {
        let fileURL = tempDir.appendingPathComponent("live-update.md")
        try! "# Version 1".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)
        XCTAssertEqual(ws.markdownContent, "# Version 1")

        let updated = expectation(description: "content updated via watcher")
        var cancellable: AnyCancellable?
        cancellable = ws.$markdownContent.dropFirst().sink { newValue in
            if newValue == "# Version 2" {
                updated.fulfill()
                cancellable?.cancel()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try! "# Version 2".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(ws.markdownContent, "# Version 2")
    }

    // MARK: - End-to-end: open via path string

    func testOpenViaPathString() {
        let fileURL = tempDir.appendingPathComponent("path-string.md")
        try! "path test".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFromPath(fileURL.path)

        XCTAssertEqual(ws.markdownContent, "path test")
        XCTAssertTrue(ws.displayName.contains("path-string.md"))
    }

    // MARK: - End-to-end: multiple sequential opens as tabs

    func testMultipleSequentialOpens() {
        let file1 = tempDir.appendingPathComponent("first.md")
        let file2 = tempDir.appendingPathComponent("second.md")
        try! "first file".write(to: file1, atomically: true, encoding: .utf8)
        try! "second file".write(to: file2, atomically: true, encoding: .utf8)

        let ws = Workspace()

        ws.openFile(file1)
        XCTAssertEqual(ws.markdownContent, "first file")
        XCTAssertTrue(ws.displayName.contains("first.md"))

        ws.openFile(file2)
        XCTAssertEqual(ws.markdownContent, "second file")
        XCTAssertTrue(ws.displayName.contains("second.md"))

        // Both should be open as tabs
        XCTAssertEqual(ws.tabs.count, 2)

        // Switch back to first
        ws.selectTab(ws.tabs[0].id)
        XCTAssertEqual(ws.markdownContent, "first file")
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

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertEqual(ws.markdownContent, content)
    }

    // MARK: - End-to-end: empty file

    func testEmptyFile() {
        let fileURL = tempDir.appendingPathComponent("empty.md")
        try! "".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertEqual(ws.markdownContent, "")
        XCTAssertNil(ws.errorMessage)
    }

    // MARK: - End-to-end: large file

    func testLargeFile() {
        let fileURL = tempDir.appendingPathComponent("large.md")
        let lines = (1...1000).map { "Line \($0): Some markdown content here." }
        let content = lines.joined(separator: "\n")
        try! content.write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertEqual(ws.markdownContent, content)
        XCTAssertEqual(ws.markdownContent.components(separatedBy: "\n").count, 1000)
    }

    // MARK: - Notification-driven open flow

    func testNotificationDrivenOpenFlow() {
        let fileURL = tempDir.appendingPathComponent("notification.md")
        try! "notification content".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()

        // Simulate what MDPreviewApp does when receiving a notification
        NotificationCenter.default.post(name: .didRequestOpenFile, object: fileURL)

        // In the real app, the notification handler calls workspace.openURL(url)
        ws.openURL(fileURL)

        XCTAssertEqual(ws.markdownContent, "notification content")
    }

    // MARK: - Directory + file opening

    func testOpenDirectoryThenFileFromTree() {
        let dir = tempDir.appendingPathComponent("project")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try! "readme content".write(to: dir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try! "guide content".write(to: dir.appendingPathComponent("guide.md"), atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openDirectory(dir)

        XCTAssertNotNil(ws.directoryURL)
        XCTAssertFalse(ws.fileTreeNodes.isEmpty)

        // Simulate clicking a file in the tree
        ws.openFile(dir.appendingPathComponent("README.md"))
        XCTAssertEqual(ws.markdownContent, "readme content")
        XCTAssertEqual(ws.tabs.count, 1)

        // Open another file
        ws.openFile(dir.appendingPathComponent("guide.md"))
        XCTAssertEqual(ws.markdownContent, "guide content")
        XCTAssertEqual(ws.tabs.count, 2)
    }
}
