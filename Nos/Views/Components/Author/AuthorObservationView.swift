import SwiftUI

/// A view that observes changes to an `Author` with the given `RawAuthorID` and continually passes the newest version 
/// to a child view. Useful for hosting views that just take an `Author` but want to observe changes to the author.
struct AuthorObservationView<Content: View>: View {
    
    /// A view building function that will be given the latest version of the `Author`.
    let contentBuilder: (Author) -> Content
    
    /// A fetch request that will trigger a view update when the `Author` changes.
    @FetchRequest private var authors: FetchedResults<Author>
    
    init(authorID: RawAuthorID?, contentBuilder: @escaping (Author) -> Content) {
        if let authorID {
            _authors = FetchRequest(fetchRequest: Author.request(by: authorID))
        } else {
            _authors = FetchRequest(fetchRequest: Author.emptyRequest())
        }
        self.contentBuilder = contentBuilder
    }
    
    var body: some View {
        if let author = authors.first {
            contentBuilder(author)
        } else {
            Text("error")
        }
    }
}
