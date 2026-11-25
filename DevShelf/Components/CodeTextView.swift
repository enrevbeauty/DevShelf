import AppKit

final class CodeTextView: NSTextView {

    var indentationWidth = 4
    var autoIndentEnabled = true
    var autoPairEnabled = true

    private let pairs: [String: String] = [
        "(": ")",
        "[": "]",
        "{": "}",
        "\"": "\"",
        "'": "'",
        "`": "`"
    ]

    override func insertTab(_ sender: Any?) {
        insertText(
            String(
                repeating: " ",
                count: indentationWidth
            ),
            replacementRange: selectedRange()
        )
    }

    override func insertNewline(_ sender: Any?) {
        guard autoIndentEnabled else {
            super.insertNewline(sender)
            return
        }

        let source = string as NSString
        let selection = selectedRange()

        let lineRange = source.lineRange(
            for: NSRange(
                location: selection.location,
                length: 0
            )
        )

        let prefix = source.substring(
            with: NSRange(
                location: lineRange.location,
                length: selection.location -
                    lineRange.location
            )
        )

        let indentation = String(
            prefix.prefix {
                $0 == " " || $0 == "\t"
            }
        )

        let trimmed = prefix.trimmingCharacters(
            in: .whitespaces
        )

        let opensBlock =
            trimmed.hasSuffix("{") ||
            trimmed.hasSuffix("(") ||
            trimmed.hasSuffix("[") ||
            trimmed.hasSuffix(":")

        let extraIndentation = opensBlock
            ? String(
                repeating: " ",
                count: indentationWidth
            )
            : ""

        let insertion =
            "\n" + indentation + extraIndentation

        let nextLocation = NSMaxRange(selection)

        if opensBlock,
           nextLocation < source.length {

            let nextCharacter = source.substring(
                with: NSRange(
                    location: nextLocation,
                    length: 1
                )
            )

            if ["}", ")", "]"].contains(nextCharacter) {
                insertText(
                    insertion + "\n" + indentation,
                    replacementRange: selection
                )

                setSelectedRange(
                    NSRange(
                        location: selection.location +
                            (insertion as NSString).length,
                        length: 0
                    )
                )

                return
            }
        }

        insertText(
            insertion,
            replacementRange: selection
        )
    }

    override func insertText(
        _ insertString: Any,
        replacementRange: NSRange
    ) {
        guard autoPairEnabled,
              !hasMarkedText(),
              let value = insertString as? String,
              value.count == 1 else {

            super.insertText(
                insertString,
                replacementRange: replacementRange
            )

            return
        }

        let selection =
            replacementRange.location == NSNotFound
            ? selectedRange()
            : replacementRange

        let source = string as NSString

        // Skip an existing closing character.

        if selection.length == 0,
           selection.location < source.length,
           pairs.values.contains(value) {

            let nextCharacter = source.substring(
                with: NSRange(
                    location: selection.location,
                    length: 1
                )
            )

            if nextCharacter == value {
                setSelectedRange(
                    NSRange(
                        location: selection.location + 1,
                        length: 0
                    )
                )

                return
            }
        }

        guard let closing = pairs[value] else {
            super.insertText(
                insertString,
                replacementRange: replacementRange
            )

            return
        }

        let selectedText = source.substring(
            with: selection
        )

        super.insertText(
            value + selectedText + closing,
            replacementRange: selection
        )

        setSelectedRange(
            NSRange(
                location: selection.location + 1,
                length: selection.length
            )
        )
    }

    override func deleteBackward(_ sender: Any?) {
        let selection = selectedRange()
        let source = string as NSString

        if autoPairEnabled,
           selection.length == 0,
           selection.location > 0,
           selection.location < source.length {

            let previous = source.substring(
                with: NSRange(
                    location: selection.location - 1,
                    length: 1
                )
            )

            let next = source.substring(
                with: NSRange(
                    location: selection.location,
                    length: 1
                )
            )

            if pairs[previous] == next {
                super.insertText(
                    "",
                    replacementRange: NSRange(
                        location: selection.location - 1,
                        length: 2
                    )
                )

                return
            }
        }

        super.deleteBackward(sender)
    }
}
