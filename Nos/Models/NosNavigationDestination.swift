import Foundation

/// An enumeration of the views that can be pushed onto a `NosNavigationStack`.
enum NosNavigationDestination: Hashable {
    case note(RawEventID?)
    case author(RawAuthorID?)
    case url(URL)
    case replyTo(RawEventID?)
}
