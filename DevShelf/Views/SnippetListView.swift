import SwiftUI
import SwiftData

enum SnippetSortOption: String, CaseIterable, Identifiable {

    case updated = "Last Modified"
    case created = "Date Created"
    case title = "Title"
    case language = "Language"

    var id: String {
        rawValue
    }
}

struct SnippetListView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \SnippetCollection.sortOrder)
    private var collections: [SnippetCollection]

    let snippets: [Snippet]

    let section: SidebarSelection?

    @Binding var selection: Snippet?

    let onCreate: () -> Void

    @State private var searchText = ""

    @AppStorage("library.sortOption")
    private var sortOption: SnippetSortOption = .updated

    @AppStorage("library.sortAscending")
    private var sortAscending = false

    @State private var pendingDeletion: Snippet?

    @State private var showingDeleteConfirmation = false

    private var filteredSnippets: [Snippet] {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let filtered = snippets.filter { snippet in

            guard query.isEmpty == false else {
                return true
            }

            return snippet.title
                .localizedCaseInsensitiveContains(query) ||

                snippet.code
                .localizedCaseInsensitiveContains(query) ||

                snippet.notes
                .localizedCaseInsensitiveContains(query) ||

                snippet.language
                .localizedCaseInsensitiveContains(query) ||

                snippet.tags.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
        }

        return filtered.sorted { lhs, rhs in

            switch sortOption {

            case .updated:
                if lhs.updatedAt != rhs.updatedAt {
                    return sortAscending
                        ? lhs.updatedAt < rhs.updatedAt
                        : lhs.updatedAt > rhs.updatedAt
                }

            case .created:
                if lhs.createdAt != rhs.createdAt {
                    return sortAscending
                        ? lhs.createdAt < rhs.createdAt
                        : lhs.createdAt > rhs.createdAt
                }

            case .title:
                let comparison = lhs.title
                    .localizedStandardCompare(rhs.title)

                if comparison != .orderedSame {
                    return sortAscending
                        ? comparison == .orderedAscending
                        : comparison == .orderedDescending
                }

            case .language:
                let comparison = lhs.language
                    .localizedStandardCompare(rhs.language)

                if comparison != .orderedSame {
                    return sortAscending
                        ? comparison == .orderedAscending
                        : comparison == .orderedDescending
                }
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            header

            Divider()

            if filteredSnippets.isEmpty {

                emptyState

            } else {

                List(
                    filteredSnippets,
                    selection: $selection
                ) { snippet in

                    snippetRow(snippet)
                        .tag(snippet)
                        .draggable(
                            "snippet:\(snippet.id.uuidString)"
                        )
                        .contextMenu {
                            snippetContextMenu(snippet)
                        }
                }
                .listStyle(.plain)
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search snippets"
        )
        .onChange(of: section) {
            searchText = ""
        }
        .confirmationDialog(
            "Permanently Delete Snippet?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Permanently",
                role: .destructive
            ) {
                permanentlyDelete()
            }

            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }

        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {

            Text("\(filteredSnippets.count) snippets")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            sortMenu

            Button(action: onCreate) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("n", modifiers: .command)
            .disabled(section == .trash)
            .help("New Snippet")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {

            Picker(
                "Sort By",
                selection: $sortOption
            ) {
                ForEach(SnippetSortOption.allCases) {
                    option in

                    Text(option.rawValue)
                        .tag(option)
                }
            }

            Divider()

            Picker(
                "Order",
                selection: $sortAscending
            ) {
                Text("Ascending")
                    .tag(true)

                Text("Descending")
                    .tag(false)
            }

        } label: {
            Image(
                systemName: "arrow.up.arrow.down"
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sort Snippets")
    }

    // MARK: - Snippet Row

    private func snippetRow(
        _ snippet: Snippet
    ) -> some View {

        VStack(alignment: .leading, spacing: 5) {

            HStack(spacing: 6) {

                Image(
                    systemName: "chevron.left.forwardslash.chevron.right"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    snippet.title.isEmpty
                        ? "Untitled Snippet"
                        : snippet.title
                )
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)

                Spacer()

                if snippet.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            HStack(spacing: 5) {

                Text(snippet.language)

                if let collection = snippet.collection {

                    Text("·")

                    Text(collection.name)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !snippet.code.isEmpty {
                Text(codePreview(snippet.code))
                    .font(.system(
                        size: 11,
                        design: .monospaced
                    ))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {

                if !snippet.tags.isEmpty {
                    Text(
                        snippet.tags
                            .prefix(3)
                            .joined(separator: " · ")
                    )
                    .lineLimit(1)
                }

                Spacer()

                Text(
                    snippet.updatedAt,
                    style: .relative
                )
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func snippetContextMenu(
        _ snippet: Snippet
    ) -> some View {

        if snippet.isDeleted {

            Button("Restore") {
                SnippetService.restore(snippet)

                if selection?.id == snippet.id {
                    selection = nil
                }
            }

            Divider()

            Button(
                "Delete Permanently",
                role: .destructive
            ) {
                pendingDeletion = snippet
                showingDeleteConfirmation = true
            }

        } else {

            Button(
                snippet.isFavorite
                    ? "Remove from Favorites"
                    : "Add to Favorites"
            ) {
                SnippetService.toggleFavorite(snippet)
            }

            Button("Duplicate") {
                let copy = SnippetService.duplicate(
                    snippet,
                    in: modelContext
                )

                selection = copy
            }

            Button("Copy Code") {
                NSPasteboard.general.clearContents()

                NSPasteboard.general.setString(
                    snippet.code,
                    forType: .string
                )
            }

            Divider()

            Menu("Move to Collection") {

                Button("Unfiled") {
                    SnippetService.move(
                        snippet,
                        to: nil
                    )
                }

                if !collections.isEmpty {
                    Divider()
                }

                ForEach(collections) { collection in

                    Button {
                        SnippetService.move(
                            snippet,
                            to: collection
                        )
                    } label: {
                        Label(
                            collection.name,
                            systemImage: collection.icon
                        )
                    }
                    .disabled(
                        snippet.collection?.id == collection.id
                    )
                }
            }

            Divider()

            Button(
                "Move to Trash",
                role: .destructive
            ) {
                SnippetService.moveToTrash(snippet)

                if selection?.id == snippet.id {
                    selection = nil
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {

            Label(
                searchText.isEmpty
                    ? "No Snippets"
                    : "No Results",
                systemImage: searchText.isEmpty
                    ? "tray"
                    : "magnifyingglass"
            )

        } description: {

            Text(
                searchText.isEmpty
                    ? "Snippets will appear here."
                    : "Try a different search."
            )

        } actions: {

            if searchText.isEmpty,
               section != .trash {

                Button("New Snippet") {
                    onCreate()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Helpers

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

    private func permanentlyDelete() {

        guard let snippet = pendingDeletion else {
            return
        }

        if selection?.id == snippet.id {
            selection = nil
        }

        SnippetService.permanentlyDelete(
            snippet,
            in: modelContext
        )

        pendingDeletion = nil
    }
}
