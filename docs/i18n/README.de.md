# MDPreview

Eine leichtgewichtige, schnelle Markdown-Vorschau-App fur macOS. Entwickelt fur Entwickler, die `plan.md`, `README.md` und andere Markdown-Dateien schnell im Terminal vorschauen mochten.

[English](../../README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Português](README.pt-BR.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## Funktionen

- **Schneller Start** - Native macOS-App, offnet sofort
- **Volle GFM-Unterstutzung** - Tabellen, Task-Listen, Durchstreichungen, automatische Links
- **Syntax-Hervorhebung** - 40+ Programmiersprachen via [highlight.js](https://highlightjs.org/)
- **Live-Neuladen** - Aktualisiert automatisch, wenn sich die Datei auf der Festplatte andert
- **Tabs** - Mehrere Dateien als Tabs offnen, wechseln mit Cmd+Shift+] / [
- **Dateibaum-Seitenleiste** - Verzeichnis offnen, um Markdown-Dateien zu durchsuchen und vorzuschauen
- **Dunkel-/Hellmodus** - Folgt der macOS-Systemdarstellung
- **CLI-freundlich** - `mdpreview file.md` startet sofort, kehrt zum Terminal zuruck
- **Keine Abhangigkeiten** - Keine externen Swift-Packages
- **Leichtgewichtig** - ~200KB Binary + ~160KB gebundeltes JS/CSS

## Installation

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### Download

Laden Sie die neueste `.dmg` oder `.zip` von der [Releases](https://github.com/kazu-42/mdpreview/releases)-Seite herunter.

Nach der Installation offnen Sie die App und gehen Sie zu **MDPreview > Install Command Line Tool...**, um den `mdpreview`-Befehl einzurichten.

### Aus dem Quellcode erstellen

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Erstellen und .app-Bundle erstellen
make all

# Nach /Applications installieren
make install

# CLI installieren (erfordert sudo)
sudo make cli
```

## Verwendung

### Uber das Terminal

```bash
# Eine Markdown-Datei offnen
mdpreview README.md

# Mehrere Dateien als Tabs offnen
mdpreview file1.md file2.md

# Ein Verzeichnis mit Dateibaum-Seitenleiste offnen
mdpreview .
mdpreview ~/projects/my-app/

# Die App ohne Argumente starten
mdpreview
```

### Uber Finder

- **Ziehen und Ablegen** einer `.md`-Datei auf das MDPreview-Fenster oder Dock-Icon
- **Rechtsklick** auf eine `.md`-Datei > Offnen mit > MDPreview
- Verwenden Sie **Cmd+O**, um eine Datei oder ein Verzeichnis aus dem Menu zu offnen

### Tastaturkurzel

| Kurzel | Aktion |
|--------|--------|
| `Cmd+O` | Datei / Verzeichnis offnen |
| `Cmd+W` | Tab / Fenster schliessen |
| `Cmd+Shift+]` | Nachster Tab |
| `Cmd+Shift+[` | Vorheriger Tab |
| `Ctrl+Tab` | Nachster Tab |
| `Cmd+Q` | Beenden |

## Screenshots

### Hellmodus
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Hellmodus" width="600">
</p>

### Dunkelmodus
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Dunkelmodus" width="600">
</p>

## Funktionsweise

MDPreview verwendet eine minimale SwiftUI-Shell mit einer `WKWebView` zum Rendern. Die Rendering-Pipeline ist:

```
Markdown-Datei auf der Festplatte
  -> Swift liest Dateiinhalt
    -> Ubergibt an WKWebView
      -> marked.js konvertiert zu HTML (GFM)
        -> highlight.js farbt Code-Bloecke ein
          -> CSS-Stile fur Dunkel-/Hellmodus
```

Dateianderungen werden mit `DispatchSource`-Dateisystemuberwachung von GCD erkannt, mit Debouncing fur schnelle Speichervorgange.

## Architektur

```
Sources/
├── MDPreviewCore/            # Core-Bibliothek
│   ├── MDPreviewApp.swift    # SwiftUI App-Szene + Befehle
│   ├── AppDelegate.swift     # Finder/CLI-Integration
│   ├── Workspace.swift       # Tab-Verwaltung + Status
│   ├── MainView.swift        # Layout: Seitenleiste + Tabs + Vorschau
│   ├── FileTree.swift        # Verzeichnisbaum-Modell + Ansicht
│   ├── MarkdownWebView.swift # WKWebView-Wrapper
│   ├── FileWatcher.swift     # DispatchSource-Dateimonitor
│   ├── CLIInstaller.swift    # Kommandozeilen-Tool-Installer
│   └── Resources/
│       ├── template.html     # HTML-Rendering-Shell
│       ├── marked.min.js     # Markdown-Parser (GFM)
│       ├── highlight.min.js  # Syntax-Hervorhebung
│       └── *.css             # GitHub-Stil-Themes
└── MDPreview/
    └── main.swift            # Einstiegspunkt
```

## Voraussetzungen

- macOS 13.0 (Ventura) oder neuer
- Apple Silicon oder Intel Mac

### Build-Voraussetzungen

- Xcode 15.0+ oder Swift 5.9+ Toolchain
- Keine zusatzlichen Abhangigkeiten erforderlich

## Mitwirken

Beitrage sind willkommen! Siehe [CONTRIBUTING.md](CONTRIBUTING.md) fur Richtlinien.

Bitte beachten Sie, dass dieses Projekt einem [Verhaltenskodex](CODE_OF_CONDUCT.md) folgt.

## Sicherheit

Um eine Sicherheitslucke zu melden, lesen Sie bitte unsere [Sicherheitsrichtlinie](SECURITY.md).

## Danksagungen

- [marked.js](https://github.com/markedjs/marked) - Markdown-Parser
- [highlight.js](https://github.com/highlightjs/highlight.js) - Syntax-Hervorhebung
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UX-Inspiration

## Lizenz

[MIT-Lizenz](LICENSE) - siehe [LICENSE](LICENSE) fur Details.
