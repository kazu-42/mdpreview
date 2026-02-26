import XCTest
@testable import MDPreviewCore

final class AppDelegateTests: XCTestCase {

    // MARK: - URL open posts notification

    func testOpenURLPostsDidRequestOpenFileNotification() {
        let delegate = AppDelegate()
        let testURL = URL(fileURLWithPath: "/tmp/test.md")

        _ = expectation(
            forNotification: .didRequestOpenFile,
            object: nil
        ) { notification in
            guard let url = notification.object as? URL else { return false }
            return url == testURL
        }

        delegate.application(NSApplication.shared, open: [testURL])

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Empty URLs does not post notification

    func testOpenEmptyURLsDoesNotPost() {
        let delegate = AppDelegate()

        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .didRequestOpenFile,
            object: nil,
            queue: .main
        ) { _ in
            received = true
        }

        delegate.application(NSApplication.shared, open: [])

        let waitExp = expectation(description: "wait to verify no notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            waitExp.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(received, "No notification should be posted for empty URLs array")
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Multiple URLs post notifications for all

    func testOpenMultipleURLsPostsAll() {
        let delegate = AppDelegate()
        let url1 = URL(fileURLWithPath: "/tmp/first.md")
        let url2 = URL(fileURLWithPath: "/tmp/second.md")

        var receivedURLs: [URL] = []
        let observer = NotificationCenter.default.addObserver(
            forName: .didRequestOpenFile,
            object: nil,
            queue: .main
        ) { notification in
            if let url = notification.object as? URL {
                receivedURLs.append(url)
            }
        }

        delegate.application(NSApplication.shared, open: [url1, url2])

        let waitExp = expectation(description: "wait for notifications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            waitExp.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(receivedURLs.count, 2)
        XCTAssertEqual(receivedURLs[0], url1)
        XCTAssertEqual(receivedURLs[1], url2)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Notification name is correct

    func testNotificationNameConstant() {
        XCTAssertEqual(
            Notification.Name.didRequestOpenFile.rawValue,
            "didRequestOpenFile"
        )
    }
}
