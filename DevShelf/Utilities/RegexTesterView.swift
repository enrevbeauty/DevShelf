import SwiftUI
import Foundation

struct RegexMatchResult: Identifiable {

    let id = UUID()

    let value: String

    let range: NSRange

    let groups: [String]
}

struct RegexTesterView: View {

    @State private var pattern = ""

    @State private var input = ""

    @State private var ignoreCase = false

    @State private var multiline = false

    @State private var dotMatchesNewline = false

    @State private var matches: [RegexMatchResult] = []

    @State private var errorMessage: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            TextField(
                "Regular expression",
                text: $pattern
            )
            .font(.system(
                size: 15,
                design: .monospaced
            ))
            .textFieldStyle(.roundedBorder)
            .onSubmit {
                evaluate()
            }

            HStack(spacing: 16) {

                Toggle(
                    "Ignore Case (i)",
                    isOn: $ignoreCase
                )

                Toggle(
                    "Multiline (m)",
                    isOn: $multiline
                )

                Toggle(
                    "Dot All (s)",
                    isOn: $dotMatchesNewline
                )

                Spacer()

                Button("Test") {
                    evaluate()
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage {

                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            UtilityTextPanel(
                title: "Test String",
                text: $input
            )
            .frame(minHeight: 160)

            HStack {

                Text("Matches")
                    .font(.headline)

                Spacer()

                Text("\(matches.count) results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List(matches) { match in

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(
                        match.value.isEmpty
                            ? "(Empty match)"
                            : match.value
                    )
                    .font(.system(
                        size: 13,
                        design: .monospaced
                    ))
                    .textSelection(.enabled)

                    Text(
                        "Location: \(match.range.location), " +
                        "Length: \(match.range.length)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach(
                        Array(match.groups.enumerated()),
                        id: \.offset
                    ) { index, group in

                        HStack {

                            Text("Group \(index + 1)")

                            Text(group)
                                .font(.system(
                                    size: 12,
                                    design: .monospaced
                                ))
                                .textSelection(.enabled)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 5)
            }
            .listStyle(.plain)
            .frame(minHeight: 150)
        }
    }

    private func evaluate() {

        matches = []

        errorMessage = nil

        guard !pattern.isEmpty else {
            return
        }

        guard input.utf16.count <= 100_000,
              pattern.utf16.count <= 2_000
        else {

            errorMessage = "Input or pattern is too large."

            return
        }

        var options: NSRegularExpression.Options = []

        if ignoreCase {
            options.insert(.caseInsensitive)
        }

        if multiline {
            options.insert(.anchorsMatchLines)
        }

        if dotMatchesNewline {
            options.insert(.dotMatchesLineSeparators)
        }

        do {

            let regex = try NSRegularExpression(
                pattern: pattern,
                options: options
            )

            let source = input as NSString

            let range = NSRange(
                location: 0,
                length: source.length
            )

            var results: [RegexMatchResult] = []

            regex.enumerateMatches(
                in: input,
                range: range
            ) { match, _, stop in

                guard let match else {
                    return
                }

                var groups: [String] = []

                if match.numberOfRanges > 1 {

                    for index in 1..<match.numberOfRanges {

                        let groupRange = match.range(
                            at: index
                        )

                        if groupRange.location == NSNotFound {

                            groups.append("(Unmatched)")

                        } else {

                            groups.append(
                                source.substring(
                                    with: groupRange
                                )
                            )
                        }
                    }
                }

                results.append(
                    RegexMatchResult(
                        value: source.substring(
                            with: match.range
                        ),
                        range: match.range,
                        groups: groups
                    )
                )

                if results.count >= 1000 {
                    stop.pointee = true
                }
            }

            matches = results

        } catch {

            errorMessage = error.localizedDescription
        }
    }
}
