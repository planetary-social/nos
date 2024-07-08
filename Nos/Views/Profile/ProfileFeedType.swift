import CoreData

/// An enumeration of the different feed algorithms the user can choose to view on the Profile screen.
enum ProfileFeedType {
    case activity
    case notes
    
    func databaseFilter(author: Author) -> NSFetchRequest<Event> {
        author.allPostsRequest(onlyRootPosts: self == .notes)
    }
    
    func relayFilter(author: Author) -> Filter {
        var kinds: [EventKind]
        switch self {
        case .activity:
            kinds = [.text, .delete, .repost, .longFormContent] 
        case .notes:
            kinds = [.text, .delete]
        }
        
        return Filter(
            authorKeys: [author.hexadecimalPublicKey ?? "error"],
            kinds: kinds,
            shouldKeepSubscriptionOpen: true
        )
    }
}
