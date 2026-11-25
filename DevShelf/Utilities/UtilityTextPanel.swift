import SwiftUI

struct UtilityTextPanel: View {

    let title: String

    @Binding var text: String

    var language = "Plain Text"

    var isEditable = true

    var showLineNumbers = true

    @AppStorage("editor.fontSize")
    private var fontSize: Double = 13

    @State private var copied = false

    @State private var copyTask: Task<Void, Never>?

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 12) {

                Text(title)
                    .fontWeight(.medium)

                Spacer()

                if isEditable {

                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(text.isEmpty)
                    .help("Clear")
                }

                Button(action: copy) {

                    Label(
                        copied ? "Copied" : "Copy",
                        systemImage: copied
                            ? "checkmark"
                            : "document.on.document"
                    )
                }
                .disabled(text.isEmpty)
                .help("Copy Text")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .padding(10)
            .background(
                Color.secondary.opacity(0.06)
            )

            Divider()

            CodeEditor(
                text: $text,
                language: language,
                fontSize: CGFloat(fontSize),
                showLineNumbers: showLineNumbers,
                autoIndent: false,
                autoPair: false,
                isEditable: isEditable
            )
            .frame(minHeight: 120)

            Divider()

            HStack {

                Text("\(text.count) characters")

                Spacer()

                Text(
                    "\(text.utf8.count) bytes"
                )
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .background(
            Color.secondary.opacity(0.04)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8)
        )
        .overlay {

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    Color.secondary.opacity(0.15)
                )
        }
        .onDisappear {
            copyTask?.cancel()
        }
    }

    private func copy() {

        guard ClipboardService.copy(text) else {
            return
        }

        copied = true

        copyTask?.cancel()

        copyTask = Task { @MainActor in

            try? await Task.sleep(
                for: .seconds(2)
            )

            guard !Task.isCancelled else {
                return
            }

            copied = false
        }
    }
}
