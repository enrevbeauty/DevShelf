import SwiftUI

struct UUIDGeneratorView: View {

    @State private var count = 10

    @State private var uppercase = false

    @State private var hyphens = true

    @State private var output = ""

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 12) {

                Text("Quantity")

                TextField(
                    "Count",
                    value: $count,
                    format: .number
                )
                .frame(width: 80)

                Stepper(
                    "",
                    value: $count,
                    in: 1...10_000
                )
                .labelsHidden()

                Spacer()

                Button("Generate") {
                    generate()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }

            HStack(spacing: 20) {

                Toggle(
                    "Uppercase",
                    isOn: $uppercase
                )

                Toggle(
                    "Include Hyphens",
                    isOn: $hyphens
                )

                Spacer()
            }

            HStack {

                ForEach(
                    [1, 10, 50, 100, 1000],
                    id: \.self
                ) { value in

                    Button("\(value)") {

                        count = value

                        generate()
                    }
                }

                Spacer()
            }

            UtilityTextPanel(
                title: "Generated UUIDs",
                text: $output,
                isEditable: false
            )
        }
        .onAppear {

            if output.isEmpty {
                generate()
            }
        }
    }

    private func generate() {

        count = min(
            max(count, 1),
            10_000
        )

        output = UtilityService.generateUUIDs(
            count: count,
            uppercase: uppercase,
            hyphens: hyphens
        )
    }
}
