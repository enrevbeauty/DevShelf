import AppKit

@MainActor
enum ClipboardService {

    @discardableResult
    static func copy(_ text: String) -> Bool {

        let pasteboard = NSPasteboard.general

        pasteboard.clearContents()

        return pasteboard.setString(
            text,
            forType: .string
        )
    }

    @discardableResult
    static func copyCode(_ snippet: Snippet) -> Bool {
        copy(snippet.code)
    }

    @discardableResult
    static func copyNotes(_ snippet: Snippet) -> Bool {
        copy(snippet.notes)
    }

    @discardableResult
    static func copyTitle(_ snippet: Snippet) -> Bool {
        copy(snippet.title)
    }
}
