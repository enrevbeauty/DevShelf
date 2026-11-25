import SwiftUI
import SwiftData

struct CollectionEditorView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \SnippetCollection.sortOrder)
    private var collections: [SnippetCollection]

    let collection: SnippetCollection?

    var onSave: (SnippetCollection) -> Void = { _ in }

    @State private var name = ""
    @State private var selectedIcon = "folder"

    @State private var errorMessage: String?

    @FocusState private var nameFocused: Bool

    private let icons = [
        "folder",
        "folder.fill",
        "shippingbox",
        "terminal",
        "chevron.left.forwardslash.chevron.right",
        "server.rack",
        "externaldrive",
        "cylinder",
        "network",
        "globe",
        "cloud",
        "lock.shield",
        "hammer",
        "wrench.and.screwdriver",
        "gearshape",
        "cpu",
        "desktopcomputer",
        "laptopcomputer",
        "apple.logo",
        "swift",
        "doc.text",
        "book",
        "archivebox",
        "star",
        "bolt",
        "link",
        "tray",
        "square.stack"
    ]

    private var isEditing: Bool {
        collection != nil
    }

    private var trimmedName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text(
                isEditing
                    ? "Edit Collection"
                    : "New Collection"
            )
            .font(.title2.bold())

            nameField

            iconPicker

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(
                    isEditing ? "Save" : "Create"
                ) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if let collection {
                name = collection.name
                selectedIcon = collection.icon
            }

            nameFocused = true
        }
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Name")
                .font(.headline)

            TextField(
                "Collection name",
                text: $name
            )
            .textFieldStyle(.roundedBorder)
            .focused($nameFocused)
            .onChange(of: name) {
                errorMessage = nil
            }
        }
    }

    // MARK: - Icon Picker

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Icon")
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(
                        .flexible(),
                        spacing: 6
                    ),
                    count: 7
                ),
                spacing: 6
            ) {
                ForEach(icons, id: \.self) { icon in

                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .frame(width: 42, height: 42)
                            .background {
                                RoundedRectangle(
                                    cornerRadius: 6
                                )
                                .fill(
                                    selectedIcon == icon
                                        ? Color.accentColor.opacity(0.18)
                                        : Color.secondary.opacity(0.06)
                                )
                            }
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 6
                                )
                                .strokeBorder(
                                    selectedIcon == icon
                                        ? Color.accentColor
                                        : Color.clear,
                                    lineWidth: 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .help(icon)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard !trimmedName.isEmpty else {
            return
        }

        let duplicate = collections.contains {
            $0.id != collection?.id &&
            $0.name.localizedCaseInsensitiveCompare(
                trimmedName
            ) == .orderedSame
        }

        guard !duplicate else {
            errorMessage =
                "A collection with this name already exists."

            return
        }

        let result: SnippetCollection

        if let collection {
            collection.name = trimmedName
            collection.icon = selectedIcon

            result = collection

        } else {
            let nextOrder = (
                collections.map(\.sortOrder).max() ?? -1
            ) + 1

            let newCollection = SnippetCollection(
                name: trimmedName,
                icon: selectedIcon,
                sortOrder: nextOrder
            )

            modelContext.insert(newCollection)

            result = newCollection
        }

        do {
            try modelContext.save()

            onSave(result)
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
