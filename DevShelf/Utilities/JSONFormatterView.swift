import SwiftUI

struct JSONFormatterView: View {

    @State private var input = ""

    @State private var output = ""

    @State private var sortedKeys = false

    @State private var errorMessage: String?

    @State private var statusMessage: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            toolbar

            if let errorMessage {

                Label(
                    errorMessage,
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

            if let statusMessage {

                Label(
                    statusMessage,
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.green)
            }

            HSplitView {

                UtilityTextPanel(
                    title: "Input",
                    text: $input,
                    language: "JSON"
                )
                .frame(minWidth: 180)

                UtilityTextPanel(
                    title: "Output",
                    text: $output,
                    language: "JSON",
                    isEditable: false
                )
                .frame(minWidth: 180)
            }
        }
        .onChange(of: input) {
            output = ""
            errorMessage = nil
            statusMessage = nil
        }
    }

    private var toolbar: some View {

        HStack {

            Button("Format") {
                process(pretty: true)
            }
            .buttonStyle(.borderedProminent)

            Button("Minify") {
                process(pretty: false)
            }

            Button("Validate") {
                validate()
            }

            Divider()
                .frame(height: 20)

            Toggle(
                "Sort Keys",
                isOn: $sortedKeys
            )

            Spacer()

            Button {

                input = output

            } label: {

                Label(
                    "Use Output",
                    systemImage: "arrow.left"
                )
            }
            .disabled(output.isEmpty)
        }
    }

    private func process(
        pretty: Bool
    ) {

        errorMessage = nil
        statusMessage = nil

        do {

            output = try UtilityService.formatJSON(
                input,
                pretty: pretty,
                sortedKeys: sortedKeys
            )

            statusMessage = pretty
                ? "JSON formatted successfully."
                : "JSON minified successfully."

        } catch {

            output = ""

            errorMessage = error.localizedDescription
        }
    }

    private func validate() {

        errorMessage = nil
        statusMessage = nil

        do {

            _ = try UtilityService.formatJSON(input)

            statusMessage = "Valid JSON."

        } catch {

            errorMessage = error.localizedDescription
        }
    }
}
