# Session Context

## User Prompts

### Prompt 1

Implement the following plan:

# MDPreview v1.2.3 Fix Plan

## Context

User reported issues with v1.2.2:
1. `mdpreview --version` not working
2. `mdpreview --help` blocking the terminal
3. `mdpreview README.md` should exit immediately after opening app (non-blocking)
4. Images not loading from relative paths in markdown

## Problem Analysis

### Issue 1 & 2: CLI Options

The CLI script at `Supporting/mdpreview` appears correct:
- `show_help()` and `show_version()` both call `exit 0`
- The op...

### Prompt 2

もうリリースした？

### Prompt 3

タブの問題は修正した？

### Prompt 4

現状のtabの実装教えてほしい。あと、markdown内のリンクにとべない問題あった。

### Prompt 5

終わったら、リリースして。

### Prompt 6

ci落ちた？

### Prompt 7

brew upgrade mdpreviewして試す

### Prompt 8

-------------------------------------
Translated Report (Full Report Below)
-------------------------------------
Process:             MDPreview [67522]
Path:                /Applications/MDPreview.app/Contents/MacOS/MDPreview
Identifier:          dev.kazu42.mdpreview
Version:             1.2.3 (1.2.3)
Code Type:           ARM-64 (Native)
Role:                Foreground
Parent Process:      launchd [1]
Coalition:           dev.kazu42.mdpreview [36341]
User ID:             502

Date/Time:     ...

