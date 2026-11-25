import SwiftUI

struct HashGeneratorView: View {

    @State private var input = ""

    @State private var uppercase = false

    @State private var copiedAlgorithm: HashAlgorithm?

    @State private var copyTask: Task<Void, Never>?

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            UtilityTextPanel(
                title: "Input",
                text: $input
            )
            .frame(height: 220)

            HStack {

                Text("Generated Hashes")
                    .font(.headline)

                Spacer()

                Toggle(
                    "Uppercase",
                    isOn: $uppercase
                )
            }

            ScrollView {

                VStack(spacing: 12) {

                    ForEach(
                        HashAlgorithm.allCases
                    ) { algorithm in

                        hashRow(algorithm)
                    }
                }
            }

            Text(
                "MD5 and SHA-1 are provided for legacy compatibility."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .onDisappear {
            copyTask?.cancel()
        }
    }

    private func hashRow(
        _ algorithm: HashAlgorithm
    ) -> some View {

        let hash = UtilityService.hash(
            input,
            algorithm: algorithm
        )

        let value = uppercase
            ? hash.uppercased()
            : hash

        return VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(algorithm.rawValue)
                    .font(.headline)

                Spacer()

                Button {

                    guard ClipboardService.copy(
                        value
                    ) else {
                        return
                    }

                    copiedAlgorithm = algorithm

                    copyTask?.cancel()

                    copyTask = Task { @MainActor in

                        try? await Task.sleep(
                            for: .seconds(2)
                        )

                        guard !Task.isCancelled else {
                            return
                        }

                        copiedAlgorithm = nil
                    }

                } label: {

                    Label(
                        copiedAlgorithm == algorithm
                            ? "Copied"
                            : "Copy",
                        systemImage:
                            copiedAlgorithm == algorithm
                            ? "checkmark"
                            : "document.on.document"
                    )
                }
                .buttonStyle(.borderless)
            }

            Text(value)
                .font(.system(
                    size: 12,
                    design: .monospaced
                ))
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .padding(12)
        .background(
            Color.secondary.opacity(0.05)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8)
        )
    }
}
