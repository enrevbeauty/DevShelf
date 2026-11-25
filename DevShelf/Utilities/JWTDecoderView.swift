import SwiftUI

struct JWTDecoderView: View {

    @State private var token = ""

    @State private var header = ""

    @State private var payload = ""

    @State private var signature = ""

    @State private var errorMessage: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            UtilityTextPanel(
                title: "JWT Token",
                text: $token,
                showLineNumbers: false
            )
            .frame(height: 160)

            HStack {

                Button("Decode") {
                    decode()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Label(
                    "Signature Not Verified",
                    systemImage: "exclamationmark.shield"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }

            if let errorMessage {

                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HSplitView {

                UtilityTextPanel(
                    title: "Header",
                    text: $header,
                    language: "JSON",
                    isEditable: false
                )
                .frame(minWidth: 180)

                UtilityTextPanel(
                    title: "Payload",
                    text: $payload,
                    language: "JSON",
                    isEditable: false
                )
                .frame(minWidth: 180)
            }

            GroupBox("Signature") {

                HStack {

                    Text(
                        signature.isEmpty
                            ? "No signature"
                            : signature
                    )
                    .font(.system(
                        size: 12,
                        design: .monospaced
                    ))
                    .textSelection(.enabled)

                    Spacer()

                    Button {

                        ClipboardService.copy(
                            signature
                        )

                    } label: {

                        Image(
                            systemName: "document.on.document"
                        )
                    }
                    .buttonStyle(.borderless)
                    .disabled(signature.isEmpty)
                }
                .padding(8)
            }
        }
        .onChange(of: token) {

            header = ""

            payload = ""

            signature = ""

            errorMessage = nil
        }
    }

    private func decode() {

        errorMessage = nil

        do {

            let result = try UtilityService.decodeJWT(
                token
            )

            header = result.header

            payload = result.payload

            signature = result.signature

        } catch {

            header = ""

            payload = ""

            signature = ""

            errorMessage = error.localizedDescription
        }
    }
}
