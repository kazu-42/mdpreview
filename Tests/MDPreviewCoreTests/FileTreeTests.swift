import XCTest
@testable import MDPreviewCore

final class FileTreeTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileTreeTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Build tree

    func testBuildTreeIncludesMarkdownFiles() {
        try! "a".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try! "b".write(to: tempDir.appendingPathComponent("notes.markdown"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        let names = tree.map(\.name)
        XCTAssertTrue(names.contains("README.md"))
        XCTAssertTrue(names.contains("notes.markdown"))
    }

    func testBuildTreeIncludesNonMarkdownFiles() {
        try! "x".write(to: tempDir.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        XCTAssertTrue(tree.contains(where: { $0.name == "main.swift" }))
    }

    func testBuildTreeIncludesSubdirectories() {
        let sub = tempDir.appendingPathComponent("docs")
        try! FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try! "doc".write(to: sub.appendingPathComponent("guide.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        let docsNode = tree.first(where: { $0.name == "docs" })
        XCTAssertNotNil(docsNode)
        XCTAssertTrue(docsNode?.isDirectory ?? false)
        XCTAssertEqual(docsNode?.children?.count, 1)
    }

    func testBuildTreeIncludesHiddenFiles() {
        // Hidden files are now shown (user requested this change)
        try! "hidden".write(to: tempDir.appendingPathComponent(".hidden.md"), atomically: true, encoding: .utf8)
        try! "visible".write(to: tempDir.appendingPathComponent("visible.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        XCTAssertTrue(tree.contains(where: { $0.name == ".hidden.md" }))
        XCTAssertTrue(tree.contains(where: { $0.name == "visible.md" }))
    }

    func testBuildTreeSkipsNodeModules() {
        let nm = tempDir.appendingPathComponent("node_modules")
        try! FileManager.default.createDirectory(at: nm, withIntermediateDirectories: true)
        try! "x".write(to: nm.appendingPathComponent("package.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        XCTAssertFalse(tree.contains(where: { $0.name == "node_modules" }))
    }

    func testBuildTreeIncludesGitDirectory() {
        // Hidden directories like .git are now shown (user requested this change)
        let git = tempDir.appendingPathComponent(".git")
        try! FileManager.default.createDirectory(at: git, withIntermediateDirectories: true)
        try! "x".write(to: git.appendingPathComponent("config.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        // .git is now visible since we show hidden files
        XCTAssertTrue(tree.contains(where: { $0.name == ".git" }))
    }

    func testBuildTreeSkipsEmptyDirectories() {
        let empty = tempDir.appendingPathComponent("empty-dir")
        try! FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        let tree = FileTreeNode.buildTree(from: tempDir)

        XCTAssertFalse(tree.contains(where: { $0.name == "empty-dir" }))
    }

    func testBuildTreeSortsDirectoriesFirst() {
        try! "z".write(to: tempDir.appendingPathComponent("z-file.md"), atomically: true, encoding: .utf8)
        let sub = tempDir.appendingPathComponent("a-dir")
        try! FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try! "a".write(to: sub.appendingPathComponent("inner.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeNode.buildTree(from: tempDir)

        XCTAssertTrue(tree[0].isDirectory, "Directories should come first")
        XCTAssertFalse(tree[1].isDirectory)
    }

    func testBuildTreeEmptyDirectory() {
        let empty = tempDir.appendingPathComponent("empty")
        try! FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        let tree = FileTreeNode.buildTree(from: empty)
        XCTAssertTrue(tree.isEmpty)
    }
}
