import SwiftUI
import SwiftData

struct QuickSearchView: View {

    @Query(sort: \Snippet.updatedAt, order: .reverse)
    private var snippets: [Snippet]

    @State private var searchText = ""

    @State private var selectedIndex = 0

    @FocusState private var searchFocused: Bool

    let onDismiss: () -> Void

    let onOpenSnippet: (UUID) -> Void

    private var activeSnippets: [Snippet] {
        snippets.filter {
            !$0.isDeleted
        }
    }

    private var results: [Snippet] {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if query.isEmpty {

            let favorites = activeSnippets.filter {
                $0.isFavorite
            }

            let recent = activeSnippets.filter {
                !$0.isFavorite
            }

            return Array(
                (favorites + recent).prefix(30)
            )
        }

        let terms = query.split(
            whereSeparator: \.isWhitespace
        )
        .map(String.init)

        let matches = activeSnippets.filter { snippet in

            let searchableText = [
                snippet.title,
                snippet.code,
                snippet.notes,
                snippet.language,
                snippet.collection?.name ?? "",
                snippet.tags.joined(separator: " ")
            ]
            .joined(separator: " ")

            return terms.allSatisfy { term in

                searchableText
                    .localizedCaseInsensitiveContains(term)
            }
        }

        return Array(
            matches.sorted { lhs, rhs in

                let lhsScore = relevanceScore(
                    lhs,
                    query: query
                )

                let rhsScore = relevanceScore(
                    rhs,
                    query: query
                )

                if lhsScore == rhsScore {
                    return lhs.updatedAt > rhs.updatedAt
                }

                return lhsScore > rhsScore
            }
            .prefix(50)
        )
    }

    private var selectedSnippet: Snippet? {

        guard results.indices.contains(selectedIndex) else {
            return nil
        }

        return results[selectedIndex]
    }

