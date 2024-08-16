enum CurrentUserError: Error {
    case authorNotFound
    case errorWhilePublishingToRelays

    var description: String? {
        switch self {
        case .authorNotFound:
            return "Current user's author not found"
        case .errorWhilePublishingToRelays:
            return "An encoding error happened while publishing to relays"
        }
    }
}
