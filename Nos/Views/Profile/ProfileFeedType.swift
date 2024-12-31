import CoreData
import SwiftUI

/// An enumeration of the different feed algorithms the user can choose to view on the Profile screen.
enum ProfileFeedType {
    case activity
    case notes
    
    func databaseFilter(author: Author, before date: Date) -> NSFetchRequest<Event> {
        author.allPostsRequest(before: date, onlyRootPosts: self == .notes)
    }
    
    func relayFilter(author: Author) -> Filter {
        var kinds: [EventKind]
        switch self {
        case .activity:
            kinds = [.text, .delete, .repost, .longFormContent] 
        case .notes:
            kinds = [.text, .delete]
        }
        
        return Filter(authorKeys: [author.hexadecimalPublicKey ?? "error"], kinds: kinds)
    }
}

extension ProfileFeedType: NosSegmentedPickerItem {
    var id: String {
        switch self {
        case .activity:
            "activity"
        case .notes:
            "notes"
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .activity:
            "activity"
        case .notes:
            "notes"
        }
    }
    
    var image: Image {
        switch self {
        case .activity:
            Image.profileFeed
        case .notes:
            Image.profilePosts
        }
    }
}
