import SwiftUI

enum DiffLineKind {

    case unchanged
    case added
    case removed
}

struct DiffLine: Identifiable {

    let id = UUID()

    let text: String

    let kind: DiffLineKind

    let oldLine: Int?

    let newLine: Int?
}

struct TextDiffView: View {

    @State private var original = ""

    @State private var modified = ""

    @State private var diffLines: [DiffLine] = []

    @State private var showUnchanged = true

    @State private var errorMessage: String?

    private var additions: Int {

        diffLines.filter {
            $0.kind == .added
        }.count
    }

    private var removals: Int {

        diffLines.filter {
            $0.kind == .removed
        }.count
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Button("Compare") {
                    compare()
                }
                .buttonStyle(.borderedProminent)

                Button("Swap") {

                    let old = original

                    original = modified

                    modified = old

                    compare()
                }

                Toggle(
                    "Show Unchanged",
                    isOn: $showUnchanged
                )

                Spacer()

                Text("+\(additions)")
                    .foregroundStyle(.green)

                Text("-\(removals)")
                    .foregroundStyle(.red)
            }

            if let errorMessage {

                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HSplitView {

                UtilityTextPanel(
                    title: "Original",
                    text: $original
                )
                .frame(minWidth: 180)

                UtilityTextPanel(
                    title: "Modified",
                    text: $modified
                )
                .frame(minWidth: 180)
            }
            .frame(minHeight: 180)

            Divider()

            Text("Comparison")
                .font(.headline)

            ScrollView([.vertical, .horizontal]) {

                LazyVStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    ForEach(diffLines) { line in

                        if showUnchanged ||
                            line.kind != .unchanged {

                            diffRow(line)
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .background(
                Color.secondary.opacity(0.04)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 6)
            )
            .frame(minHeight: 160)
        }
    }

    private func diffRow(
        _ line: DiffLine
    ) -> some View {

        HStack(spacing: 10) {

            Text(
                line.oldLine.map {
                    String($0)
                } ?? ""
            )
            .frame(width: 35, alignment: .trailing)

            Text(
                line.newLine.map {
                    String($0)
                } ?? ""
            )
            .frame(width: 35, alignment: .trailing)

            Text(symbol(line.kind))
                .frame(width: 12)

            Text(line.text)
                .textSelection(.enabled)
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )

            Spacer(minLength: 0)
        }
        .font(.system(
            size: 12,
            design: .monospaced
        ))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(background(line.kind))
    }

    private func symbol(
        _ kind: DiffLineKind
    ) -> String {

        switch kind {

        case .added:
            return "+"

        case .removed:
            return "-"

        case .unchanged:
            return " "
        }
    }

    private func background(
        _ kind: DiffLineKind
    ) -> Color {

        switch kind {

        case .added:
            return .green.opacity(0.12)

        case .removed:
            return .red.opacity(0.12)

        case .unchanged:
            return .clear
        }
    }

    private func compare() {

        errorMessage = nil

        diffLines = []

        let oldLines = original.isEmpty
            ? []
            : original.components(separatedBy: "\n")

        let newLines = modified.isEmpty
            ? []
            : modified.components(separatedBy: "\n")

        guard oldLines.count <= 2000,
              newLines.count <= 2000
        else {

            errorMessage =
                "Text comparison supports up to 2,000 lines per input."

            return
        }

        let difference = newLines.difference(
            from: oldLines
        )

        var removed = Set<Int>()

        var inserted = Set<Int>()

        for change in difference {

            switch change {

            case .remove(let offset, _, _):

                removed.insert(offset)

            case .insert(let offset, _, _):

                inserted.insert(offset)
            }
        }

        var oldIndex = 0

        var newIndex = 0

        var result: [DiffLine] = []

        while oldIndex < oldLines.count ||
              newIndex < newLines.count {

            if oldIndex < oldLines.count,
               removed.contains(oldIndex) {

                result.append(
                    DiffLine(
                        text: oldLines[oldIndex],
                        kind: .removed,
                        oldLine: oldIndex + 1,
                        newLine: nil
                    )
                )

                oldIndex += 1

            } else if newIndex < newLines.count,
                      inserted.contains(newIndex) {

                result.append(
                    DiffLine(
                        text: newLines[newIndex],
                        kind: .added,
                        oldLine: nil,
                        newLine: newIndex + 1
                    )
                )

                newIndex += 1

            } else if oldIndex < oldLines.count,
                      newIndex < newLines.count {

                result.append(
                    DiffLine(
                        text: oldLines[oldIndex],
                        kind: .unchanged,
                        oldLine: oldIndex + 1,
                        newLine: newIndex + 1
                    )
                )

                oldIndex += 1

                newIndex += 1

            } else {

                break
            }
        }

        diffLines = result
    }
}
