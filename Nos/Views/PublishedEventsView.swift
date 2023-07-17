//
//  PublishedEventsView.swift
//  Nos
//
//  Created by Martin Dutra on 7/7/23.
//

import SwiftUI

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
                    Text("id: \(event.identifier ?? Localized.error.string)")
                    Text("kind: \(event.kind)")
                    Text("content: \(event.content ?? Localized.error.string)")
                    if let tags = event.allTags as? [[String]] {
                        ForEach(tags, id: \.self) { tag in
                            Text("tag: \(tag.joined(separator: ", "))")
                        }
                    }
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .allPublishedEvents)
    }
}

struct PublishedEventsView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        PublishedEventsView(author: previewData.previewAuthor)
    }
}
