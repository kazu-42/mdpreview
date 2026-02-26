# MDPreview

A lightweight, fast Markdown preview app for macOS. Built for developers who need to quickly preview `plan.md`, `README.md`, and other Markdown files from the terminal.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## Features

- **Fast startup** - Native macOS app, opens instantly
- **Full GFM support** - Tables, task lists, strikethrough, autolinks
- **Syntax highlighting** - 40+ programming languages via [highlight.js](https://highlightjs.org/)
- **Live reload** - Automatically refreshes when the file changes on disk
- **Dark/Light mode** - Follows macOS system appearance
- **Zero dependencies** - No external Swift packages
- **CLI-friendly** - `mdpreview path/to/file.md`
- **Lightweight** - ~200KB binary + ~160KB bundled JS/CSS

## Installation

### Download

Download the latest `.dmg` or `.zip` from the [Releases](https://github.com/kazu-42/mdpreview/releases) page.

### Build from Source

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Build and create .app bundle
make all

# Install to /Applications and create CLI command
make install
make cli
```

### Homebrew (coming soon)

```bash
brew install --cask kazu-42/tap/mdpreview
```

## Usage

### From the Terminal

```bash
# Open a Markdown file
mdpreview README.md

# Or use the full path
mdpreview ~/projects/my-app/plan.md

# Or launch the .app directly
open -a MDPreview file.md
```

### From Finder

- **Drag and drop** a `.md` file onto the MDPreview window or Dock icon
- **Right-click** a `.md` file > Open With > MDPreview
- Use **Cmd+O** to open a file from the menu

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open file |
| `Cmd+W` | Close window |
| `Cmd+Q` | Quit |

## Screenshots

### Light Mode
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Light Mode" width="600">
</p>

### Dark Mode
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Dark Mode" width="600">
</p>

## How It Works

MDPreview uses a minimal SwiftUI shell with a `WKWebView` for rendering. The rendering pipeline is:

```
Markdown file on disk
  → Swift reads file content
    → Passes to WKWebView
      → marked.js converts to HTML (GFM)
        → highlight.js colorizes code blocks
          → CSS styles for dark/light mode
```

File changes are detected using GCD's `DispatchSource` file system monitoring, with debouncing to handle rapid saves.

## Architecture

```
Sources/
├── MDPreviewCore/           # Core library
│   ├── MDPreviewApp.swift   # SwiftUI App scene
│   ├── ContentView.swift    # Main view + drag-and-drop
│   ├── MarkdownWebView.swift# WKWebView wrapper
│   ├── MarkdownDocument.swift# File loading + state
│   ├── FileWatcher.swift    # DispatchSource file monitor
│   ├── AppDelegate.swift    # Finder integration
│   └── Resources/
│       ├── template.html    # HTML rendering shell
│       ├── marked.min.js    # Markdown parser (GFM)
│       ├── highlight.min.js # Syntax highlighting
│       └── *.css            # GitHub-style themes
└── MDPreview/
    └── main.swift           # Entry point
```

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

### Build Requirements

- Xcode 15.0+ or Swift 5.9+ toolchain
- No additional dependencies required

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Acknowledgments

- [marked.js](https://github.com/markedjs/marked) - Markdown parser
- [highlight.js](https://github.com/highlightjs/highlight.js) - Syntax highlighting
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UX inspiration

## License

[MIT License](LICENSE) - see [LICENSE](LICENSE) for details.
