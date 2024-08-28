enum CurrentUserError: Error {
    case authorNotFound
    case keyPairNotFound
    case errorWhilePublishingToRelays

    var description: String? {
        switch self {
        case .authorNotFound:
            return "Current user's author not found"
        case .keyPairNotFound:
            return "Current user's key pair not found"
        case .errorWhilePublishingToRelays:
            return "An encoding error happened while publishing to relays"
        }
    }
}
