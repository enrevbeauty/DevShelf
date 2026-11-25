import SwiftUI

struct SettingsView: View {

    @EnvironmentObject
    private var appState: AppState

    var body: some View {

        TabView {

            GeneralSettingsView()
                .tabItem {

                    Label(
                        "General",
                        systemImage: "gearshape"
                    )
                }

            EditorSettingsView()
                .tabItem {

                    Label(
                        "Editor",
                        systemImage: "chevron.left.forwardslash.chevron.right"
                    )
                }

            ShortcutSettingsView()
                .tabItem {

                    Label(
                        "Shortcuts",
                        systemImage: "keyboard"
                    )
                }
        }
        .frame(width: 520, height: 300)
        .padding(10)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {

    @EnvironmentObject
    private var appState: AppState

    var body: some View {

        Form {

            Section("Application") {

                Toggle(
                    "Menu bar-only mode",
                    isOn: $appState.menuBarOnly
                )

                Text(
                    "Hide the Dock icon while keeping DevShelf available in the menu bar."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Quick Search") {

                Toggle(
                    "Enable global keyboard shortcut",
                    isOn: $appState.quickSearchEnabled
                )
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Editor Settings

struct EditorSettingsView: View {

    @AppStorage("editor.fontSize")
    private var fontSize: Double = 13

    @AppStorage("editor.showLineNumbers")
    private var showLineNumbers = true

    @AppStorage("editor.autoIndent")
    private var autoIndent = true

    @AppStorage("editor.autoPair")
    private var autoPair = true

    var body: some View {

        Form {

            Section("Appearance") {

                Stepper(
                    "Font Size: \(Int(fontSize)) pt",
                    value: $fontSize,
                    in: 10...28,
                    step: 1
                )

                Toggle(
                    "Show line numbers",
                    isOn: $showLineNumbers
                )
            }

            Section("Editing") {

                Toggle(
                    "Automatic indentation",
                    isOn: $autoIndent
                )

                Toggle(
                    "Automatic bracket pairing",
                    isOn: $autoPair
                )
            }

            Section {

                Button("Restore Defaults") {

                    fontSize = 13

                    showLineNumbers = true

                    autoIndent = true

                    autoPair = true
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shortcut Settings

struct ShortcutSettingsView: View {

    @EnvironmentObject
    private var appState: AppState

    var body: some View {

        Form {

            Section("Global Shortcut") {

                Toggle(
                    "Enable Quick Search",
                    isOn: $appState.quickSearchEnabled
                )

                Picker(
                    "Quick Search",
                    selection: $appState.shortcut
                ) {

                    ForEach(
                        QuickSearchShortcut.allCases
                    ) { shortcut in

                        Text(shortcut.title)
                            .tag(shortcut)
                    }
                }
                .disabled(!appState.quickSearchEnabled)

                if let error = appState.hotKeyError {

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Quick Search Navigation") {

                LabeledContent(
                    "Navigate Results",
                    value: "↑ / ↓"
                )

                LabeledContent(
                    "Copy Code",
                    value: "Return"
                )

                LabeledContent(
                    "Open Snippet",
                    value: "⌘ Return"
                )

                LabeledContent(
                    "Dismiss",
                    value: "Escape"
                )
            }
        }
        .formStyle(.grouped)
    }
}
