import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {

    @Binding var text: String

    var language: String = "Plain Text"
    var fontSize: CGFloat = 13
    var showLineNumbers = true
    var indentationWidth = 4
    var autoIndent = true
    var autoPair = true
    var isEditable = true

    private var editorFont: NSFont {
        NSFont.monospacedSystemFont(
            ofSize: fontSize,
            weight: .regular
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(
        context: Context
    ) -> NSScrollView {

        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()

        let textContainer = NSTextContainer(
            containerSize: NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 4

        let textView = CodeTextView(
            frame: scrollView.contentView.bounds,
            textContainer: textContainer
        )

        textView.delegate = context.coordinator

        textView.string = text
        textView.font = editorFont

        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = isEditable
        textView.isSelectable = true

        // Disable automatic macOS text substitutions.

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false

        textView.drawsBackground = false
        textView.insertionPointColor = .labelColor

        textView.textContainerInset = NSSize(
            width: 8,
            height: 10
        )

        textView.minSize = NSSize(
            width: scrollView.contentSize.width,
            height: scrollView.contentSize.height
        )

        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]

        textView.indentationWidth = indentationWidth
        textView.autoIndentEnabled = autoIndent
        textView.autoPairEnabled = autoPair

        scrollView.documentView = textView

        // Line numbers.

        let ruler = LineNumberRulerView(
            textView: textView,
            scrollView: scrollView
        )

        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = showLineNumbers

        context.coordinator.textView = textView

        context.coordinator.highlight()

        return scrollView
    }

    func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        let coordinator = context.coordinator

        let languageChanged =
            coordinator.parent.language != language

        let fontChanged =
            coordinator.parent.fontSize != fontSize

        coordinator.parent = self

        guard let textView =
            scrollView.documentView as? CodeTextView
        else {
            return
        }

        textView.isEditable = isEditable
        textView.indentationWidth = indentationWidth
        textView.autoIndentEnabled = autoIndent
        textView.autoPairEnabled = autoPair

        scrollView.rulersVisible = showLineNumbers

        if textView.string != text {
            coordinator.isUpdating = true

            let oldSelection = textView.selectedRange()

            textView.string = text

            let length = (text as NSString).length

            let location = min(
                oldSelection.location,
                length
            )

            textView.setSelectedRange(
                NSRange(
                    location: location,
                    length: min(
                        oldSelection.length,
                        length - location
                    )
                )
            )

            coordinator.isUpdating = false
            coordinator.highlight()

        } else if languageChanged || fontChanged {
            coordinator.highlight()
        }

        scrollView.verticalRulerView?
            .needsDisplay = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {

        var parent: CodeEditor

        weak var textView: CodeTextView?

        var isUpdating = false

        private var highlightTask: DispatchWorkItem?

        init(_ parent: CodeEditor) {
            self.parent = parent
        }

        deinit {
            highlightTask?.cancel()
        }

        func textDidChange(
            _ notification: Notification
        ) {
            guard !isUpdating,
                  let textView else {
                return
            }

            parent.text = textView.string

            textView.enclosingScrollView?
                .verticalRulerView?
                .needsDisplay = true

            // Debounce syntax highlighting.

            highlightTask?.cancel()

            let task = DispatchWorkItem { [weak self] in
                self?.highlight()
            }

            highlightTask = task

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.08,
                execute: task
            )
        }

        func highlight() {
            guard let textView,
                  let storage = textView.textStorage
            else {
                return
            }

            // Avoid interfering with IME composition.

            guard !textView.hasMarkedText() else {
                return
            }

            let font = NSFont.monospacedSystemFont(
                ofSize: parent.fontSize,
                weight: .regular
            )

            isUpdating = true

            // Do not register syntax coloring as an undo action.

            let undoManager = textView.undoManager

            undoManager?.disableUndoRegistration()

            defer {
                undoManager?.enableUndoRegistration()
                isUpdating = false
            }

            SyntaxHighlightService.highlight(
                storage: storage,
                language: parent.language,
                font: font
            )

            textView.typingAttributes = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]

            textView.enclosingScrollView?
                .verticalRulerView?
                .needsDisplay = true
        }
    }
}
