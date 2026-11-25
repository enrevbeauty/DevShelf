import Foundation
import SwiftData

@MainActor
enum SnippetService {

    // MARK: - Create

    @discardableResult
    static func create(
        in context: ModelContext,
        collection: SnippetCollection? = nil,
        favorite: Bool = false,
        tags: [String] = []
    ) -> Snippet {

        let snippet = Snippet(
            collection: collection
        )

        snippet.isFavorite = favorite
        snippet.tags = tags

        context.insert(snippet)

        return snippet
    }

    // MARK: - Duplicate

    @discardableResult
    static func duplicate(
        _ snippet: Snippet,
        in context: ModelContext
    ) -> Snippet {

        let copy = Snippet(
            title: "\(snippet.title) Copy",
            code: snippet.code,
            notes: snippet.notes,
            language: snippet.language,
            collection: snippet.collection
        )

        copy.tags = snippet.tags
        copy.isFavorite = snippet.isFavorite

        context.insert(copy)

        return copy
    }

    // MARK: - Move

    static func move(
        _ snippet: Snippet,
        to collection: SnippetCollection?
    ) {
        snippet.collection = collection
        snippet.updatedAt = Date()
    }

    // MARK: - Favorites

    static func toggleFavorite(
        _ snippet: Snippet
    ) {
        snippet.isFavorite.toggle()
        snippet.updatedAt = Date()
    }

    // MARK: - Trash

    static func moveToTrash(
        _ snippet: Snippet
    ) {
        snippet.isDeleted = true
        snippet.updatedAt = Date()
    }

    static func restore(
        _ snippet: Snippet
    ) {
        snippet.isDeleted = false
        snippet.updatedAt = Date()
    }

    static func permanentlyDelete(
        _ snippet: Snippet,
        in context: ModelContext
    ) {
        context.delete(snippet)
    }

    static func emptyTrash(
        snippets: [Snippet],
        in context: ModelContext
    ) {
        for snippet in snippets where snippet.isDeleted {
            context.delete(snippet)
        }
    }

    // MARK: - Tags

    static func addTag(
        _ name: String,
        to snippet: Snippet
    ) {
        let tag = normalizeTag(name)

        guard !tag.isEmpty else {
            return
        }

        guard !snippet.tags.contains(tag) else {
            return
        }

        snippet.tags.append(tag)
        snippet.tags.sort()
        snippet.updatedAt = Date()
    }

    static func removeTag(
        _ name: String,
        from snippet: Snippet
    ) {
        snippet.tags.removeAll {
            $0 == name
        }

        snippet.updatedAt = Date()
    }

    static func normalizeTag(
        _ name: String
    ) -> String {
        name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }
}
