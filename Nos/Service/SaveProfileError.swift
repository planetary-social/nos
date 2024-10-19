import Foundation

/// An error that may occur while saving a profile.
enum SaveProfileError: LocalizedError {
    case unexpectedError
    case unableToPublishChanges

    var errorDescription: String? {
        switch self {
        case .unexpectedError:
            return "Something unexpected happened"
        case .unableToPublishChanges:
            return "We were unable to publish your changes to the network."
        }
    }
}
