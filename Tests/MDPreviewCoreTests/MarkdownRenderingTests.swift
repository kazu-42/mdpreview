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

    // MARK: - KaTeX and Mermaid bundled files

    func testKaTeXMinJSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "katex.min",
            withExtension: "js",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "katex.min.js should be bundled in Resources")
    }

    func testKaTeXMinCSSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "katex.min",
            withExtension: "css",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "katex.min.css should be bundled in Resources")
    }

    func testAutoRenderMinJSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "auto-render.min",
            withExtension: "js",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "auto-render.min.js should be bundled in Resources")
    }

    func testMermaidMinJSExistsInBundle() {
        let url = Bundle.module.url(
            forResource: "mermaid.min",
            withExtension: "js",
            subdirectory: "Resources"
        )
        XCTAssertNotNil(url, "mermaid.min.js should be bundled in Resources")
    }

    func testTemplateHTMLContainsKaTeX() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("katex.min.js"), "template.html should reference katex.min.js")
        XCTAssertTrue(content.contains("katex.min.css"), "template.html should reference katex.min.css")
        XCTAssertTrue(content.contains("renderMathInElement"), "template.html should call renderMathInElement")
    }

    func testTemplateHTMLContainsMermaid() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("mermaid.min.js"), "template.html should reference mermaid.min.js")
        XCTAssertTrue(content.contains("mermaid.initialize"), "template.html should call mermaid.initialize")
    }

    func testTemplateHTMLContainsAnchorClickInterceptor() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("href.startsWith('#')"),
            "template.html should intercept same-page anchor clicks")
    }

    func testTemplateHTMLContainsBrokenLinkFunction() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("function markBrokenLinks"),
            "template.html should define markBrokenLinks function")
        XCTAssertTrue(content.contains("broken-link"),
            "template.html should define broken-link CSS class")
    }

    func testTemplateHTMLContainsCustomCSSFunction() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources")
        )
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("function applyCustomCSS"),
            "template.html should define applyCustomCSS function")
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
