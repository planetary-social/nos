import SwiftUI

/// An enumeration of the views that can be pushed onto a `NosNavigationStack`.
enum NosNavigationDestination: Hashable {
    case note(RawEventID?)
    case author(RawAuthorID?)
    case url(URL)
    case replyTo(RawEventID?)
}

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
                    case .note(let eventID):
                        EventObservationView(eventID: eventID) { event in
                            RepliesView(note: event)
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
