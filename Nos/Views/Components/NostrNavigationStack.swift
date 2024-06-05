import SwiftUI

/// A NavigationStack that knows how to present views to display Nostr entities like `Events` and `Authors`.
/// Take care not to nest these.
struct NostrNavigationStack<Content: View>: View {
    
    @Binding var path: NavigationPath
    
    var content: () -> Content
    
    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: Event.self) { note in
                    RepliesView(note: note)
                }
                .navigationDestination(for: URL.self) { url in 
                    URLView(url: url) 
                }
                .navigationDestination(for: ReplyToNavigationDestination.self) { destination in 
                    RepliesView(note: destination.note, showKeyboard: true)
                }
                .navigationDestination(for: Author.self) { author in
                    ProfileView(author: author)
                }
        }            
    }
}

#Preview {
    @State var path = NavigationPath()
    
    return NostrNavigationStack(path: $path) {
        Text("hello world")
    }
}
