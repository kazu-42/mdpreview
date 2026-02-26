# MDPreview

A lightweight, fast Markdown preview app for macOS. Built for developers who need to quickly preview `plan.md`, `README.md`, and other Markdown files from the terminal.

[日本語](docs/i18n/README.ja.md) | [한국어](docs/i18n/README.ko.md) | [Español](docs/i18n/README.es.md) | [Français](docs/i18n/README.fr.md) | [Deutsch](docs/i18n/README.de.md) | [Português](docs/i18n/README.pt-BR.md) | [简体中文](docs/i18n/README.zh-CN.md)

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
- **Tabs** - Open multiple files as tabs, switch with Cmd+Shift+] / [
- **File tree sidebar** - Open a directory to browse and preview Markdown files
- **Dark/Light mode** - Follows macOS system appearance
- **CLI-friendly** - `mdpreview file.md` launches instantly, returns to terminal
- **Zero dependencies** - No external Swift packages
- **Lightweight** - ~200KB binary + ~160KB bundled JS/CSS

## Installation

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### Download

Download the latest `.dmg` or `.zip` from the [Releases](https://github.com/kazu-42/mdpreview/releases) page.

After installing, open the app and go to **MDPreview > Install Command Line Tool...** to set up the `mdpreview` command.

### Build from Source

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Build and create .app bundle
make all

# Install to /Applications
make install

# Install CLI (requires sudo)
sudo make cli
```

## Usage

### From the Terminal

```bash
# Open a Markdown file
mdpreview README.md

# Open multiple files as tabs
mdpreview file1.md file2.md

# Open a directory with file tree sidebar
mdpreview .
mdpreview ~/projects/my-app/

# Launch the app without arguments
mdpreview
```

### From Finder

- **Drag and drop** a `.md` file onto the MDPreview window or Dock icon
- **Right-click** a `.md` file > Open With > MDPreview
- Use **Cmd+O** to open a file or directory from the menu

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open file / directory |
| `Cmd+W` | Close tab / window |
| `Cmd+Shift+]` | Next tab |
| `Cmd+Shift+[` | Previous tab |
| `Ctrl+Tab` | Next tab |
| `Cmd+1` - `Cmd+9` | Go to tab 1-9 |
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
├── MDPreviewCore/            # Core library
│   ├── MDPreviewApp.swift    # SwiftUI App scene + commands
│   ├── AppDelegate.swift     # Finder/CLI integration
│   ├── Workspace.swift       # Tab management + state
│   ├── MainView.swift        # Layout: sidebar + tabs + preview
│   ├── FileTree.swift        # Directory tree model + view
│   ├── MarkdownWebView.swift # WKWebView wrapper
│   ├── FileWatcher.swift     # DispatchSource file monitor
│   ├── CLIInstaller.swift    # Command line tool installer
│   └── Resources/
│       ├── template.html     # HTML rendering shell
│       ├── marked.min.js     # Markdown parser (GFM)
│       ├── highlight.min.js  # Syntax highlighting
│       └── *.css             # GitHub-style themes
└── MDPreview/
    └── main.swift            # Entry point
```

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

### Build Requirements

- Xcode 15.0+ or Swift 5.9+ toolchain
- No additional dependencies required

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Please note that this project follows a [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

To report a security vulnerability, please see our [Security Policy](SECURITY.md).

## Acknowledgments

- [marked.js](https://github.com/markedjs/marked) - Markdown parser
- [highlight.js](https://github.com/highlightjs/highlight.js) - Syntax highlighting
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UX inspiration

## License

[MIT License](LICENSE) - see [LICENSE](LICENSE) for details.
