import XCTest
@testable import MDPreviewCore

final class MarkdownRenderingTests: XCTestCase {

    // MARK: - Template HTML loads from bundle

    func testTemplateHTMLExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "template",
            withExtension: "html",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "template.html should be loadable from the resource bundle")
    }

    func testTemplateHTMLContainsRenderFunction() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("function render(markdown, basePath, preserveScroll)"),
            "template.html should contain the render(markdown, basePath, preserveScroll) function")
    }

    func testTemplateHTMLContainsBaseTagHandling() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        // Verify that the render function handles base URL for relative image paths
        XCTAssertTrue(content.contains("base.href = 'file://' + basePath"),
            "template.html should set base href for relative path resolution")
    }

    func testTemplateHTMLContainsMarkedSetup() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("marked.use("),
            "template.html should configure marked.js via marked.use()")
        XCTAssertTrue(content.contains("gfm: true"),
            "template.html should enable GitHub Flavored Markdown")
    }

    func testTemplateHTMLContainsContentDiv() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("id=\"content\""),
            "template.html should contain a div with id='content'")
    }

    func testTemplateHTMLContainsHighlightJS() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("hljs.highlightElement"),
            "template.html should use highlight.js for syntax highlighting")
    }

    // MARK: - Bundled JavaScript files

    func testMarkedMinJSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "marked.min",
            withExtension: "js",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "marked.min.js should be bundled in Resources")
    }

    func testHighlightMinJSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "highlight.min",
            withExtension: "js",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "highlight.min.js should be bundled in Resources")
    }

    // MARK: - CSS files bundled

    func testGitHubCSSExistsInBundle() {
        let lightURL = Bundle.module.url(
            forResource: "github.min",
            withExtension: "css",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(lightURL, "github.min.css should be bundled in Resources")

        let darkURL = Bundle.module.url(
            forResource: "github-dark.min",
            withExtension: "css",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(darkURL, "github-dark.min.css should be bundled in Resources")
    }

    // MARK: - Template HTML structure

    func testTemplateHTMLHasProperStructure() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(content.contains("<!DOCTYPE html>"), "Should be a proper HTML5 document")
        XCTAssertTrue(content.contains("<meta charset=\"utf-8\">"), "Should declare UTF-8 charset")
        XCTAssertTrue(content.contains("marked.min.js"), "Should reference marked.min.js")
        XCTAssertTrue(content.contains("highlight.min.js"), "Should reference highlight.min.js")
    }

    // MARK: - JavaScript escaping

    func testEscapeForJavaScriptBackslash() {
        let result = MarkdownWebView.escapeForJavaScript("a\\b")
        XCTAssertEqual(result, "a\\\\b")
    }

    func testEscapeForJavaScriptBacktick() {
        let result = MarkdownWebView.escapeForJavaScript("code: `hello`")
        XCTAssertEqual(result, "code: \\`hello\\`")
    }

    func testEscapeForJavaScriptDollarSign() {
        let result = MarkdownWebView.escapeForJavaScript("price: $10")
        XCTAssertEqual(result, "price: \\$10")
    }

    func testEscapeForJavaScriptCRLF() {
        let result = MarkdownWebView.escapeForJavaScript("line1\r\nline2")
        XCTAssertEqual(result, "line1\\nline2")
    }

    func testEscapeForJavaScriptCR() {
        let result = MarkdownWebView.escapeForJavaScript("line1\rline2")
        XCTAssertEqual(result, "line1\\nline2")
    }

    func testEscapeForJavaScriptPlainText() {
        let result = MarkdownWebView.escapeForJavaScript("Hello, World!")
        XCTAssertEqual(result, "Hello, World!")
    }

    func testEscapeForJavaScriptCombined() {
        let result = MarkdownWebView.escapeForJavaScript("Use `$HOME\\path`\r\n")
        XCTAssertEqual(result, "Use \\`\\$HOME\\\\path\\`\\n")
    }

    func testEscapeForJavaScriptEmptyString() {
        let result = MarkdownWebView.escapeForJavaScript("")
        XCTAssertEqual(result, "")
    }
}
