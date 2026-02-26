import XCTest
@testable import MDPreviewCore

final class WorkspaceTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Open file

    func testOpenFileAddsTab() {
        let fileURL = tempDir.appendingPathComponent("test.md")
        try! "# Hello".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertEqual(ws.tabs.count, 1)
        XCTAssertEqual(ws.selectedTab?.url, fileURL.standardizedFileURL)
        XCTAssertEqual(ws.markdownContent, "# Hello")
    }

    func testOpenSameFileDoesNotDuplicate() {
        let fileURL = tempDir.appendingPathComponent("test.md")
        try! "content".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)
        ws.openFile(fileURL)

        XCTAssertEqual(ws.tabs.count, 1)
    }

    func testOpenMultipleFiles() {
        let file1 = tempDir.appendingPathComponent("a.md")
        let file2 = tempDir.appendingPathComponent("b.md")
        try! "content A".write(to: file1, atomically: true, encoding: .utf8)
        try! "content B".write(to: file2, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(file1)
        ws.openFile(file2)

        XCTAssertEqual(ws.tabs.count, 2)
        XCTAssertEqual(ws.markdownContent, "content B")
    }

    // MARK: - Open via path

    func testOpenFromAbsolutePath() {
        let fileURL = tempDir.appendingPathComponent("absolute.md")
        try! "# Hello".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFromPath(fileURL.path)

        XCTAssertEqual(ws.tabs.count, 1)
        XCTAssertEqual(ws.markdownContent, "# Hello")
    }

    func testOpenFromRelativePath() {
        let cwd = FileManager.default.currentDirectoryPath
        let fileName = "relative-test-\(UUID().uuidString).md"
        let fileURL = URL(fileURLWithPath: cwd).appendingPathComponent(fileName)
        try! "relative content".write(to: fileURL, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let ws = Workspace()
        ws.openFromPath(fileName)

        XCTAssertEqual(ws.markdownContent, "relative content")
    }

    func testOpenFromTildePath() {
        let homeDir = NSHomeDirectory()
        let fileName = ".mdpreview-tilde-test-\(UUID().uuidString).md"
        let fileURL = URL(fileURLWithPath: homeDir).appendingPathComponent(fileName)
        try! "tilde content".write(to: fileURL, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let ws = Workspace()
        ws.openFromPath("~/\(fileName)")

        XCTAssertEqual(ws.markdownContent, "tilde content")
    }

    // MARK: - Open directory

    func testOpenDirectorySetsFileTree() {
        let dir = tempDir.appendingPathComponent("project")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try! "readme".write(to: dir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openDirectory(dir)

        XCTAssertNotNil(ws.directoryURL)
        XCTAssertFalse(ws.fileTreeNodes.isEmpty)
    }

    func testOpenURLDetectsDirectory() {
        let dir = tempDir.appendingPathComponent("mydir")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try! "x".write(to: dir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openURL(dir)

        XCTAssertNotNil(ws.directoryURL)
        XCTAssertEqual(ws.tabs.count, 0)
    }

    func testOpenURLDetectsFile() {
        let fileURL = tempDir.appendingPathComponent("file.md")
        try! "content".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openURL(fileURL)

        XCTAssertNil(ws.directoryURL)
        XCTAssertEqual(ws.tabs.count, 1)
    }

    // MARK: - Tab management

    func testCloseTab() {
        let file1 = tempDir.appendingPathComponent("a.md")
        let file2 = tempDir.appendingPathComponent("b.md")
        try! "A".write(to: file1, atomically: true, encoding: .utf8)
        try! "B".write(to: file2, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(file1)
        ws.openFile(file2)
        XCTAssertEqual(ws.tabs.count, 2)

        // Close the selected (second) tab
        ws.closeTab(ws.selectedTabID!)
        XCTAssertEqual(ws.tabs.count, 1)
        XCTAssertEqual(ws.markdownContent, "A")
    }

    func testCloseLastTab() {
        let fileURL = tempDir.appendingPathComponent("only.md")
        try! "only".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)
        ws.closeTab(ws.selectedTabID!)

        XCTAssertEqual(ws.tabs.count, 0)
        XCTAssertNil(ws.selectedTabID)
        XCTAssertEqual(ws.markdownContent, "")
    }

    func testSelectNextTab() {
        let file1 = tempDir.appendingPathComponent("a.md")
        let file2 = tempDir.appendingPathComponent("b.md")
        try! "A".write(to: file1, atomically: true, encoding: .utf8)
        try! "B".write(to: file2, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(file1)
        ws.openFile(file2)
        // Currently on file2

        ws.selectNextTab()
        XCTAssertEqual(ws.markdownContent, "A") // Wrapped to first

        ws.selectNextTab()
        XCTAssertEqual(ws.markdownContent, "B")
    }

    func testSelectPreviousTab() {
        let file1 = tempDir.appendingPathComponent("a.md")
        let file2 = tempDir.appendingPathComponent("b.md")
        try! "A".write(to: file1, atomically: true, encoding: .utf8)
        try! "B".write(to: file2, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(file1)
        ws.openFile(file2)

        ws.selectPreviousTab()
        XCTAssertEqual(ws.markdownContent, "A")
    }

    // MARK: - Display name

    func testDisplayNameWithTab() {
        let fileURL = tempDir.appendingPathComponent("readme.md")
        try! "x".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)

        XCTAssertEqual(ws.displayName, "readme.md")
    }

    func testDisplayNameWithDirectory() {
        let dir = tempDir.appendingPathComponent("project")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try! "x".write(to: dir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openDirectory(dir)

        XCTAssertEqual(ws.displayName, "project")
    }

    func testDisplayNameDefault() {
        let ws = Workspace()
        XCTAssertEqual(ws.displayName, "MDPreview")
    }

    // MARK: - Error handling

    func testOpenNonExistentFileSetsError() {
        let ws = Workspace()
        ws.openURL(tempDir.appendingPathComponent("no-such-file.md"))

        XCTAssertNotNil(ws.errorMessage)
    }

    // MARK: - File watching

    func testFileWatchingUpdatesContent() {
        let fileURL = tempDir.appendingPathComponent("watch.md")
        try! "initial".write(to: fileURL, atomically: true, encoding: .utf8)

        let ws = Workspace()
        ws.openFile(fileURL)
        XCTAssertEqual(ws.markdownContent, "initial")

        let updated = expectation(description: "content updated via watcher")
        let cancellable = ws.$markdownContent.dropFirst().sink { newValue in
            if newValue == "modified" {
                updated.fulfill()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try! "modified".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        cancellable.cancel()
    }
}
