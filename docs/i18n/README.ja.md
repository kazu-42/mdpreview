# MDPreview

macOS向けの軽量・高速なMarkdownプレビューアプリ。ターミナルから`plan.md`、`README.md`などのMarkdownファイルを素早くプレビューしたい開発者のために作られました。

[English](../../README.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## 機能

- **高速起動** - ネイティブmacOSアプリ、瞬時に開く
- **完全なGFM対応** - テーブル、タスクリスト、取り消し線、自動リンク
- **シンタックスハイライト** - [highlight.js](https://highlightjs.org/)による40以上のプログラミング言語に対応
- **ライブリロード** - ファイルが変更されると自動的に更新
- **タブ** - 複数のファイルをタブで開き、Cmd+Shift+] / [ で切り替え
- **ファイルツリーサイドバー** - ディレクトリを開いてMarkdownファイルをブラウズ・プレビュー
- **ダーク/ライトモード** - macOSのシステム外観に追従
- **CLIフレンドリー** - `mdpreview file.md`で瞬時に起動、ターミナルに戻る
- **依存関係ゼロ** - 外部Swiftパッケージなし
- **軽量** - ~200KBのバイナリ + ~160KBのバンドルJS/CSS

## インストール

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### ダウンロード

[Releases](https://github.com/kazu-42/mdpreview/releases)ページから最新の`.dmg`または`.zip`をダウンロードしてください。

インストール後、アプリを開いて**MDPreview > Install Command Line Tool...**を選択し、`mdpreview`コマンドをセットアップしてください。

### ソースからビルド

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

## 使い方

### ターミナルから

```bash
# Markdownファイルを開く
mdpreview README.md

# 複数のファイルをタブで開く
mdpreview file1.md file2.md

# ファイルツリーサイドバー付きでディレクトリを開く
mdpreview .
mdpreview ~/projects/my-app/

# 引数なしでアプリを起動
mdpreview
```

### Finderから

- `.md`ファイルをMDPreviewウィンドウまたはDockアイコンに**ドラッグ＆ドロップ**
- `.md`ファイルを**右クリック** > このアプリケーションで開く > MDPreview
- メニューから**Cmd+O**でファイルまたはディレクトリを開く

### キーボードショートカット

| ショートカット | アクション |
|----------|--------|
| `Cmd+O` | ファイル / ディレクトリを開く |
| `Cmd+W` | タブ / ウィンドウを閉じる |
| `Cmd+Shift+]` | 次のタブ |
| `Cmd+Shift+[` | 前のタブ |
| `Ctrl+Tab` | 次のタブ |
| `Cmd+1` - `Cmd+9` | タブ 1-9 に移動 |
| `Cmd+Q` | 終了 |

## スクリーンショット

### ライトモード
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Light Mode" width="600">
</p>

### ダークモード
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Dark Mode" width="600">
</p>

## 仕組み

MDPreviewは、レンダリング用の`WKWebView`を備えた最小限のSwiftUIシェルを使用しています。レンダリングパイプラインは次のとおりです：

```
Markdown file on disk
  → Swift reads file content
    → Passes to WKWebView
      → marked.js converts to HTML (GFM)
        → highlight.js colorizes code blocks
          → CSS styles for dark/light mode
```

ファイルの変更はGCDの`DispatchSource`ファイルシステムモニタリングで検出し、急速な保存を処理するためのデバウンス処理を行っています。

## アーキテクチャ

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

## 動作環境

- macOS 13.0 (Ventura) 以降
- Apple SiliconまたはIntel Mac

### ビルド要件

- Xcode 15.0+ または Swift 5.9+ ツールチェーン
- 追加の依存関係は不要

## コントリビュート

コントリビュートを歓迎します！ガイドラインは[CONTRIBUTING.md](CONTRIBUTING.md)をご覧ください。

このプロジェクトは[行動規範](CODE_OF_CONDUCT.md)に従っています。

## セキュリティ

セキュリティ脆弱性を報告する場合は、[セキュリティポリシー](SECURITY.md)をご覧ください。

## 謝辞

- [marked.js](https://github.com/markedjs/marked) - Markdownパーサー
- [highlight.js](https://github.com/highlightjs/highlight.js) - シンタックスハイライト
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UXのインスピレーション

## ライセンス

[MIT License](LICENSE) - 詳細は[LICENSE](LICENSE)をご覧ください。
