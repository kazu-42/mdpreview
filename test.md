# MDPreview Test

This is a **test document** for the MDPreview app.

## Features

### Task Lists
- [x] Markdown rendering
- [x] Dark/light mode
- [x] File watching
- [ ] Syntax highlighting
- [ ] Table support

### Code Blocks

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .padding()
    }
}
```

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)
```

### Tables

| Feature | Status | Priority |
|---------|--------|----------|
| Markdown rendering | Done | High |
| File watching | Done | High |
| Syntax highlighting | Done | Medium |
| CLI support | Done | Medium |

### Blockquote

> This is a blockquote with **bold** and *italic* text.
>
> It can span multiple lines.

### Links

[GitHub](https://github.com) | [Apple Developer](https://developer.apple.com)

---

*Built with SwiftUI + WKWebView + marked.js*
