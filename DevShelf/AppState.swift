import SwiftUI
import SwiftData
import AppKit
import Carbon.HIToolbox
public import Combine

enum QuickSearchShortcut: String, CaseIterable, Identifiable {

    case optionSpace
    case controlSpace
    case commandShiftSpace
    case controlOptionD

    var id: String {
        rawValue
    }

    var title: String {
        switch self {

        case .optionSpace:
            return "⌥ Space"

        case .controlSpace:
            return "⌃ Space"

        case .commandShiftSpace:
            return "⌘ ⇧ Space"

        case .controlOptionD:
            return "⌃ ⌥ D"
        }
    }

    var keyCode: UInt32 {
        switch self {

        case .controlOptionD:
            return UInt32(kVK_ANSI_D)

        default:
            return UInt32(kVK_Space)
        }
    }

    var modifiers: UInt32 {
        switch self {

        case .optionSpace:
            return UInt32(optionKey)

        case .controlSpace:
            return UInt32(controlKey)

        case .commandShiftSpace:
            return UInt32(cmdKey | shiftKey)

        case .controlOptionD:
            return UInt32(controlKey | optionKey)
        }
    }
}

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var menuBarOnly: Bool {
        didSet {
            UserDefaults.standard.set(
                menuBarOnly,
                forKey: "app.menuBarOnly"
            )

            updateActivationPolicy()
        }
    }

    @Published var quickSearchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                quickSearchEnabled,
                forKey: "app.quickSearchEnabled"
            )

            registerHotKey()
        }
    }

    @Published var shortcut: QuickSearchShortcut {
        didSet {
            UserDefaults.standard.set(
                shortcut.rawValue,
                forKey: "app.quickSearchShortcut"
            )

            registerHotKey()
        }
    }

    @Published private(set) var hotKeyError: String?

    @Published var requestedSnippetID: UUID?

    weak var mainWindow: NSWindow?

    private var modelContainer: ModelContainer?

    private init() {

        let defaults = UserDefaults.standard

        menuBarOnly = defaults.bool(
            forKey: "app.menuBarOnly"
        )

        quickSearchEnabled = defaults.object(
            forKey: "app.quickSearchEnabled"
        ) as? Bool ?? true

        let savedShortcut = defaults.string(
            forKey: "app.quickSearchShortcut"
        ) ?? QuickSearchShortcut.optionSpace.rawValue

        shortcut = QuickSearchShortcut(
            rawValue: savedShortcut
        ) ?? .optionSpace
    }

    func configure(
        container: ModelContainer
    ) {
        modelContainer = container

        updateActivationPolicy()

        registerHotKey()
    }

    // MARK: - Window Management

    func showMainWindow() {

        guard let mainWindow else {
            return
        }

        mainWindow.deminiaturize(nil)

        NSApp.activate(ignoringOtherApps: true)

        mainWindow.makeKeyAndOrderFront(nil)
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    func toggleMainWindow() {

        guard let mainWindow else {
            return
        }

        if mainWindow.isVisible,
           mainWindow.isKeyWindow {

            hideMainWindow()

        } else {

            showMainWindow()
        }
    }

    func updateActivationPolicy() {

        NSApp.setActivationPolicy(
            menuBarOnly
                ? .accessory
                : .regular
        )
    }

    // MARK: - Quick Search

    func showQuickSearch() {

        guard let modelContainer else {
            return
        }

        QuickSearchController.shared.show(
            container: modelContainer
        )
    }

    func toggleQuickSearch() {

        if QuickSearchController.shared.isVisible {

            QuickSearchController.shared.hide()

        } else {

            showQuickSearch()
        }
    }

    // MARK: - Open Snippet

    func openSnippet(_ id: UUID) {

        QuickSearchController.shared.hide(
            restorePreviousApplication: false
        )

        requestedSnippetID = id

        showMainWindow()
    }

    // MARK: - Global Shortcut

    func registerHotKey() {

        HotKeyService.shared.unregister()

        hotKeyError = nil

        guard quickSearchEnabled else {
            return
        }

        let success = HotKeyService.shared.register(
            keyCode: shortcut.keyCode,
            modifiers: shortcut.modifiers
        ) { [weak self] in

            self?.toggleQuickSearch()
        }

        if !success {

            hotKeyError = """
            Unable to register \(shortcut.title).
            This shortcut may already be in use.
            """
        }
    }
}
