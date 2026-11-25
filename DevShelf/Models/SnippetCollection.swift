import Foundation
import SwiftData

@Model
final class SnippetCollection {

    var id: UUID
    var name: String
    var icon: String
    var createdAt: Date

    var sortOrder: Int = 0

    @Relationship(
        deleteRule: .nullify,
        inverse: \Snippet.collection
    )
    var snippets: [Snippet] = []

    init(
        name: String,
        icon: String = "folder",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}
