enum CurrentUserError: Error {
    case authorNotFound
    case encodingError
    case errorWhilePublishingToRelays

    var description: String? {
        switch self {
        case .authorNotFound:
            return "Current user's author not found"
        case .encodingError:
            return "An encoding error happened while saving the user data"
        case .errorWhilePublishingToRelays:
            return "An encoding error happened while publishing to relays"
        }
    }
}
