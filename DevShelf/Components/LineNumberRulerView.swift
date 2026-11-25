import AppKit

final class LineNumberRulerView: NSRulerView {

    weak var textView: NSTextView?

    override var isFlipped: Bool {
        true
    }

    init(
        textView: NSTextView,
        scrollView: NSScrollView
    ) {
        self.textView = textView

        super.init(
            scrollView: scrollView,
            orientation: .verticalRuler
        )

        clientView = textView
        ruleThickness = 48

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: NSText.didChangeNotification,
            object: textView
        )

        scrollView.contentView
            .postsBoundsChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func refresh() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(
        in rect: NSRect
    ) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer
        else {
            return
        }

        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        let source = textView.string as NSString
        let visibleRect = textView.visibleRect

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: 11,
                weight: .regular
            ),
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        let origin = textView.textContainerOrigin

        layoutManager.ensureLayout(for: textContainer)

        var lineNumber = 1
        var location = 0

        func drawNumber(
            _ number: Int,
            at lineRect: NSRect
        ) {
            let y = lineRect.minY +
                origin.y - visibleRect.minY

            guard y + lineRect.height >= 0,
                  y <= bounds.height else {
                return
            }

            let label = "\(number)" as NSString

            let size = label.size(
                withAttributes: attributes
            )

            label.draw(
                at: NSPoint(
                    x: ruleThickness - size.width - 10,
                    y: y + (lineRect.height - size.height) / 2
                ),
                withAttributes: attributes
            )
        }

        while location < source.length {
            let lineRange = source.lineRange(
                for: NSRange(
                    location: location,
                    length: 0
                )
            )

            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: lineRange,
                actualCharacterRange: nil
            )

            if glyphRange.length > 0 {
                let lineRect =
                    layoutManager.lineFragmentRect(
                        forGlyphAt: glyphRange.location,
                        effectiveRange: nil
                    )

                drawNumber(
                    lineNumber,
                    at: lineRect
                )

                if lineRect.minY + origin.y >
                    visibleRect.maxY {
                    break
                }
            }

            location = NSMaxRange(lineRange)
            lineNumber += 1
        }

        // Empty document or trailing newline.

        if location == source.length,
           source.length == 0 ||
           source.hasSuffix("\n") {

            var extraRect =
                layoutManager.extraLineFragmentRect

            if extraRect.height == 0 {
                extraRect.size.height =
                    layoutManager.defaultLineHeight(
                        for: textView.font ??
                            NSFont.monospacedSystemFont(
                                ofSize: 13,
                                weight: .regular
                            )
                    )
            }

            drawNumber(
                lineNumber,
                at: extraRect
            )
        }

        // Right separator.

        NSColor.separatorColor.setFill()

        NSRect(
            x: bounds.maxX - 1,
            y: bounds.minY,
            width: 1,
            height: bounds.height
        ).fill()
    }
}
