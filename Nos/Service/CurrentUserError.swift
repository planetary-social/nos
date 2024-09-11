enum CurrentUserError: Error {
    /// Author associated to the logged in user wasn't found.
    /// It might indicate the user is not yet logged in.
    case authorNotFound

    /// KeyPair of the logged in user wasn't found.
    /// It might indicate the user is not yet logged in.
    case keyPairNotFound

    /// Error while publishing to relays.
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
