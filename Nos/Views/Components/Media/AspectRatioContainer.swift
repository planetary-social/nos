import SwiftUI

/// A container that holds a view and crops it to fit the aspect ratio of determined by the ``orientation``.
/// When the ``orientation`` is `.portrait`, the aspect ratio of the container will be 3:4. Otherwise, it'll be 4:3.
struct AspectRatioContainer<Content: View>: View {
    /// The orientation, which determines the aspect ratio of this container.
    let orientation: MediaOrientation

    /// The content to be displayed in the container.
    let content: () -> Content

    var body: some View {
        Color.clear
            .aspectRatio(orientation.aspectRatio, contentMode: .fit)
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

    /// The aspect ratio to use for the view that displays this media.
    /// For `landscape`, the aspect ratio will be 4:3. For `portrait`, the aspect ratio will be 3:4.
    var aspectRatio: CGFloat {
        switch self {
        case .landscape:
            4 / 3
        case .portrait:
            3 / 4
        }
    }
}
