
import Foundation
import SwiftData

@Model
final class Snippet {
    var id: UUID
    var title: String
    var code: String
    var notes: String
    var language: String
    var isFavorite: Bool
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]

    var collection: SnippetCollection?

    init(
        title: String = "Untitled Snippet",
        code: String = "",
        notes: String = "",
        language: String = "Plain Text",
        collection: SnippetCollection? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.code = code
        self.notes = notes
        self.language = language
        self.collection = collection
        self.isFavorite = false
        self.isDeleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = []
    }
}
