import SwiftUI

/// A container that holds a view and crops it to fit the aspect ratio of determined by the ``orientation``.
/// When the ``orientation`` is `.portrait`, the aspect ratio of the container will be 3:4. Otherwise, it'll be 4:3.
struct AspectRatioContainer<Content: View>: View {
    /// The orientation of this container. If `.portrait`, the aspect ratio of this container will be 3:4.
    /// Otherwise, the aspect ratio will be 4:3.
    let orientation: MediaOrientation
    
    /// The content to be displayed in the container.
    let content: () -> Content

    var body: some View {
        Color.clear
            .aspectRatio(
                orientation == .portrait ?
                    CGSize(width: 3, height: 4) :
                    CGSize(width: 4, height: 3),
                contentMode: .fit
            )
            .overlay {
                content()
            }
            .clipShape(.rect)
            .contentShape(.rect)
    }
}

/// The orientation of the media: either landscape or portrait.
enum MediaOrientation {
    /// The media is wider than it is tall.
    case landscape
    /// The media is taller than it is wide.
    case portrait
}
