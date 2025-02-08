import SwiftUI
import CoreData

extension View {
    /// Forwards any URLs the user taps in this view to `Router.open(url:with:)`.
    func handleURLsInRouter() -> some View {
        modifier(HandleURLsInRouter())
    }
}

fileprivate struct HandleURLsInRouter: ViewModifier {
    
    @EnvironmentObject private var router: Router
    
    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                router.open(url: url)
                return .handled
            })
    }
}
