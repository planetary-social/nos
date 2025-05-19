import SwiftUI

/// A `NavigationStack` that knows how to present views common to all the tabs like `Events` and `Authors`.
/// Take care not to nest these.
struct NosNavigationStack<Content: View>: View {
    
    @Binding var path: NavigationPath
    
    let content: () -> Content
    
    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: NosNavigationDestination.self, destination: { destination in
                    switch destination {
                    case .note(let noteIdentifiable):
                        if case let .identifier(eventID) = noteIdentifiable {
                            EventObservationView(eventID: eventID) { event in
                                NoteView(note: event)
                            }
                        } else if case let .replaceableIdentifier(replaceableEventID, author, kind) = noteIdentifiable {
                            EventObservationView(
                                replaceableEventID: replaceableEventID,
                                author: author,
                                kind: kind
                            ) { event in
                                NoteView(note: event)
                            }
                        }
                    case .author(let authorID):
                        AuthorObservationView(authorID: authorID) { author in
                            ProfileView(author: author)
                        }
                    case .list(let list):
                        AuthorListDetailView(list: list)
                    case .url(let url):
                        URLView(url: url)
                    case .replyTo(let eventID):
                        EventObservationView(eventID: eventID) { event in
                            NoteView(note: event, showKeyboard: true)
                        }
                    case .wallet:
                        // Present wallet via sheet since it uses a navigation stack internally
                        Text("Wallet")
                            .onAppear {
                                // Use a sheet presentation from the parent view instead
                                DispatchQueue.main.async {
                                    path.removeLast() // Remove wallet from navigation path
                                }
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
