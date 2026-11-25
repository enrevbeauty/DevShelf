import SwiftUI
import SwiftData

struct SidebarView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \SnippetCollection.sortOrder)
    private var collections: [SnippetCollection]

    @Query
    private var snippets: [Snippet]

    @Binding var selection: SidebarSelection?

    @State private var showingNewCollection = false

    @State private var editingCollection: SnippetCollection?

    @State private var deletingCollection: SnippetCollection?

    @State private var showingDeleteConfirmation = false

    @State private var showingEmptyTrashConfirmation = false

    @State private var draggingCollectionID: UUID?

    private var activeSnippets: [Snippet] {
        snippets.filter {
            !$0.isDeleted
        }
    }

    private var trashedSnippets: [Snippet] {
        snippets.filter {
            $0.isDeleted
        }
    }

    private var allTags: [String] {
        Array(
            Set(
                activeSnippets.flatMap(\.tags)
            )
        )
        .sorted()
    }

    var body: some View {
        List(selection: $selection) {

            librarySection

            collectionsSection

            tagsSection

            utilitiesSection
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showingNewCollection) {
            CollectionEditorView(
                collection: nil
            ) { collection in
                selection = .collection(collection.id)
            }
        }
        .sheet(item: $editingCollection) { collection in
            CollectionEditorView(
                collection: collection
            )
        }
        .confirmationDialog(
            "Delete Collection?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Collection",
                role: .destructive
            ) {
                deleteCollection()
            }

            Button("Cancel", role: .cancel) {
                deletingCollection = nil
            }

        } message: {
            Text(
                "Snippets in this collection will be moved to Unfiled."
            )
        }
        .confirmationDialog(
            "Empty Trash?",
            isPresented: $showingEmptyTrashConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Permanently Delete All",
                role: .destructive
            ) {
                SnippetService.emptyTrash(
                    snippets: snippets,
                    in: modelContext
                )
            }

            Button("Cancel", role: .cancel) {}

        } message: {
            Text(
                "All trashed snippets will be permanently deleted. This cannot be undone."
            )
        }
    }
    
    // MARK: - Utilities

    private var utilitiesSection: some View {

        Section("Utilities") {

            ForEach(
                DeveloperUtility.allCases
            ) { utility in

                sidebarRow(
                    title: utility.title,
                    icon: utility.icon
                )
                .tag(
                    SidebarSelection.utility(utility)
                )
            }
        }
    }

    // MARK: - Library

    private var librarySection: some View {
        Section("Library") {

            sidebarRow(
                title: "All Snippets",
                icon: "tray",
                count: activeSnippets.count
            )
            .tag(SidebarSelection.all)

            sidebarRow(
                title: "Favorites",
                icon: "star",
                count: activeSnippets.filter {
                    $0.isFavorite
                }.count
            )
            .tag(SidebarSelection.favorites)

            sidebarRow(
                title: "Recent",
                icon: "clock"
            )
            .tag(SidebarSelection.recent)

            sidebarRow(
                title: "Unfiled",
                icon: "tray.full",
                count: activeSnippets.filter {
                    $0.collection == nil
                }.count
            )
            .tag(SidebarSelection.unfiled)
            .dropDestination(for: String.self) { items, _ in
                moveSnippets(
                    items,
                    to: nil
                )
            }

            sidebarRow(
                title: "Trash",
                icon: "trash",
                count: trashedSnippets.count
            )
            .tag(SidebarSelection.trash)
            .contextMenu {
                Button(
                    "Empty Trash",
                    role: .destructive
                ) {
                    showingEmptyTrashConfirmation = true
                }
                .disabled(trashedSnippets.isEmpty)
            }
        }
    }

    // MARK: - Collections

    private var collectionsSection: some View {
        Section {

            ForEach(collections) { collection in
                collectionRow(collection)
            }

        } header: {
            HStack {
                Text("Collections")

                Spacer()

                Button {
                    showingNewCollection = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("New Collection")
            }
        }
    }

    private func collectionRow(
        _ collection: SnippetCollection
    ) -> some View {

        sidebarRow(
            title: collection.name,
            icon: collection.icon,
            count: activeSnippets.filter {
                $0.collection?.id == collection.id
            }.count
        )
        .tag(
            SidebarSelection.collection(collection.id)
        )
        .draggable(
            "collection:\(collection.id.uuidString)"
        )
        .dropDestination(for: String.self) { items, _ in

            if let item = items.first,
               item.hasPrefix("collection:") {

                return reorderCollection(
                    item,
                    before: collection
                )
            }

            return moveSnippets(
                items,
                to: collection
            )
        }
        .contextMenu {

            Button("Rename Collection") {
                editingCollection = collection
            }

            Button("Change Icon") {
                editingCollection = collection
            }

            Divider()

            Button(
                "Delete Collection",
                role: .destructive
            ) {
                deletingCollection = collection
                showingDeleteConfirmation = true
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        Section("Tags") {

            if allTags.isEmpty {
                Text("No tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(allTags, id: \.self) { tag in

                sidebarRow(
                    title: tag,
                    icon: "tag",
                    count: activeSnippets.filter {
                        $0.tags.contains(tag)
                    }.count
                )
                .tag(
                    SidebarSelection.tag(tag)
                )
            }
        }
    }

    // MARK: - Row

    private func sidebarRow(
        title: String,
        icon: String,
        count: Int? = nil
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .frame(width: 18)
                .foregroundStyle(Color.accentColor)

            Text(title)
                .lineLimit(1)

            Spacer()

            if let count, count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    // MARK: - Move Snippets

    private func moveSnippets(
        _ items: [String],
        to collection: SnippetCollection?
    ) -> Bool {

        var moved = false

        for item in items {

            guard item.hasPrefix("snippet:") else {
                continue
            }

            let value = String(
                item.dropFirst("snippet:".count)
            )

            guard let id = UUID(uuidString: value),
                  let snippet = snippets.first(
                    where: { $0.id == id }
                  ),
                  !snippet.isDeleted
            else {
                continue
            }

            SnippetService.move(
                snippet,
                to: collection
            )

            moved = true
        }

        return moved
    }

    // MARK: - Reorder Collections

    private func reorderCollection(
        _ item: String,
        before target: SnippetCollection
    ) -> Bool {

        let value = String(
            item.dropFirst("collection:".count)
        )

        guard let id = UUID(uuidString: value),
              id != target.id,
              let source = collections.first(
                where: { $0.id == id }
              )
        else {
            return false
        }

        var ordered = collections

        ordered.removeAll {
            $0.id == source.id
        }

        guard let targetIndex = ordered.firstIndex(
            where: { $0.id == target.id }
        ) else {
            return false
        }

        ordered.insert(
            source,
            at: targetIndex
        )

        for (index, collection) in ordered.enumerated() {
            collection.sortOrder = index
        }

        return true
    }

    // MARK: - Delete Collection

    private func deleteCollection() {

        guard let collection = deletingCollection else {
            return
        }

        if selection == .collection(collection.id) {
            selection = .unfiled
        }

        modelContext.delete(collection)

        deletingCollection = nil
    }
}
