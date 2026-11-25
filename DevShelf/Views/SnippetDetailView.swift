import SwiftUI
import SwiftData
import AppKit

struct SnippetDetailView: View {

    @Bindable var snippet: Snippet
    
    @AppStorage("editor.autoIndent")
    private var autoIndent = true

    @AppStorage("editor.autoPair")
    private var autoPair = true
    
    @Query(sort: \SnippetCollection.sortOrder)
    private var collections: [SnippetCollection]

    @Query
    private var allSnippets: [Snippet]

    private var availableTags: [String] {
        Array(
            Set(
                allSnippets
                    .filter { !$0.isDeleted }
                    .flatMap(\.tags)
            )
        )
        .sorted()
    }

    @AppStorage("editor.fontSize")
    private var editorFontSize: Double = 13

    @AppStorage("editor.showLineNumbers")
    private var showLineNumbers = true

    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    private let languages = [
        "Plain Text",
        "Shell",
        "Swift",
        "JavaScript",
        "TypeScript",
        "Python",
        "Go",
        "Rust",
        "SQL",
        "JSON",
        "YAML",
        "HTML",
        "CSS",
        "Dockerfile",
        "Markdown"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            titleBar

            HStack(spacing: 20) {

                languagePicker

                collectionPicker

                Spacer(minLength: 0)
            }

            TagEditor(
                tags: $snippet.tags,
                availableTags: availableTags
            )

            notesEditor

            codeBlock
        }
        .padding(20)
        .disabled(snippet.isDeleted)
        .onChange(of: snippet.title) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.code) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.notes) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.language) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.tags) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.collection?.id) {
            snippet.updatedAt = Date()
        }
        .onChange(of: snippet.id) {
            copyResetTask?.cancel()
            copied = false
        }
        .onDisappear {
            copyResetTask?.cancel()
        }
    }
    
    // MARK: - Collection Picker

    private var collectionPicker: some View {

        Picker(
            "Collection",
            selection: Binding<UUID?>(
                get: {
                    snippet.collection?.id
                },
                set: { id in

                    let collection = collections.first {
                        $0.id == id
                    }

                    SnippetService.move(
                        snippet,
                        to: collection
                    )
                }
            )
        ) {

            Text("Unfiled")
                .tag(nil as UUID?)

            ForEach(collections) { collection in

                Label(
                    collection.name,
                    systemImage: collection.icon
                )
                .tag(Optional(collection.id))
            }
        }
        .frame(maxWidth: 240)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            TextField(
                "Snippet title",
                text: $snippet.title
            )
            .font(.title2.bold())
            .textFieldStyle(.plain)

            Button {
                snippet.isFavorite.toggle()
            } label: {
                Image(
                    systemName: snippet.isFavorite
                        ? "star.fill"
                        : "star"
                )
                .foregroundStyle(
                    snippet.isFavorite
                        ? Color.yellow
                        : Color.secondary
                )
            }
            .buttonStyle(.plain)
            .help(
                snippet.isFavorite
                    ? "Remove from Favorites"
                    : "Add to Favorites"
            )
        }
    }

    // MARK: - Language Picker

    private var languagePicker: some View {
        Picker(
            "Language",
            selection: $snippet.language
        ) {
            ForEach(languages, id: \.self) {
                Text($0)
                    .tag($0)
            }
        }
        .frame(maxWidth: 240)
    }

    // MARK: - Notes Editor

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            TextEditor(text: $snippet.notes)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(6)
                .frame(height: 80)
                .background(
                    Color.secondary.opacity(0.04)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 6)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            Color.secondary.opacity(0.15)
                        )
                }
        }
    }

    // MARK: - Code Block

    private var codeBlock: some View {
        VStack(spacing: 0) {

            codeToolbar

            Divider()

            CodeEditor(
                text: $snippet.code,
                language: snippet.language,
                fontSize: CGFloat(editorFontSize),
                showLineNumbers: showLineNumbers,
                autoIndent: autoIndent,
                autoPair: autoPair
            )
            .id(snippet.id)
            .frame(minHeight: 200)
            .frame(maxHeight: .infinity)

            Divider()

            codeStatusBar
        }
        .background(
            Color.secondary.opacity(0.04)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    Color.secondary.opacity(0.15)
                )
        }
    }

    // MARK: - Code Toolbar

    private var codeToolbar: some View {
        HStack(spacing: 8) {

            Image(
                systemName: "chevron.left.forwardslash.chevron.right"
            )

            Text(snippet.language)

            Spacer()

            Button {
                showLineNumbers.toggle()
            } label: {
                Image(systemName: "list.number")
                    .foregroundStyle(
                        showLineNumbers
                            ? Color.primary
                            : Color.secondary
                    )
            }
            .help("Toggle Line Numbers")

            Divider()
                .frame(height: 14)

            Button {
                editorFontSize = max(
                    10,
                    editorFontSize - 1
                )
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .disabled(editorFontSize <= 10)
            .help("Decrease Font Size")

            Text("\(Int(editorFontSize))")
                .monospacedDigit()
                .frame(width: 20)

            Button {
                editorFontSize = min(
                    28,
                    editorFontSize + 1
                )
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .disabled(editorFontSize >= 28)
            .help("Increase Font Size")

            Divider()
                .frame(height: 14)

            Button(action: copyCode) {
                Label(
                    copied ? "Copied" : "Copy",
                    systemImage: copied
                        ? "checkmark"
                        : "document.on.document"
                )
                .frame(minWidth: 65)
            }
            .help("Copy Code")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.secondary.opacity(0.06)
        )
    }

    // MARK: - Code Status Bar

    private var codeStatusBar: some View {
        HStack(spacing: 14) {

            Text(snippet.language)

            Spacer()

            Text("\(lineCount) lines")

            Text("\(snippet.code.count) characters")

            Text("UTF-8")

            Text("Spaces: 4")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    // MARK: - Helpers

    private var lineCount: Int {
        snippet.code.components(
            separatedBy: "\n"
        ).count
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()

        let success = NSPasteboard.general.setString(
            snippet.code,
            forType: .string
        )

        guard success else {
            return
        }

        copied = true

        copyResetTask?.cancel()

        copyResetTask = Task { @MainActor in
            try? await Task.sleep(
                for: .seconds(2)
            )

            guard !Task.isCancelled else {
                return
            }

            copied = false
        }
    }
}
