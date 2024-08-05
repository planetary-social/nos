import CoreData

/// An enumeration of the different feed algorithms the user can choose to view on the Profile screen.
enum ProfileFeedType {
    case activity
    case notes
    
    /// A filter for the database. Also known as a fetch request.
    /// - Parameters:
    ///   - author: Only fetch events created by this author.
    ///   - before: Only fetch events that were created before this date.
    ///   - after: Only fetch events that were created after this date.
    /// - Returns: A fetch request that will return events matching the given parameters.
    func databaseFilter(author: Author, before: Date? = nil, after: Date? = nil) -> NSFetchRequest<Event> {
        author.allPostsRequest(before: before, after: after, onlyRootPosts: self == .notes)
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
