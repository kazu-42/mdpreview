# MDPreview

macOS용 가볍고 빠른 Markdown 미리보기 앱입니다. 터미널에서 `plan.md`, `README.md` 및 기타 Markdown 파일을 빠르게 미리보기해야 하는 개발자를 위해 제작되었습니다.

[English](../../README.md) | [日本語](README.ja.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## 기능

- **빠른 시작** - 네이티브 macOS 앱으로 즉시 실행됩니다
- **완전한 GFM 지원** - 표, 작업 목록, 취소선, 자동 링크 지원
- **구문 강조** - [highlight.js](https://highlightjs.org/)를 통한 40개 이상의 프로그래밍 언어 지원
- **실시간 새로고침** - 파일이 디스크에서 변경되면 자동으로 갱신됩니다
- **탭** - 여러 파일을 탭으로 열고 Cmd+Shift+] / [로 전환
- **파일 트리 사이드바** - 디렉토리를 열어 Markdown 파일을 탐색하고 미리보기
- **다크/라이트 모드** - macOS 시스템 설정을 따릅니다
- **CLI 친화적** - `mdpreview file.md`로 즉시 실행, 터미널로 복귀
- **종속성 없음** - 외부 Swift 패키지 불필요
- **가벼운 용량** - ~200KB 바이너리 + ~160KB 번들 JS/CSS

## 설치

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### 다운로드

[Releases](https://github.com/kazu-42/mdpreview/releases) 페이지에서 최신 `.dmg` 또는 `.zip`을 다운로드하세요.

설치 후 앱을 열고 **MDPreview > Install Command Line Tool...**로 이동하여 `mdpreview` 명령을 설정하세요.

### 소스에서 빌드

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# 빌드 및 .app 번들 생성
make all

# /Applications에 설치
make install

# CLI 설치 (sudo 필요)
sudo make cli
```

## 사용법

### 터미널에서

```bash
# Markdown 파일 열기
mdpreview README.md

# 여러 파일을 탭으로 열기
mdpreview file1.md file2.md

# 파일 트리 사이드바와 함께 디렉토리 열기
mdpreview .
mdpreview ~/projects/my-app/

# 인자 없이 앱 실행
mdpreview
```

### Finder에서

- `.md` 파일을 MDPreview 창 또는 Dock 아이콘에 **드래그 앤 드롭**
- `.md` 파일을 **우클릭** > 열기 > MDPreview
- 메뉴에서 **Cmd+O**를 사용하여 파일 또는 디렉토리 열기

### 키보드 단축키

| 단축키 | 동작 |
|--------|------|
| `Cmd+O` | 파일 / 디렉토리 열기 |
| `Cmd+W` | 탭 / 창 닫기 |
| `Cmd+Shift+]` | 다음 탭 |
| `Cmd+Shift+[` | 이전 탭 |
| `Ctrl+Tab` | 다음 탭 |
| `Cmd+Q` | 종료 |

## 스크린샷

### 라이트 모드
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Light Mode" width="600">
</p>

### 다크 모드
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Dark Mode" width="600">
</p>

## 작동 방식

MDPreview는 렌더링을 위해 `WKWebView`가 포함된 최소한의 SwiftUI 셸을 사용합니다. 렌더링 파이프라인은 다음과 같습니다:

```
디스크의 Markdown 파일
  → Swift가 파일 내용 읽기
    → WKWebView로 전달
      → marked.js가 HTML로 변환 (GFM)
        → highlight.js가 코드 블록 색상화
          → 다크/라이트 모드용 CSS 스타일
```

파일 변경은 GCD의 `DispatchSource` 파일 시스템 모니터링을 사용하여 감지되며, 빠른 저장을 처리하기 위한 디바운싱이 적용됩니다.

## 아키텍처

```
Sources/
├── MDPreviewCore/            # 핵심 라이브러리
│   ├── MDPreviewApp.swift    # SwiftUI App 씬 + 명령
│   ├── AppDelegate.swift     # Finder/CLI 연동
│   ├── Workspace.swift       # 탭 관리 + 상태
│   ├── MainView.swift        # 레이아웃: 사이드바 + 탭 + 미리보기
│   ├── FileTree.swift        # 디렉토리 트리 모델 + 뷰
│   ├── MarkdownWebView.swift # WKWebView 래퍼
│   ├── FileWatcher.swift     # DispatchSource 파일 모니터
│   ├── CLIInstaller.swift    # 명령줄 도구 설치
│   └── Resources/
│       ├── template.html     # HTML 렌더링 셸
│       ├── marked.min.js     # Markdown 파서 (GFM)
│       ├── highlight.min.js  # 구문 강조
│       └── *.css             # GitHub 스타일 테마
└── MDPreview/
    └── main.swift            # 진입점
```

## 요구 사항

- macOS 13.0 (Ventura) 이상
- Apple Silicon 또는 Intel Mac

### 빌드 요구 사항

- Xcode 15.0+ 또는 Swift 5.9+ 툴체인
- 추가 종속성 불필요

## 기여

기여를 환영합니다! 가이드라인은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

이 프로젝트는 [Code of Conduct](CODE_OF_CONDUCT.md)를 따릅니다.

## 보안

보안 취약점을 보고하려면 [Security Policy](SECURITY.md)를 참조하세요.

## 감사의 말

- [marked.js](https://github.com/markedjs/marked) - Markdown 파서
- [highlight.js](https://github.com/highlightjs/highlight.js) - 구문 강조
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - UI/UX 영감

## 라이선스

[MIT License](LICENSE) - 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
