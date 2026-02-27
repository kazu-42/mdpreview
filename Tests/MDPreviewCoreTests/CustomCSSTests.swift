import XCTest
import Combine
@testable import MDPreviewCore

final class CustomCSSTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Clear persisted state between tests
        UserDefaults.standard.removeObject(forKey: "customCSSPath")
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "customCSSPath")
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Workspace custom CSS

    func testInitialCustomCSSIsEmpty() {
        let workspace = Workspace()
        XCTAssertEqual(workspace.customCSS, "")
        XCTAssertEqual(workspace.customCSSPath, "")
    }

    func testSetCustomCSSPathLoadsCSS() throws {
        let cssURL = tempDir.appendingPathComponent("custom.css")
        let cssContent = "body { font-size: 18px; }"
        try cssContent.write(to: cssURL, atomically: true, encoding: .utf8)

        let workspace = Workspace()
        workspace.setCustomCSSPath(cssURL.path)

        XCTAssertEqual(workspace.customCSS, cssContent)
        XCTAssertEqual(workspace.customCSSPath, cssURL.path)
    }

    func testRemoveCustomCSSClearsContent() throws {
        let cssURL = tempDir.appendingPathComponent("custom.css")
        try "body { color: red; }".write(to: cssURL, atomically: true, encoding: .utf8)

        let workspace = Workspace()
        workspace.setCustomCSSPath(cssURL.path)
        XCTAssertFalse(workspace.customCSS.isEmpty)

        workspace.setCustomCSSPath("")
        XCTAssertEqual(workspace.customCSS, "")
        XCTAssertEqual(workspace.customCSSPath, "")
    }

    func testSetCustomCSSPathWithNonExistentFileDoesNotCrash() {
        let workspace = Workspace()
        workspace.setCustomCSSPath("/nonexistent/path/custom.css")
        // Should not crash; CSS stays empty since file cannot be read
        XCTAssertEqual(workspace.customCSS, "")
    }

    func testCSSLiveReload() throws {
        let cssURL = tempDir.appendingPathComponent("live.css")
        try "body { color: blue; }".write(to: cssURL, atomically: true, encoding: .utf8)

        let workspace = Workspace()
        workspace.setCustomCSSPath(cssURL.path)
        XCTAssertEqual(workspace.customCSS, "body { color: blue; }")

        let expectation = self.expectation(description: "CSS reloaded")
        let updatedCSS = "body { color: green; }"

        var cancellable: AnyCancellable?
        cancellable = workspace.$customCSS
            .dropFirst()
            .sink { css in
                if css == updatedCSS {
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        try updatedCSS.write(to: cssURL, atomically: true, encoding: .utf8)
        waitForExpectations(timeout: 2.0)
    }
}
