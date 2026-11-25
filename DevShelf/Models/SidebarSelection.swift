import Foundation

enum SidebarSelection: Hashable {

    case all
    case favorites
    case recent
    case unfiled
    case trash

    case collection(UUID)
    case tag(String)

    var title: String {
        switch self {
        case .all:
            return "All Snippets"

        case .favorites:
            return "Favorites"

        case .recent:
            return "Recent"

        case .unfiled:
            return "Unfiled"

        case .trash:
            return "Trash"

        case .collection:
            return "Collection"

        case .tag(let name):
            return name
        }
    }
}
