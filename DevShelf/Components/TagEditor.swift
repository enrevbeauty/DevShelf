import SwiftUI

struct TagEditor: View {

    @Binding var tags: [String]

    var availableTags: [String] = []

    @State private var input = ""

    @FocusState private var inputFocused: Bool

    private var suggestions: [String] {
        let query = input.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return availableTags
            .filter { tag in
                !tags.contains(tag) &&
                (
                    query.isEmpty ||
                    tag.localizedCaseInsensitiveContains(
                        query
                    )
                )
            }
            .sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Tags")
                    .font(.headline)

                Spacer()

                if !suggestions.isEmpty {
                    suggestionMenu
                }
            }

            HStack(spacing: 8) {

                Image(systemName: "tag")
                    .foregroundStyle(.secondary)

                TextField(
                    "Add a tag...",
                    text: $input
                )
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit {
                    addTag(input)
                }

                Button {
                    addTag(input)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .disabled(
                    input.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .help("Add Tag")
            }
            .padding(8)
            .background(
                Color.secondary.opacity(0.05)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        Color.secondary.opacity(0.15)
                    )
            }

            if !tags.isEmpty {
                tagList
            }
        }
    }

    // MARK: - Tag List

    private var tagList: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    tagChip(tag)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func tagChip(
        _ tag: String
    ) -> some View {

        HStack(spacing: 5) {

            Text(tag)
                .lineLimit(1)

            Button {
                tags.removeAll {
                    $0 == tag
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(
                        size: 8,
                        weight: .semibold
                    ))
            }
            .buttonStyle(.plain)
            .help("Remove Tag")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .foregroundStyle(Color.accentColor)
        .background(
            Color.accentColor.opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 5)
        )
    }

    // MARK: - Suggestions

    private var suggestionMenu: some View {
        Menu {
            ForEach(suggestions, id: \.self) { tag in
                Button(tag) {
                    addTag(tag)
                }
            }
        } label: {
            Image(systemName: "tag.circle")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Existing Tags")
    }

    // MARK: - Add Tag

    private func addTag(
        _ value: String
    ) {
        let tag = value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        guard !tag.isEmpty else {
            return
        }

        if !tags.contains(tag) {
            tags.append(tag)
            tags.sort()
        }

        input = ""
        inputFocused = true
    }
}
