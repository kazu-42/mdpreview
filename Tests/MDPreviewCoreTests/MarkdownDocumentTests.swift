import XCTest
@testable import MDPreviewCore

final class MarkdownDocumentTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownDocumentTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Open with absolute path

    func testOpenWithAbsolutePath() {
        let fileURL = tempDir.appendingPathComponent("absolute.md")
        try! "# Hello".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(path: fileURL.path)

        // The reload happens synchronously for the file read, then dispatches to main
        let expectation = expectation(description: "content loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.fileURL, fileURL)
        XCTAssertEqual(doc.markdownContent, "# Hello")
        XCTAssertNil(doc.errorMessage)
    }

    // MARK: - Open with relative path

    func testOpenWithRelativePath() {
        // Create a file in the current working directory
        let cwd = FileManager.default.currentDirectoryPath
        let fileName = "relative-test-\(UUID().uuidString).md"
        let fileURL = URL(fileURLWithPath: cwd).appendingPathComponent(fileName)
        try! "relative content".write(to: fileURL, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let doc = MarkdownDocument()
        doc.open(path: fileName)

        let expectation = expectation(description: "content loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "relative content")
    }

    // MARK: - Open with tilde path

    func testOpenWithTildePath() {
        // Write to home directory temp location
        let homeDir = NSHomeDirectory()
        let fileName = ".mdpreview-tilde-test-\(UUID().uuidString).md"
        let fileURL = URL(fileURLWithPath: homeDir).appendingPathComponent(fileName)
        try! "tilde content".write(to: fileURL, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let doc = MarkdownDocument()
        doc.open(path: "~/\(fileName)")

        let expectation = expectation(description: "content loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "tilde content")
        XCTAssertEqual(doc.fileURL?.path, fileURL.path)
    }

    // MARK: - Reload updates content

    func testReloadUpdatesContent() {
        let fileURL = tempDir.appendingPathComponent("reload.md")
        try! "version 1".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let loaded = expectation(description: "initial load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(doc.markdownContent, "version 1")

        // Modify the file
        try! "version 2".write(to: fileURL, atomically: true, encoding: .utf8)
        doc.reload()

        let reloaded = expectation(description: "reloaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            reloaded.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(doc.markdownContent, "version 2")
    }

    // MARK: - Display name

    func testDisplayNameReturnsFilename() {
        let doc = MarkdownDocument()
        doc.fileURL = URL(fileURLWithPath: "/tmp/readme.md")
        XCTAssertEqual(doc.displayName, "readme.md")
    }

    func testDisplayNameReturnsMDPreviewWhenNoFile() {
        let doc = MarkdownDocument()
        XCTAssertEqual(doc.displayName, "MDPreview")
    }

    func testDisplayNameWithNestedPath() {
        let doc = MarkdownDocument()
        doc.fileURL = URL(fileURLWithPath: "/Users/test/Documents/notes/daily.md")
        XCTAssertEqual(doc.displayName, "daily.md")
    }

    // MARK: - Open non-existent file sets error

    func testOpenNonExistentFileSetsError() {
        let doc = MarkdownDocument()
        let bogusURL = tempDir.appendingPathComponent("no-such-file.md")
        doc.open(url: bogusURL)

        let expectation = expectation(description: "error set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertNotNil(doc.errorMessage)
        XCTAssertEqual(doc.markdownContent, "")
    }

    // MARK: - File watching integration

    func testFileWatchingUpdatesContentOnExternalModification() {
        let fileURL = tempDir.appendingPathComponent("watch-integration.md")
        try! "initial content".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        doc.open(url: fileURL)

        let initialLoad = expectation(description: "initial load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            initialLoad.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(doc.markdownContent, "initial content")

        // Externally modify the file (non-atomic to trigger write event)
        let contentUpdated = expectation(description: "content updated via watcher")

        // Observe changes to markdownContent
        let cancellable = doc.$markdownContent.dropFirst().sink { newValue in
            if newValue == "externally modified" {
                contentUpdated.fulfill()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            try! "externally modified".write(to: fileURL, atomically: false, encoding: .utf8)
        }

        waitForExpectations(timeout: 3.0)
        cancellable.cancel()
    }

    // MARK: - Open clears previous error

    func testOpenClearsPreviousError() {
        let doc = MarkdownDocument()

        // First open a non-existent file to set an error
        let bogusURL = tempDir.appendingPathComponent("nonexistent.md")
        doc.open(url: bogusURL)

        let errorSet = expectation(description: "error set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            errorSet.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(doc.errorMessage)

        // Now open a valid file
        let validURL = tempDir.appendingPathComponent("valid.md")
        try! "valid content".write(to: validURL, atomically: true, encoding: .utf8)
        doc.open(url: validURL)

        let cleared = expectation(description: "error cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cleared.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        XCTAssertNil(doc.errorMessage)
        XCTAssertEqual(doc.markdownContent, "valid content")
    }

    // MARK: - Reload with no file does nothing

    func testReloadWithNoFileURLDoesNothing() {
        let doc = MarkdownDocument()
        doc.reload() // Should not crash
        XCTAssertEqual(doc.markdownContent, "")
        XCTAssertNil(doc.errorMessage)
    }

    // MARK: - Open sets fileURL

    func testOpenSetsFileURL() {
        let fileURL = tempDir.appendingPathComponent("seturl.md")
        try! "test".write(to: fileURL, atomically: true, encoding: .utf8)

        let doc = MarkdownDocument()
        XCTAssertNil(doc.fileURL)

        doc.open(url: fileURL)
        XCTAssertEqual(doc.fileURL, fileURL)
    }
}
