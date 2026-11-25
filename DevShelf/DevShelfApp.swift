import SwiftUI
import SwiftData
import AppKit

@main
struct DevShelfApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject
    private var appState = AppState.shared

    private let modelContainer: ModelContainer

    init() {

        do {

            modelContainer = try ModelContainer(
                for:
                    Snippet.self,
                    SnippetCollection.self
            )

        } catch {

            fatalError(
                "Failed to initialize SwiftData: \(error)"
            )
        }
    }

    var body: some Scene {

        Window(
            "DevShelf",
            id: "main"
        ) {

            ContentView()
                .environmentObject(appState)
                .modelContainer(modelContainer)
                .frame(
                    minWidth: 900,
                    minHeight: 550
                )
                .onAppear {

                    appState.configure(
                        container: modelContainer
                    )
                }
        }
        .defaultSize(
            width: 1200,
            height: 750
        )
        .commands {

            CommandGroup(
                replacing: .newItem
            ) {}
        }

        MenuBarExtra {

            MenuBarView()
                .environmentObject(appState)
                .modelContainer(modelContainer)

        } label: {

            Image(
                systemName: "chevron.left.forwardslash.chevron.right"
            )
        }
        .menuBarExtraStyle(.menu)

        Settings {

            SettingsView()
                .environmentObject(appState)
                .modelContainer(modelContainer)
        }
    }
}
