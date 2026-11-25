import SwiftUI
import SwiftData
import AppKit

struct MenuBarView: View {

    @EnvironmentObject
    private var appState: AppState

    @Environment(\.openSettings)
    private var openSettings

    @Query(sort: \Snippet.updatedAt, order: .reverse)
    private var snippets: [Snippet]

    private var favorites: [Snippet] {

        Array(
            snippets.filter {

                $0.isFavorite &&
                !$0.isDeleted

            }
            .prefix(10)
        )
    }

    private var recent: [Snippet] {

        Array(
            snippets.filter {

                !$0.isDeleted

            }
            .prefix(10)
        )
    }

    var body: some View {

        Button {

            appState.showQuickSearch()

        } label: {

            Text(
                "Quick Search    \(appState.shortcut.title)"
            )
        }

        Button("Show DevShelf") {

            appState.showMainWindow()
        }

        Button("Hide DevShelf") {

            appState.hideMainWindow()
        }

        Divider()

        Menu("Favorites") {

            if favorites.isEmpty {

                Text("No Favorites")

            } else {

                ForEach(favorites) { snippet in

                    snippetMenu(snippet)
                }
            }
        }

        Menu("Recent Snippets") {

            if recent.isEmpty {

                Text("No Recent Snippets")

            } else {

                ForEach(recent) { snippet in

                    snippetMenu(snippet)
                }
            }
        }

        Divider()

        Toggle(
            "Menu Bar Only",
            isOn: $appState.menuBarOnly
        )
        
        Menu("Developer Utilities") {

            ForEach(
                DeveloperUtility.allCases
            ) { utility in

                Button {

                    appState.openUtility(utility)

                } label: {

                    Label(
                        utility.title,
                        systemImage: utility.icon
                    )
                }
            }
        }

        Divider()

        Button("Settings...") {

            NSApp.activate(ignoringOtherApps: true)

            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit DevShelf") {

            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    @ViewBuilder
    private func snippetMenu(
        _ snippet: Snippet
    ) -> some View {

        Menu(
            snippet.title.isEmpty
                ? "Untitled Snippet"
                : snippet.title
        ) {

            Button("Copy Code") {

                ClipboardService.copyCode(snippet)
            }

            Button("Copy Notes") {

                ClipboardService.copyNotes(snippet)
            }
            .disabled(snippet.notes.isEmpty)

            Button("Open in DevShelf") {

                appState.openSnippet(snippet.id)
            }
        }
    }
}
