import Foundation

/// The types of objects that can be reported.
enum ReportTarget {
    
    case note(Event)
    case author(Author)
    
    /// The author who owns the content being reported.
    var author: Author? {
        switch self {
        case .note(let note):
            return note.author
        case .author(let author):
            return author
        }
    }
    
    var displayString: String {
        switch self {
        case .note:
            return String(localized: .localizable.note)
        case .author:
            return String(localized: .localizable.profile)
        }
    }
    
    /// Creates a tag referencing this target that can be attached to a report event.
    var tag: [String] {
        switch self {
        case .author(let author):
            if let pubKey = author.hexadecimalPublicKey {
                return ["p", pubKey]
            }
        case .note(let note):
            if let eventID = note.identifier {
                return ["e", eventID]
            }
        }
        
        return []
    }
}
