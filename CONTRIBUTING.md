# Contributing to MDPreview

Thank you for your interest in contributing to MDPreview! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ or Swift 5.9+ toolchain
- Git

### Getting Started

```bash
# Clone the repository
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Build the project
swift build

# Run tests
swift test

# Build release and create .app bundle
make all

# Launch the app
make run
```

### Project Structure

```
mdpreview/
├── Package.swift              # Swift Package Manager manifest
├── Makefile                   # Build automation
├── Sources/
│   ├── MDPreviewCore/         # Core library (testable)
│   │   ├── MDPreviewApp.swift # SwiftUI App scene + menu commands
│   │   ├── AppDelegate.swift  # CLI/Finder integration
│   │   ├── Workspace.swift    # Tab management + app state
│   │   ├── MainView.swift     # Layout: sidebar + tabs + preview
│   │   ├── FileTree.swift     # Directory tree model + view
│   │   ├── MarkdownWebView.swift
│   │   ├── FileWatcher.swift
│   │   ├── CLIInstaller.swift # Command line tool installer
│   │   └── Resources/        # HTML template, JS, CSS
│   └── MDPreview/
│       └── main.swift         # Entry point
├── Tests/
│   └── MDPreviewCoreTests/    # Unit and integration tests
├── Assets/                    # App icon source files
├── Supporting/                # Info.plist, entitlements, CLI script
└── .github/                   # CI/CD workflows, templates
```

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/kazu-42/mdpreview/issues) to avoid duplicates
2. Use the **Bug Report** issue template
3. Include your macOS version and MDPreview version
4. Provide steps to reproduce the issue

### Suggesting Features

1. Open a **Feature Request** issue
2. Describe the use case and proposed solution
3. Consider whether the feature aligns with the project's goal of being lightweight

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/your-feature
   ```
3. Make your changes following the [code conventions](#code-conventions)
4. Add or update tests as needed
5. Ensure all tests pass:
   ```bash
   swift test
   ```
6. Ensure the release build succeeds:
   ```bash
   swift build -c release
   ```
7. Commit with a clear message:
   ```bash
   git commit -m "Add support for mermaid diagrams"
   ```
8. Push and open a pull request

### Branch Naming

- `feat/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation changes
- `chore/` - Build, CI, and tooling changes

## Code Conventions

### Swift Style

- Use Swift's standard formatting conventions
- Prefer `let` over `var` when possible
- Use explicit access control (`public`, `internal`, `private`)
- Keep types and functions focused and small
- Use `final` for classes that shouldn't be subclassed

### Commit Messages

- Use imperative mood: "Add feature" not "Added feature"
- Keep the first line under 72 characters
- Reference issue numbers when applicable: "Fix #123"

### Testing

- Write tests for all new functionality
- Use descriptive test method names: `testFileWatcherDetectsWriteEvent`
- Follow Arrange-Act-Assert pattern
- Tests must pass on macOS 13+

## Architecture Decisions

### Why WKWebView + marked.js?

MDPreview uses WKWebView with bundled JavaScript libraries (marked.js + highlight.js) instead of native Swift Markdown rendering for several reasons:

1. **Full GFM compatibility** - Tables, task lists, strikethrough, autolinks
2. **Performance** - WebKit's rendering engine handles large files efficiently
3. **Syntax highlighting** - highlight.js supports 40+ languages out of the box
4. **Zero Swift dependencies** - No external Swift packages to manage
5. **CSS-only dark/light mode** - `prefers-color-scheme` media queries work automatically

### Why SPM + Makefile?

Swift Package Manager handles compilation and dependency resolution. The Makefile handles .app bundle assembly, code signing, and installation - tasks that SPM doesn't support natively. This keeps the project lightweight and editor-agnostic.

## Release Process

Releases are automated via GitHub Actions:

1. Update version in `Supporting/Info.plist`
2. Update `CHANGELOG.md`
3. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. GitHub Actions builds the release, creates DMG/ZIP, and publishes a GitHub Release

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
