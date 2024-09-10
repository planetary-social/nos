import Foundation

/// Errors for an ``Event``.
enum EventError: LocalizedError {
    case utf8Encoding
    case unrecognizedKind
    case missingAuthor
    case invalidETag([String])
    case invalidSignature(Event)
    case expiredEvent

    var errorDescription: String? {
        switch self {
        case .unrecognizedKind:
            return "Unrecognized event kind"
        case .missingAuthor:
            return "Could not parse author on event"
        case .invalidETag(let strings):
            return "Invalid e tag \(strings.joined(separator: ","))"
        case .invalidSignature(let event):
            return "Invalid signature on event: \(String(describing: event.identifier))"
        case .expiredEvent:
            return "This event has expired"
        default:
            return "An unkown error occurred."
        }
    }
}
