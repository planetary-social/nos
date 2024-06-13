import SwiftUI
import CoreData

extension View {
    /// Forwards any URLs the user taps in this view to `Router.open(url:with:)`.
    func handleURLsInRouter() -> some View {
        self.modifier(HandleURLsInRouter())
    }
}

struct HandleURLsInRouter: ViewModifier {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    
    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                router.open(url: url, with: viewContext)
                return .handled
            })
    }
}
