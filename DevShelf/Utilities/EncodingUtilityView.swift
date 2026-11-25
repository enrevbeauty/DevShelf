import SwiftUI

enum EncodingMode: String, CaseIterable {

    case encode = "Encode"
    case decode = "Decode"
}

struct EncodingUtilityView: View {

    let utility: DeveloperUtility

    @State private var input = ""

    @State private var output = ""

    @State private var mode: EncodingMode = .encode

    @State private var errorMessage: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Picker(
                    "Mode",
                    selection: $mode
                ) {

                    ForEach(
                        EncodingMode.allCases,
                        id: \.self
                    ) { mode in

                        Text(mode.rawValue)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Button("Convert") {
                    convert()
                }
                .buttonStyle(.borderedProminent)

                Button {

                    let oldInput = input

                    input = output

                    output = oldInput

                    mode = mode == .encode
                        ? .decode
                        : .encode

                    convert()

                } label: {

                    Label(
                        "Swap",
                        systemImage: "arrow.left.arrow.right"
                    )
                }
                .disabled(output.isEmpty)

                Spacer()
            }

            if let errorMessage {

                Label(
                    errorMessage,
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

            HSplitView {

                UtilityTextPanel(
                    title: "Input",
                    text: $input
                )
                .frame(minWidth: 180)

                UtilityTextPanel(
                    title: "Output",
                    text: $output,
                    isEditable: false
                )
                .frame(minWidth: 180)
            }
        }
        .onChange(of: input) {
            convert()
        }
        .onChange(of: mode) {
            convert()
        }
    }

    private func convert() {

        errorMessage = nil

        guard !input.isEmpty else {

            output = ""

            return
        }

        do {

            switch (utility, mode) {

            case (.base64, .encode):

                output = UtilityService.encodeBase64(
                    input
                )

            case (.base64, .decode):

                output = try UtilityService.decodeBase64(
                    input
                )

            case (.url, .encode):

                output = UtilityService.encodeURL(
                    input
                )

            case (.url, .decode):

                output = try UtilityService.decodeURL(
                    input
                )

            case (.hex, .encode):

                output = UtilityService.encodeHex(
                    input
                )

            case (.hex, .decode):

                output = try UtilityService.decodeHex(
                    input
                )

            default:

                output = ""
            }

        } catch {

            output = ""

            errorMessage = error.localizedDescription
        }
    }
}
