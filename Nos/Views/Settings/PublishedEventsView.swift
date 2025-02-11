#if DEBUG
import SwiftUI

/// Only used for debugging. Settings > All published events.
struct PublishedEventsView: View {

    let author: Author

    @FetchRequest
    private var events: FetchedResults<Event>

    init(author: Author) {
        self.author = author
        _events = FetchRequest(fetchRequest: author.allEventsRequest())
    }
    
    var body: some View {
        List {
            ForEach(events) { event in
                Section {
                    Text("id: \(event.identifier ?? String(localized: "error"))")
                    Text("kind: \(event.kind)")
                    Text("content: \(event.content ?? String(localized: "error"))")
                    if let tags = event.allTags as? [[String]] {
                        ForEach(tags, id: \.self) { tag in
                            Text("tag: \(tag.joined(separator: ", "))")
                        }
                    }
                }
                .listRowGradientBackground()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("allPublishedEvents")
    }
}

struct PublishedEventsView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        PublishedEventsView(author: previewData.previewAuthor)
    }
}
#endif
