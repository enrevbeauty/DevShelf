import SwiftUI

struct UtilityContainerView: View {

    let utility: DeveloperUtility

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 12) {

                Image(systemName: utility.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {

                    Text(utility.title)
                        .font(.title2.bold())

                    Text(utility.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(
                    "Offline",
                    systemImage: "lock.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            utilityContent
                .id(utility.id)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .padding(20)
        .navigationTitle(utility.title)
    }

    @ViewBuilder
    private var utilityContent: some View {

        switch utility {

        case .json:

            JSONFormatterView()

        case .base64, .url, .hex:

            EncodingUtilityView(
                utility: utility
            )

        case .hash:

            HashGeneratorView()

        case .uuid:

            UUIDGeneratorView()

        case .timestamp:

            TimestampConverterView()

        case .regex:

            RegexTesterView()

        case .jwt:

            JWTDecoderView()

        case .diff:

            TextDiffView()
        }
    }
}
