#if DEBUG
    import SwiftUI

    /// Only used for debugging. Settings > All published events.
    struct PublishedEventsView: View {

        var author: Author

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
                        Text("id: \(event.identifier ?? String(localized: .localizable.error))")
                        Text("kind: \(event.kind)")
                        Text("content: \(event.content ?? String(localized: .localizable.error))")
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
            .nosNavigationBar(title: .localizable.allPublishedEvents)
        }
    }

    struct PublishedEventsView_Previews: PreviewProvider {
        static var previewData = PreviewData()
        static var previews: some View {
            PublishedEventsView(author: previewData.previewAuthor)
        }
    }
#endif
