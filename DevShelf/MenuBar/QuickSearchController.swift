import SwiftUI
import SwiftData
import AppKit

final class QuickSearchPanel: NSPanel {

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

@MainActor
final class QuickSearchController: NSObject, NSWindowDelegate {

    static let shared = QuickSearchController()

    private var panel: QuickSearchPanel?

    private weak var previousApplication: NSRunningApplication?

    private override init() {
        super.init()
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show(
        container: ModelContainer
    ) {

        if let panel, panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        previousApplication =
            NSWorkspace.shared.frontmostApplication

        let panel = QuickSearchPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 640,
                height: 440
            ),
            styleMask: [
                .borderless,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true

        panel.level = .floating

        panel.isOpaque = false

        panel.backgroundColor = .clear

        panel.hasShadow = true

        panel.isMovableByWindowBackground = true

        panel.hidesOnDeactivate = true

        panel.isReleasedWhenClosed = false

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        panel.delegate = self

        let rootView = QuickSearchView(
            onDismiss: { [weak self] in
                self?.hide()
            },
            onOpenSnippet: { id in
                AppState.shared.openSnippet(id)
            }
        )
        .modelContainer(container)
        .environmentObject(AppState.shared)

        panel.contentView = NSHostingView(
            rootView: rootView
        )

        self.panel = panel

        positionPanel(panel)

        NSApp.activate(ignoringOtherApps: true)

        panel.makeKeyAndOrderFront(nil)
    }

    func hide(
        restorePreviousApplication: Bool = true
    ) {

        panel?.orderOut(nil)

        if restorePreviousApplication,
           let previousApplication,
           previousApplication.processIdentifier !=
                ProcessInfo.processInfo.processIdentifier {

            previousApplication.activate(
                options: []
            )
        }

        previousApplication = nil
    }

    private func positionPanel(
        _ panel: NSPanel
    ) {

        let mouseLocation = NSEvent.mouseLocation

        let screen = NSScreen.screens.first {
            $0.frame.contains(mouseLocation)
        } ?? NSScreen.main

        guard let screen else {
            panel.center()
            return
        }

        let screenFrame = screen.visibleFrame

        let panelSize = panel.frame.size

        let x = screenFrame.midX -
            panelSize.width / 2

        let y = screenFrame.maxY -
            screenFrame.height * 0.18 -
            panelSize.height

        panel.setFrameOrigin(
            NSPoint(
                x: x,
                y: max(screenFrame.minY, y)
            )
        )
    }

    func windowDidResignKey(
        _ notification: Notification
    ) {

        panel?.orderOut(nil)
    }
}
