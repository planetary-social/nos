import SwiftUI

/// A view that observes changes to an `Event` with the given `RawEventID` and continually passes the newest version to
/// a child view. Useful for hosting views that just take an `Event` but want to observe changes to the event.
struct EventObservationView<Content: View>: View {
    
    /// A view building function that will be given the latest version of the `Event`.
    let contentBuilder: (Event) -> Content
    
    /// A fetch request that will trigger a view update when the `Event` changes.
    @FetchRequest private var events: FetchedResults<Event>
    
    init(eventID: RawEventID?, contentBuilder: @escaping (Event) -> Content) {
        if let eventID {
            _events = FetchRequest(fetchRequest: Event.event(by: eventID))
        } else {
            _events = FetchRequest(fetchRequest: Event.emptyRequest())
        }
        self.contentBuilder = contentBuilder
    }

    init(
        replaceableEventID: RawReplaceableID,
        author: Author,
        kind: Int64,
        contentBuilder: @escaping (Event) -> Content
    ) {
        _events = FetchRequest(fetchRequest: Event.event(by: replaceableEventID, author: author, kind: kind))
        self.contentBuilder = contentBuilder
    }

    var body: some View {
        if let event = events.first {
            contentBuilder(event)
        } else {
            Text("error")
        }
    }
}
