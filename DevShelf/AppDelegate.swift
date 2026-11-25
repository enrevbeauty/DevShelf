import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {

        if !flag {
            AppState.shared.showMainWindow()
        }

        return true
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        HotKeyService.shared.unregister()
    }
}

@MainActor
final class MainWindowDelegate: NSObject, NSWindowDelegate {

    static let shared = MainWindowDelegate()

    func windowShouldClose(
        _ sender: NSWindow
    ) -> Bool {

        sender.orderOut(nil)

        return false
    }
}
