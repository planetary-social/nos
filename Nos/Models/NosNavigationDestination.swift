import Foundation

/// An enumeration of the views that can be pushed onto a `NosNavigationStack`.
enum NosNavigationDestination: Hashable {
    case note(NoteIdentifiable)
    case author(RawAuthorID?)
    case list(AuthorList)
    case url(URL)
    case replyTo(RawEventID?)
    case wallet
}

/// Convenience for wallet destinations.
extension NosNavigationDestination {
    static func wallet() -> Self {
        return .wallet
    }
}

/// Extension to help with creating wallet destinations.
typealias WalletDestination = NosNavigationDestination

enum NoteIdentifiable: Hashable {
    case identifier(RawEventID?)
    case replaceableIdentifier(replaceableID: RawReplaceableID, author: Author, kind: Int64)
}
