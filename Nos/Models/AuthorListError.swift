import Foundation

/// Errors for an ``AuthorList``.
enum AuthorListError: LocalizedError {
    /// The event kind is invalid; that is, an ``AuthorList`` can't be created with the given kind.
    case invalidKind

    /// The replaceable ID is missing (the `d` tag from the JSON event).
    case missingReplaceableID
}
