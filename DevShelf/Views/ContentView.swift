import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    
    @EnvironmentObject
    private var appState: AppState

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Snippet.updatedAt, order: .reverse)
    private var snippets: [Snippet]

    @Query(sort: \SnippetCollection.sortOrder)
    private var collections: [SnippetCollection]

    @State private var selectedSection: SidebarSelection? = .all

    @State private var selectedSnippet: Snippet?

    @State private var columnVisibility:
        NavigationSplitViewVisibility = .all

    private var sectionTitle: String {

        switch selectedSection {

        case .collection(let id):
            return collections.first {
                $0.id == id
            }?.name ?? "Collection"

        case .tag(let tag):
            return tag

        default:
            return selectedSection?.title ?? "DevShelf"
        }
    }

    private var filteredSnippets: [Snippet] {

        switch selectedSection {

        case .all, .none:
            return snippets.filter {
                !$0.isDeleted
            }

        case .favorites:
            return snippets.filter {
                !$0.isDeleted &&
                $0.isFavorite
            }

        case .recent:

            let cutoff = Calendar.current.date(
                byAdding: .day,
                value: -7,
                to: Date()
            ) ?? .distantPast

            return snippets.filter {
                !$0.isDeleted &&
                $0.updatedAt >= cutoff
            }

        case .unfiled:
            return snippets.filter {
                !$0.isDeleted &&
                $0.collection == nil
            }

        case .trash:
            return snippets.filter {
                $0.isDeleted
            }

        case .collection(let id):
            return snippets.filter {
                !$0.isDeleted &&
                $0.collection?.id == id
            }

        case .tag(let tag):
            return snippets.filter {
                !$0.isDeleted &&
                $0.tags.contains(tag)
            }
        }
    }

    private var visibleSnippetIDs: [UUID] {
        filteredSnippets.map(\.id)
    }

    var body: some View {

        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {

            SidebarView(
                selection: $selectedSection
            )
            .navigationSplitViewColumnWidth(
                min: 160,
                ideal: 200,
                max: 280
            )

        } content: {

            SnippetListView(
                snippets: filteredSnippets,
                section: selectedSection,
                selection: $selectedSnippet,
                onCreate: createSnippet
            )
            .navigationTitle(sectionTitle)
            .navigationSplitViewColumnWidth(
                min: 220,
                ideal: 280,
                max: 420
            )

        } detail: {

            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedSection) {
            validateSelection()
        }
        .onChange(of: visibleSnippetIDs) {
            validateSelection()
        }
        .onReceive(
            appState.$requestedSnippetID
        ) { id in

            guard let id else {
                return
            }

            openRequestedSnippet(id)
        }
        .background {

            MainWindowAccessor { window in

                window.isReleasedWhenClosed = false

                window.delegate = MainWindowDelegate.shared

                appState.mainWindow = window
            }
        }
    }
    
    // MARK: - External Snippet Selection

    private func openRequestedSnippet(
        _ id: UUID
    ) {

        guard let snippet = snippets.first(
            where: {
                $0.id == id &&
                !$0.isDeleted
            }
        ) else {
            return
        }

        selectedSection = .all

        selectedSnippet = snippet

        Task { @MainActor in

            await Task.yield()

            if appState.requestedSnippetID == id {

                appState.requestedSnippetID = nil
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {

        if let selectedSnippet {

            if selectedSnippet.isDeleted {

                VStack(spacing: 0) {

                    trashBanner(selectedSnippet)

                    Divider()

                    SnippetDetailView(
                        snippet: selectedSnippet
                    )
                }

            } else {

                SnippetDetailView(
                    snippet: selectedSnippet
                )
            }

        } else {

            ContentUnavailableView(
                "No Snippet Selected",
                systemImage:
                    "chevron.left.forwardslash.chevron.right",
                description: Text(
                    "Select or create a snippet."
                )
            )
        }
    }

    // MARK: - Trash Banner

    private func trashBanner(
        _ snippet: Snippet
    ) -> some View {

        HStack {

            Image(systemName: "trash")

            Text("This snippet is in the Trash.")

            Spacer()

            Button("Restore") {
                SnippetService.restore(snippet)
                selectedSnippet = nil
            }
            .buttonStyle(.bordered)
        }
        .font(.caption)
        .padding(12)
        .background(
            Color.orange.opacity(0.08)
        )
    }

    // MARK: - Create Snippet

    private func createSnippet() {

        guard selectedSection != .trash else {
            return
        }

        var collection: SnippetCollection?

        var favorite = false

        var tags: [String] = []

        switch selectedSection {

        case .collection(let id):
            collection = collections.first {
                $0.id == id
            }

        case .favorites:
            favorite = true

        case .tag(let tag):
            tags = [tag]

        default:
            break
        }

        let snippet = SnippetService.create(
            in: modelContext,
            collection: collection,
            favorite: favorite,
            tags: tags
        )

        selectedSnippet = snippet
    }

    // MARK: - Selection

    private func validateSelection() {

        guard let selectedSnippet else {
            return
        }

        let exists = filteredSnippets.contains {
            $0.id == selectedSnippet.id
        }

        if !exists {
            self.selectedSnippet = nil
        }
    }
    
    struct MainWindowAccessor: NSViewRepresentable {

        let onResolve: (NSWindow) -> Void

        func makeNSView(
            context: Context
        ) -> NSView {

            let view = NSView()

            DispatchQueue.main.async {

                if let window = view.window {

                    onResolve(window)
                }
            }

            return view
        }

        func updateNSView(
            _ nsView: NSView,
            context: Context
        ) {

            DispatchQueue.main.async {

                if let window = nsView.window {

                    onResolve(window)
                }
            }
        }
    }
}