    var body: some View {

        VStack(spacing: 0) {

            searchBar

            Divider()

            if results.isEmpty {

                emptyState

            } else {

                resultsList
            }

            Divider()

            footer
        }
        .frame(width: 640, height: 440)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
        .overlay {

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    Color.secondary.opacity(0.20)
                )
        }
        .onAppear {
            searchFocused = true
        }
        .onChange(of: searchText) {
            selectedIndex = 0
        }
        .onChange(of: results.map(\.id)) {

            selectedIndex = min(
                selectedIndex,
                max(0, results.count - 1)
            )
        }
        .onKeyPress(.upArrow) {

            moveSelection(by: -1)

            return .handled
        }
        .onKeyPress(.downArrow) {

            moveSelection(by: 1)

            return .handled
        }
        .onKeyPress(.escape) {

            onDismiss()

            return .handled
        }
        .onKeyPress(
            keys: [.return],
            phases: .down
        ) { press in

            if press.modifiers.contains(.command) {

                openSelectedSnippet()

            } else {

                copySelectedSnippet()
            }

            return .handled
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {

        HStack(spacing: 14) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)

            TextField(
                "Search DevShelf...",
                text: $searchText
            )
            .font(.system(size: 23))
            .textFieldStyle(.plain)
            .focused($searchFocused)

            if !searchText.isEmpty {

                Button {

                    searchText = ""

                    searchFocused = true

                } label: {

                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("ESC")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(5)
                .background(
                    Color.secondary.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Results

    private var resultsList: some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(spacing: 2) {

                    HStack {

                        Text(
                            searchText.isEmpty
                                ? "Favorites & Recent"
                                : "\(results.count) Results"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    ForEach(
                        Array(results.enumerated()),
                        id: \.element.id
                    ) { index, snippet in

                        resultRow(
                            snippet,
                            selected: index == selectedIndex
                        )
                        .id(snippet.id)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {

                            selectedIndex = index

                            copySelectedSnippet()
                        }
                        .onTapGesture {

                            selectedIndex = index
                        }
                    }
                }
                .padding(8)
            }
            .onChange(of: selectedIndex) {

                guard let selectedSnippet else {
                    return
                }

                proxy.scrollTo(
                    selectedSnippet.id
                )
            }
        }
    }

    private func resultRow(
        _ snippet: Snippet,
        selected: Bool
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: "chevron.left.forwardslash.chevron.right"
            )
            .font(.system(size: 18))
            .foregroundStyle(
                selected
                    ? Color.accentColor
                    : Color.secondary
            )
            .frame(width: 36, height: 36)
            .background(
                Color.secondary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 7)
            )

            VStack(alignment: .leading, spacing: 4) {

                HStack(spacing: 6) {

                    Text(
                        snippet.title.isEmpty
                            ? "Untitled Snippet"
                            : snippet.title
                    )
                    .font(.system(
                        size: 13,
                        weight: .medium
                    ))
                    .lineLimit(1)

                    if snippet.isFavorite {

                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 5) {

                    Text(snippet.language)

                    if let collection = snippet.collection {

                        Text("·")

                        Text(collection.name)
                    }

                    if !snippet.tags.isEmpty {

                        Text("·")

                        Text(
                            snippet.tags
                                .prefix(3)
                                .joined(separator: ", ")
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if !snippet.code.isEmpty {

                    Text(codePreview(snippet.code))
                        .font(.system(
                            size: 11,
                            design: .monospaced
                        ))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if selected {

                Image(systemName: "return")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {

            RoundedRectangle(cornerRadius: 7)
                .fill(
                    selected
                        ? Color.accentColor.opacity(0.16)
                        : Color.clear
                )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)

            Text("No Snippets Found")
                .font(.headline)

            Text("Try a different search.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Footer

    private var footer: some View {

        HStack(spacing: 18) {

            shortcutHint(
                key: "↑ ↓",
                title: "Navigate"
            )

            shortcutHint(
                key: "↵",
                title: "Copy Code"
            )

            shortcutHint(
                key: "⌘ ↵",
                title: "Open"
            )

            Spacer()

            Text("DevShelf")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func shortcutHint(
        key: String,
        title: String
    ) -> some View {

        HStack(spacing: 5) {

            Text(key)
                .font(.system(
                    size: 10,
                    weight: .medium
                ))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    Color.secondary.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Search Ranking

    private func relevanceScore(
        _ snippet: Snippet,
        query: String
    ) -> Int {

        var score = 0

        if snippet.title
            .localizedCaseInsensitiveCompare(query)
            == .orderedSame {

            score += 100
        }

        if snippet.title.lowercased()
            .hasPrefix(query.lowercased()) {

            score += 50
        }

        if snippet.title
            .localizedCaseInsensitiveContains(query) {

            score += 30
        }

        if snippet.tags.contains(where: {

            $0.localizedCaseInsensitiveContains(query)

        }) {

            score += 20
        }

        if snippet.language
            .localizedCaseInsensitiveContains(query) {

            score += 10
        }

        if snippet.collection?.name
            .localizedCaseInsensitiveContains(query)
            == true {

            score += 10
        }

        if snippet.code
            .localizedCaseInsensitiveContains(query) {

            score += 5
        }

        if snippet.notes
            .localizedCaseInsensitiveContains(query) {

            score += 5
        }

        if snippet.isFavorite {
            score += 3
        }

        return score
    }

    // MARK: - Actions

    private func moveSelection(by offset: Int) {

        guard !results.isEmpty else {
            return
        }

        selectedIndex = min(
            max(0, selectedIndex + offset),
            results.count - 1
        )
    }

    private func copySelectedSnippet() {

        guard let selectedSnippet else {
            return
        }

        if ClipboardService.copyCode(selectedSnippet) {

            onDismiss()
        }
    }

    private func openSelectedSnippet() {

        guard let selectedSnippet else {
            return
        }

        onOpenSnippet(selectedSnippet.id)
    }

    private func codePreview(
        _ code: String
    ) -> String {

        code.components(separatedBy: .newlines)
            .map {

                $0.trimmingCharacters(
                    in: .whitespaces
                )
            }
            .first {
                !$0.isEmpty
            } ?? ""
    }
}
