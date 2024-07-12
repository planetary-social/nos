import SwiftUI

/// A `NavigationStack` that knows how to present views common to all the tabs like `Events` and `Authors`.
/// Take care not to nest these.
struct NosNavigationStack<Content: View>: View {
    
    @Binding var path: NavigationPath
    
    var content: () -> Content
    
    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: NosNavigationDestination.self, destination: { destination in
                    switch destination {
                    case .note(let noteIdentifiable):
                        if case let .identifier(eventID) = noteIdentifiable {
                            EventObservationView(eventID: eventID) { event in
                                RepliesView(note: event)
                            }
                        } else if case let .replaceableIdentifier(replaceableEventID, author) = noteIdentifiable {
                            EventObservationView(replaceableEventID: replaceableEventID, author: author) { event in
                                RepliesView(note: event)
                            }
                        }
                    case .author(let authorID):
                        AuthorObservationView(authorID: authorID) { author in
                            ProfileView(author: author)
                        }
                    case .url(let url):
                        URLView(url: url) 
                    case .replyTo(let eventID):
                        EventObservationView(eventID: eventID) { event in
                            RepliesView(note: event, showKeyboard: true)
                        }
                    }
                })
        }            
    }
}

#Preview {
    @State var path = NavigationPath()
    
    return NosNavigationStack(path: $path) {
        Text("hello world")
    }
}
