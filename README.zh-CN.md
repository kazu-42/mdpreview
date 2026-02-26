# MDPreview

一款轻量、快速的 macOS Markdown 预览应用。专为需要从终端快速预览 `plan.md`、`README.md` 及其他 Markdown 文件的开发者打造。

[English](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## 功能特性

- **快速启动** - 原生 macOS 应用，即时打开
- **完整 GFM 支持** - 表格、任务列表、删除线、自动链接
- **语法高亮** - 通过 [highlight.js](https://highlightjs.org/) 支持 40+ 种编程语言
- **实时重载** - 文件在磁盘上更改时自动刷新
- **标签页** - 以标签页形式打开多个文件，使用 Cmd+Shift+] / [ 切换
- **文件树侧边栏** - 打开目录以浏览和预览 Markdown 文件
- **深色/浅色模式** - 跟随 macOS 系统外观
- **CLI 友好** - `mdpreview file.md` 即时启动，返回终端
- **零依赖** - 无外部 Swift 包依赖
- **轻量级** - 约 200KB 二进制文件 + 约 160KB 内置 JS/CSS

## 安装

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### 下载

从 [Releases](https://github.com/kazu-42/mdpreview/releases) 页面下载最新的 `.dmg` 或 `.zip` 文件。

安装后，打开应用并前往 **MDPreview > Install Command Line Tool...** 设置 `mdpreview` 命令。

### 从源码构建

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# 构建并创建 .app 包
make all

# 安装到 /Applications
make install

# 安装 CLI（需要 sudo）
sudo make cli
```

## 使用方法

### 从终端

```bash
# 打开 Markdown 文件
mdpreview README.md

# 以标签页形式打开多个文件
mdpreview file1.md file2.md

# 打开目录并显示文件树侧边栏
mdpreview .
mdpreview ~/projects/my-app/

# 无参数启动应用
mdpreview
```

### 从 Finder

- **拖放** `.md` 文件到 MDPreview 窗口或 Dock 图标
- **右键点击** `.md` 文件 > 打开方式 > MDPreview
- 使用 **Cmd+O** 从菜单打开文件或目录

### 键盘快捷键

| 快捷键 | 操作 |
|--------|------|
| `Cmd+O` | 打开文件 / 目录 |
| `Cmd+W` | 关闭标签页 / 窗口 |
| `Cmd+Shift+]` | 下一个标签页 |
| `Cmd+Shift+[` | 上一个标签页 |
| `Ctrl+Tab` | 下一个标签页 |
| `Cmd+Q` | 退出 |

## 截图

### 浅色模式
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Light Mode" width="600">
</p>

### 深色模式
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Dark Mode" width="600">
</p>

## 工作原理

MDPreview 使用最小化的 SwiftUI 外壳配合 `WKWebView` 进行渲染。渲染流程为：

```
磁盘上的 Markdown 文件
  → Swift 读取文件内容
    → 传递给 WKWebView
      → marked.js 转换为 HTML（GFM）
        → highlight.js 为代码块着色
          → CSS 样式适配深色/浅色模式
```

文件更改通过 GCD 的 `DispatchSource` 文件系统监控检测，并带有防抖处理以应对快速保存。

## 架构

```
Sources/
├── MDPreviewCore/            # 核心库
│   ├── MDPreviewApp.swift    # SwiftUI App 场景 + 命令
│   ├── AppDelegate.swift     # Finder/CLI 集成
│   ├── Workspace.swift       # 标签页管理 + 状态
│   ├── MainView.swift        # 布局：侧边栏 + 标签页 + 预览
│   ├── FileTree.swift        # 目录树模型 + 视图
│   ├── MarkdownWebView.swift # WKWebView 包装器
│   ├── FileWatcher.swift     # DispatchSource 文件监控器
│   ├── CLIInstaller.swift    # 命令行工具安装器
│   └── Resources/
│       ├── template.html     # HTML 渲染外壳
│       ├── marked.min.js     # Markdown 解析器（GFM）
│       ├── highlight.min.js  # 语法高亮
│       └── *.css             # GitHub 风格主题
└── MDPreview/
    └── main.swift            # 入口点
```

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel Mac

### 构建要求

- Xcode 15.0+ 或 Swift 5.9+ 工具链
- 无需额外依赖

## 贡献

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解指南。

请注意本项目遵循 [行为准则](CODE_OF_CONDUCT.md)。

## 安全

如需报告安全漏洞，请参阅我们的 [安全政策](SECURITY.md)。

## 致谢

- [marked.js](https://github.com/markedjs/marked) - Markdown 解析器
- [highlight.js](https://github.com/highlightjs/highlight.js) - 语法高亮
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UX 灵感

## 许可证

[MIT License](LICENSE) - 详情请参阅 [LICENSE](LICENSE)。
