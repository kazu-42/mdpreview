import XCTest
@testable import MDPreviewCore

final class LinkValidationTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - extractLocalLinks

    func testNoLinksReturnsEmpty() {
        let markdown = "# Hello\nNo links here."
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty)
    }

    func testExistingFileIsNotBroken() throws {
        let fileURL = tempDir.appendingPathComponent("other.md")
        try "# Other".write(to: fileURL, atomically: true, encoding: .utf8)

        let markdown = "[link](other.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty, "Existing file should not appear as broken")
    }

    func testMissingFileIsReported() {
        let markdown = "[link](nonexistent.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertEqual(result, ["nonexistent.md"])
    }

    func testDotSlashPrefixIsNormalized() {
        let markdown = "[link](./nonexistent.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertEqual(result, ["nonexistent.md"])
    }

    func testImagesAreExcluded() {
        let markdown = "![image](nonexistent.png)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty, "Images should not be checked as links")
    }

    func testExternalHTTPLinksAreExcluded() {
        let markdown = "[link](https://example.com/page)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty)
    }

    func testExternalHTTPLinksWithoutSAreExcluded() {
        let markdown = "[link](http://example.com/page)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty)
    }

    func testAnchorOnlyLinksAreExcluded() {
        let markdown = "[link](#heading)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty, "Same-page anchor links should not be validated")
    }

    func testFragmentIsStrippedBeforeValidation() throws {
        let fileURL = tempDir.appendingPathComponent("guide.md")
        try "# Guide".write(to: fileURL, atomically: true, encoding: .utf8)

        let markdown = "[link](guide.md#section)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty, "Fragment should be stripped before checking file existence")
    }

    func testFragmentWithMissingFileIsReported() {
        let markdown = "[link](missing.md#section)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertEqual(result, ["missing.md"])
    }

    func testMultipleBrokenLinksReported() {
        let markdown = "[a](a.md) [b](b.md) [c](c.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertEqual(Set(result), Set(["a.md", "b.md", "c.md"]))
    }

    func testMixedExistingAndBrokenLinks() throws {
        let existingURL = tempDir.appendingPathComponent("exists.md")
        try "# Exists".write(to: existingURL, atomically: true, encoding: .utf8)

        let markdown = "[good](exists.md) [bad](missing.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertEqual(result, ["missing.md"])
    }

    func testAbsolutePathsAreExcluded() {
        let markdown = "[link](/usr/local/share/doc.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty, "Absolute paths should not be checked")
    }

    func testFileURLsAreExcluded() {
        let markdown = "[link](file:///some/path.md)"
        let result = MarkdownWebView.extractLocalLinks(in: markdown, baseURL: tempDir)
        XCTAssertTrue(result.isEmpty)
    }
}
