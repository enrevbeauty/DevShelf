import SwiftUI

enum TimestampUnit: String, CaseIterable {

    case seconds = "Seconds"
    case milliseconds = "Milliseconds"
}

struct TimestampConverterView: View {

    @State private var timestamp = ""

    @State private var unit: TimestampUnit = .seconds

    @State private var selectedDate = Date()

    @State private var isoInput = ""

    @State private var errorMessage: String?

    private var seconds: Double {
        selectedDate.timeIntervalSince1970
    }

    private var isoString: String {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter.string(
            from: selectedDate
        )
    }
    
    private var utcString: String {

        let formatter = DateFormatter()

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.timeZone = TimeZone(
            secondsFromGMT: 0
        )

        formatter.dateFormat =
            "yyyy-MM-dd HH:mm:ss 'UTC'"

        return formatter.string(
            from: selectedDate
        )
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                GroupBox("Timestamp to Date") {

                    VStack(alignment: .leading, spacing: 12) {

                        TextField(
                            "Unix timestamp",
                            text: $timestamp
                        )
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            convertTimestamp()
                        }

                        Picker(
                            "Unit",
                            selection: $unit
                        ) {

                            ForEach(
                                TimestampUnit.allCases,
                                id: \.self
                            ) { unit in

                                Text(unit.rawValue)
                                    .tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {

                            Button("Convert") {
                                convertTimestamp()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Current Time") {
                                setCurrentTime()
                            }

                            Spacer()
                        }
                    }
                    .padding(8)
                }

                GroupBox("Date to Timestamp") {

                    VStack(alignment: .leading, spacing: 12) {

                        DatePicker(
                            "Date and Time",
                            selection: $selectedDate
                        )

                        HStack {

                            TextField(
                                "ISO 8601 date",
                                text: $isoInput
                            )

                            Button("Parse") {
                                parseISODate()
                            }
                        }
                    }
                    .padding(8)
                }

                if let errorMessage {

                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                GroupBox("Results") {

                    VStack(spacing: 14) {

                        resultRow(
                            "Unix Seconds",
                            value: String(
                                Int64(seconds.rounded(.down))
                            )
                        )

                        Divider()

                        resultRow(
                            "Unix Milliseconds",
                            value: String(
                                Int64(
                                    (seconds * 1000)
                                        .rounded(.down)
                                )
                            )
                        )

                        Divider()

                        resultRow(
                            "ISO 8601",
                            value: isoString
                        )

                        Divider()

                        resultRow(
                            "Local Time",
                            value: selectedDate.formatted(
                                date: .complete,
                                time: .standard
                            )
                        )

                        Divider()

                        resultRow(
                            "UTC",
                            value: utcString
                        )
                    }
                    .padding(8)
                }
            }
        }
        .onAppear {
            setCurrentTime()
        }
    }

    private func resultRow(
        _ title: String,
        value: String
    ) -> some View {

        HStack {

            VStack(alignment: .leading, spacing: 5) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(
                        size: 13,
                        design: .monospaced
                    ))
                    .textSelection(.enabled)
            }

            Spacer()

            Button {

                ClipboardService.copy(value)

            } label: {

                Image(
                    systemName: "document.on.document"
                )
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
    }

    private func convertTimestamp() {

        errorMessage = nil

        guard let value = Double(
            timestamp.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        ), value.isFinite else {

            errorMessage = "Invalid timestamp."

            return
        }

        let seconds = unit == .milliseconds
            ? value / 1000
            : value

        guard seconds >= -62_135_596_800,
              seconds <= 253_402_300_799
        else {

            errorMessage = "Timestamp is outside the supported range."

            return
        }

        selectedDate = Date(
            timeIntervalSince1970: seconds
        )

        isoInput = isoString
    }

    private func setCurrentTime() {

        selectedDate = Date()

        let value = unit == .milliseconds
            ? seconds * 1000
            : seconds

        timestamp = String(
            Int64(value.rounded(.down))
        )

        isoInput = isoString

        errorMessage = nil
    }

    private func parseISODate() {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        var date = formatter.date(from: isoInput)

        if date == nil {

            formatter.formatOptions = [
                .withInternetDateTime
            ]

            date = formatter.date(from: isoInput)
        }

        guard let date else {

            errorMessage = "Invalid ISO 8601 date."

            return
        }

        selectedDate = date

        errorMessage = nil
    }
}
