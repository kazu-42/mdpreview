import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @ObservedObject public var document: MarkdownDocument
    @State private var isDragOver = false

    public init(document: MarkdownDocument) {
        self.document = document
    }

    public var body: some View {
        Group {
            if document.fileURL != nil {
                MarkdownWebView(markdownContent: document.markdownContent)
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .navigationTitle(document.displayName)
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(dragOverlay)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }

    @ViewBuilder
    private var dragOverlay: some View {
        if isDragOver {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                .background(Color.accentColor.opacity(0.08))
                .padding(8)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            let ext = url.pathExtension.lowercased()
            guard ["md", "markdown", "mdown", "mkd", "txt"].contains(ext) else { return }
            DispatchQueue.main.async {
                document.open(url: url)
            }
        }
        return true
    }
}

public struct EmptyStateView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.secondary)
            Text("Drop a Markdown file here")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("or press Cmd+O to open")
                .font(.callout)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
