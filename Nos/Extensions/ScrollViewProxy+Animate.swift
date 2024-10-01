import SwiftUI

extension ScrollViewProxy {
    /// Animates and scrolls to the bottom of the specified view using the provided namespace ID.
    ///
    /// This function triggers two animations:
    /// 1. A binding value (`isAnimating`) is set to `true` with an animation.
    /// 2. The scroll view is then animated to scroll to the bottom of the view identified by the specified `id`.
    ///
    /// - Parameters:
    ///   - viewID: The namespace ID of the view to scroll to.
    ///   - isAnimating: Controls when to animate.
    func animateAndScrollTo(
        _ viewID: Namespace.ID,
        animating isAnimating: Binding<Bool>
    ) {
        withAnimation(.easeInOut(duration: 0.5)) {
            isAnimating.wrappedValue = true
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            scrollTo(viewID, anchor: .bottom)
        }
    }
}
